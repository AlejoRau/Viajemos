import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';

/// Result returned when the user confirms a location on the map.
class MapResult {
  final double lat;
  final double lng;
  final String address;
  const MapResult({required this.lat, required this.lng, required this.address});
}

class TripMapScreen extends StatefulWidget {
  final String title;
  final String? initialCity;
  final MapResult? initialResult;

  const TripMapScreen({
    super.key,
    required this.title,
    this.initialCity,
    this.initialResult,
  });

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _mapController = MapController();

  LatLng _pin = const LatLng(-34.6037, -58.3816);
  String _address = '';
  String _addressSubtitle = '';
  List<_Place> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;
  bool _reversing = false;
  bool _locating = false;
  bool _showSuggestions = false;

  // Pin drop animation
  late AnimationController _pinCtrl;
  late Animation<double> _pinDrop;
  late Animation<double> _shadowScale;

  @override
  void initState() {
    super.initState();

    _pinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pinDrop = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _pinCtrl, curve: Curves.bounceOut),
    );
    _shadowScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pinCtrl, curve: Curves.easeOut),
    );
    _pinCtrl.forward();

    final ir = widget.initialResult;
    if (ir != null) {
      _pin = LatLng(ir.lat, ir.lng);
      _address = ir.address;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(_pin, 15);
      });
    } else if (widget.initialCity != null && widget.initialCity!.trim().isNotEmpty) {
      _centerOnCity(widget.initialCity!.trim());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _dropPin(LatLng point) {
    setState(() {
      _pin = point;
      _address = '';
      _addressSubtitle = '';
    });
    _pinCtrl.reset();
    _pinCtrl.forward();
    _mapController.move(point, _mapController.camera.zoom < 14 ? 15 : _mapController.camera.zoom);
    _reverseGeocode(point);
  }

  Future<void> _centerOnCity(String city) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(city)}'
        '&format=json&limit=1&countrycodes=ar',
      );
      final res = await http.get(uri, headers: {
        'Accept-Language': 'es',
        'User-Agent': 'Viajemos/1.0',
      });
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lon = double.parse(data[0]['lon'] as String);
          final point = LatLng(lat, lon);
          setState(() => _pin = point);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _mapController.move(point, 13);
          });
        }
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(query.trim()),
    );
  }

  String _buildQuery(String raw) {
    final numberFirst = RegExp(r'^(\d+)\s+(.+)$');
    final match = numberFirst.firstMatch(raw);
    final normalized =
        match != null ? '${match.group(2)} ${match.group(1)}' : raw;
    final city = widget.initialCity?.trim();
    if (city != null &&
        city.isNotEmpty &&
        !normalized.toLowerCase().contains(city.toLowerCase())) {
      return '$normalized, $city';
    }
    return normalized;
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final q = _buildQuery(query);
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(q)}'
        '&format=json&limit=6&countrycodes=ar&addressdetails=1',
      );
      final res = await http.get(uri, headers: {
        'Accept-Language': 'es',
        'User-Agent': 'Viajemos/1.0',
      });
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _suggestions = data
              .map((e) => _Place(
                    lat: double.parse(e['lat'] as String),
                    lon: double.parse(e['lon'] as String),
                    display: e['display_name'] as String,
                    type: e['type'] as String? ?? '',
                    address: (e['address'] as Map<String, dynamic>?) ?? {},
                  ))
              .toList();
          _showSuggestions = true;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectPlace(_Place place) {
    final point = LatLng(place.lat, place.lon);
    _searchController.text = _shortDisplay(place.display);
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    FocusScope.of(context).unfocus();
    _dropPin(point);
  }

  Future<LatLng?> _snapToRoad(LatLng point) async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/nearest/v1/driving/'
        '${point.longitude},${point.latitude}.json?number=1',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'Viajemos/1.0'}).timeout(
              const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final waypoints = data['waypoints'] as List?;
        if (waypoints != null && waypoints.isNotEmpty) {
          final loc = waypoints[0]['location'] as List;
          final snapped =
              LatLng((loc[1] as num).toDouble(), (loc[0] as num).toDouble());
          final dist =
              const Distance().as(LengthUnit.Meter, point, snapped);
          if (dist <= 150.0) return snapped;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _reverseGeocode(LatLng point) async {
    if (!mounted) return;
    setState(() => _reversing = true);
    try {
      final snapped = await _snapToRoad(point);
      final usePoint = snapped ?? point;
      if (snapped != null && mounted) setState(() => _pin = snapped);

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${usePoint.latitude}&lon=${usePoint.longitude}'
        '&format=json&addressdetails=1',
      );
      final res = await http.get(uri, headers: {
        'Accept-Language': 'es',
        'User-Agent': 'Viajemos/1.0',
      });
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final displayName = data['display_name'] as String? ?? '';

        final city = addr['city'] as String? ??
            addr['town'] as String? ??
            addr['village'] as String? ??
            '';
        final state = addr['state'] as String? ?? '';
        final main = _buildAddressLabel(addr, displayName);

        final subtitle = [city, state].where((s) => s.isNotEmpty).join(', ');

        if (mounted) {
          setState(() {
            _address = main;
            _addressSubtitle = subtitle;
          });
          if (main.isNotEmpty && _searchController.text.isEmpty) {
            _searchController.text = main;
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _reversing = false);
    }
  }

  /// Builds a clean human-readable street address from a Nominatim
  /// reverse-geocode response, avoiding coordinate-like or abbreviated outputs.
  String _buildAddressLabel(Map<String, dynamic> addr, String displayName) {
    final road = addr['road'] as String?;
    final houseNumber = addr['house_number'] as String?;

    if (road != null && road.length > 3 &&
        !RegExp(r'^[\dA-Z]{1,4}$').hasMatch(road.trim())) {
      return houseNumber != null ? '$road $houseNumber' : road;
    }

    final parts = <String>[];
    if (road != null && road.isNotEmpty) {
      parts.add(houseNumber != null ? '$road $houseNumber' : road);
    }
    final neighborhood = addr['suburb'] as String? ??
        addr['city_district'] as String? ??
        addr['neighbourhood'] as String?;
    if (neighborhood != null) parts.add(neighborhood);
    final city = addr['city'] as String? ??
        addr['town'] as String? ??
        addr['village'] as String? ??
        addr['municipality'] as String?;
    if (city != null) parts.add(city);
    if (parts.isNotEmpty) return parts.join(', ');

    if (displayName.isNotEmpty) {
      final filtered = displayName
          .split(', ')
          .where((s) => !RegExp(r'^-?\d+\.?\d*$').hasMatch(s.trim()))
          .take(3)
          .join(', ');
      if (filtered.isNotEmpty) return filtered;
    }
    return '';
  }

  void _getMyLocation() async {
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) _dropPin(LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener tu ubicación')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _zoomIn() =>
      _mapController.move(_pin, _mapController.camera.zoom + 1);

  void _zoomOut() =>
      _mapController.move(_pin, _mapController.camera.zoom - 1);

  String _shortDisplay(String full) => full.split(', ').take(3).join(', ');

  IconData _placeIcon(String type) {
    switch (type) {
      case 'house':
      case 'residential':
        return Icons.home_rounded;
      case 'bus_stop':
      case 'station':
        return Icons.directions_bus_rounded;
      case 'hospital':
      case 'clinic':
        return Icons.local_hospital_rounded;
      case 'school':
      case 'university':
        return Icons.school_rounded;
      case 'restaurant':
      case 'cafe':
        return Icons.restaurant_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAddress = _address.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Mapa ──────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pin,
              initialZoom: 13.0,
              minZoom: 4,
              maxZoom: 19,
              onTap: (_, point) {
                setState(() {
                  _showSuggestions = false;
                  _searchController.clear();
                });
                FocusScope.of(context).unfocus();
                _dropPin(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.viajemos.app',
                maxZoom: 19,
              ),
              // Pin animado
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pin,
                    width: 60,
                    height: 80,
                    alignment: Alignment.topCenter,
                    child: AnimatedBuilder(
                      animation: _pinCtrl,
                      builder: (_, __) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(0, -_pinDrop.value),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: _shadowScale.value,
                            child: Container(
                              width: 10,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── AppBar custom ─────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    // Botón back
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: const Color(0xFF1E293B),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Buscador
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onTap: () {
                            if (_suggestions.isNotEmpty) {
                              setState(() => _showSuggestions = true);
                            }
                          },
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            hintText: widget.title,
                            hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 14),
                            prefixIcon: _loading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary),
                                    ),
                                  )
                                : const Icon(Icons.search_rounded,
                                    color: Color(0xFF94A3B8), size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 18, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _suggestions = [];
                                        _showSuggestions = false;
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Sugerencias ───────────────────────────────────────────────
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: 80,
              left: 70,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _suggestions.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, indent: 56, endIndent: 16),
                        InkWell(
                          onTap: () => _selectPlace(_suggestions[i]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primary.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _placeIcon(_suggestions[i].type),
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _shortDisplay(_suggestions[i].display)
                                            .split(', ')
                                            .first,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _shortDisplay(_suggestions[i].display)
                                            .split(', ')
                                            .skip(1)
                                            .join(', '),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // ── Controles derecha ─────────────────────────────────────────
          Positioned(
            right: 14,
            bottom: hasAddress ? 160 : 110,
            child: Column(
              children: [
                // Mi ubicación
                _MapButton(
                  onTap: _getMyLocation,
                  child: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : const Icon(Icons.my_location_rounded,
                          color: AppColors.primary, size: 22),
                ),
                const SizedBox(height: 8),
                // Zoom +
                _MapButton(
                  onTap: _zoomIn,
                  child: const Icon(Icons.add_rounded,
                      color: Color(0xFF1E293B), size: 22),
                ),
                const SizedBox(height: 2),
                // Zoom -
                _MapButton(
                  onTap: _zoomOut,
                  child: const Icon(Icons.remove_rounded,
                      color: Color(0xFF1E293B), size: 22),
                ),
              ],
            ),
          ),

          // ── Card dirección + confirmar ─────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -4)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_reversing)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          ),
                          SizedBox(width: 10),
                          Text('Obteniendo dirección...',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF94A3B8))),
                        ],
                      )
                    else if (hasAddress) ...[
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _address,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_addressSubtitle.isNotEmpty)
                                  Text(
                                    _addressSubtitle,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      const Text(
                        'Tocá el mapa o buscá una dirección',
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Botón confirmar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (hasAddress && !_reversing)
                            ? () => Navigator.pop(
                                  context,
                                  MapResult(
                                    lat: _pin.latitude,
                                    lng: _pin.longitude,
                                    address: _address,
                                  ),
                                )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.35),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirmar ubicación',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón flotante del mapa ──────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  const _MapButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _Place {
  final double lat;
  final double lon;
  final String display;
  final String type;
  final Map<String, dynamic> address;
  const _Place({
    required this.lat,
    required this.lon,
    required this.display,
    required this.type,
    required this.address,
  });
}
