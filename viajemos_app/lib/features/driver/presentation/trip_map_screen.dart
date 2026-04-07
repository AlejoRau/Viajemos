import 'dart:async';
import 'dart:convert';
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
  /// Title shown in the AppBar, e.g. "Punto de salida" or "Punto de llegada".
  final String title;

  const TripMapScreen({super.key, required this.title});

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  final _searchController = TextEditingController();
  final _mapController = MapController();

  // Default center: Buenos Aires
  LatLng _pin = const LatLng(-34.6037, -58.3816);
  String _address = '';
  List<_Place> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;
  bool _reversing = false; // true while reverse-geocoding a tapped point

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _search(query.trim()),
    );
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5&countrycodes=ar',
      );
      final res = await http.get(uri, headers: {
        'Accept-Language': 'es',
        'User-Agent': 'Viajemos/1.0',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _suggestions = data
              .map((e) => _Place(
                    lat: double.parse(e['lat'] as String),
                    lon: double.parse(e['lon'] as String),
                    display: e['display_name'] as String,
                  ))
              .toList();
        });
      }
    } catch (_) {
      // ignore network errors
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectPlace(_Place place) {
    final point = LatLng(place.lat, place.lon);
    setState(() {
      _pin = point;
      _address = place.display;
      _suggestions = [];
      _searchController.text = _short(place.display);
    });
    _mapController.move(point, 15);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _reversing = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${point.latitude}&lon=${point.longitude}'
        '&format=json',
      );
      final res = await http.get(uri, headers: {
        'Accept-Language': 'es',
        'User-Agent': 'Viajemos/1.0',
      });
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final city = (addr['city']
                ?? addr['town']
                ?? addr['village']
                ?? addr['municipality']
                ?? addr['county']
                ?? data['display_name']) as String?;
        if (city != null && mounted) {
          setState(() => _address = city);
        }
      }
    } catch (_) {
      // On error leave _address empty so the confirm button stays disabled.
    } finally {
      if (mounted) setState(() => _reversing = false);
    }
  }

  /// Shows only the first 3 segments of the Nominatim display_name.
  String _short(String full) =>
      full.split(', ').take(3).join(', ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Stack(
        children: [
          // ── Mapa ─────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pin,
              initialZoom: 12.0,
              onTap: (_, point) {
                setState(() {
                  _pin = point;
                  _suggestions = [];
                  _searchController.clear();
                  _address = ''; // cleared until reverse geocode completes
                });
                _reverseGeocode(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.viajemos.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pin,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_pin,
                      color: AppColors.primary,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Buscador ─────────────────────────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar dirección...',
                      hintStyle:
                          const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF94A3B8)),
                      suffixIcon: _loading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _suggestions.length; i++) ...[
                          if (i > 0)
                            const Divider(
                                height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            dense: true,
                            leading: const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: AppColors.primary),
                            title: Text(
                              _short(_suggestions[i].display),
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectPlace(_suggestions[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Tip ──────────────────────────────────────────────────────
          Positioned(
            bottom: 96,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Buscá o tocá el mapa para ajustar el punto',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),

          // ── Botón confirmar ───────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: (_address.isEmpty || _reversing)
                      ? null
                      : () => Navigator.pop(
                            context,
                            MapResult(
                              lat: _pin.latitude,
                              lng: _pin.longitude,
                              address: _short(_address),
                            ),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27)),
                    elevation: 0,
                  ),
                  child: _reversing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Confirmar ubicación',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Place {
  final double lat;
  final double lon;
  final String display;
  const _Place(
      {required this.lat, required this.lon, required this.display});
}
