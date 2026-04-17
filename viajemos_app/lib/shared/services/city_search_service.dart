import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class CitySuggestion {
  const CitySuggestion({
    required this.name,
    required this.displayName,
  });

  /// Short name used as the stored value (e.g. "Tandil").
  final String name;

  /// Full label shown in the list (e.g. "Tandil, Buenos Aires, Argentina").
  final String displayName;
}

/// Popular Argentine cities shown when a city field is focused and empty.
const popularArgentineCities = [
  CitySuggestion(name: 'Buenos Aires',  displayName: 'Buenos Aires, Argentina'),
  CitySuggestion(name: 'Córdoba',       displayName: 'Córdoba, Córdoba'),
  CitySuggestion(name: 'Rosario',       displayName: 'Rosario, Santa Fe'),
  CitySuggestion(name: 'Mendoza',       displayName: 'Mendoza, Mendoza'),
  CitySuggestion(name: 'La Plata',      displayName: 'La Plata, Buenos Aires'),
  CitySuggestion(name: 'Mar del Plata', displayName: 'Mar del Plata, Buenos Aires'),
  CitySuggestion(name: 'Tucumán',       displayName: 'San Miguel de Tucumán, Tucumán'),
  CitySuggestion(name: 'Salta',         displayName: 'Salta, Salta'),
  CitySuggestion(name: 'Santa Fe',      displayName: 'Santa Fe, Santa Fe'),
  CitySuggestion(name: 'Bahía Blanca',  displayName: 'Bahía Blanca, Buenos Aires'),
];

/// Which backend to use for city lookups.
/// Switch to [CitySearchSource.georef] when the official Argentine government
/// API is ready to replace Photon.
enum CitySearchSource { photon, georef }

class CitySearchService {
  CitySearchService._();
  static final CitySearchService instance = CitySearchService._();

  // ── Source toggle ─────────────────────────────────────────────────────────
  /// Change this to [CitySearchSource.georef] to use the official Argentine
  /// Georef API (apis.datos.gob.ar/georef/api/).
  static CitySearchSource source = CitySearchSource.photon;

  // ── Photon config ─────────────────────────────────────────────────────────
  // Bounding box targeting Argentina + surrounding LATAM region.
  static const _photonBbox = '-73,-55,-53,-22';
  static const _photonLat = -34.0;
  static const _photonLon = -64.0;

  // Place types to keep — everything else (streets, shops, POIs) is discarded.
  static const _placeTypes = {
    'city', 'town', 'village', 'hamlet', 'municipality', 'administrative',
    'suburb', 'quarter', 'neighbourhood', 'locality', 'district',
  };

  // ── Debounce ──────────────────────────────────────────────────────────────
  Timer? _debounce;

  void debounce(Duration delay, void Function() fn) {
    _debounce?.cancel();
    _debounce = Timer(delay, fn);
  }

  void cancel() => _debounce?.cancel();

  // ── Cache ─────────────────────────────────────────────────────────────────
  // Stores the last 20 unique queries so repeated or re-typed searches never
  // hit the network again.
  static const _cacheMaxSize = 20;
  final _cache = <String, List<CitySuggestion>>{};

  String _cacheKey(String query, CitySearchSource src) =>
      '${src.name}:${query.trim().toLowerCase()}';

  // ── Public search ─────────────────────────────────────────────────────────
  /// [overrideSource] lets a single call use a different source than the global default.
  Future<List<CitySuggestion>> search(String query,
      {CitySearchSource? overrideSource}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    // Minimum 3 characters — avoids burning requests on single letters.
    if (q.length < 3) return [];

    final src = overrideSource ?? source;
    final key = _cacheKey(q, src);

    if (_cache.containsKey(key)) return _cache[key]!;

    final results = await switch (src) {
      CitySearchSource.photon => _searchPhoton(q),
      CitySearchSource.georef => _searchGeoref(q),
    };

    // Evict oldest entry when cache is full.
    if (_cache.length >= _cacheMaxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = results;
    return results;
  }

  // ── Photon (komoot) ───────────────────────────────────────────────────────
  Future<List<CitySuggestion>> _searchPhoton(String query) async {
    // Note: Photon only supports lang=de/en/fr/default — do NOT pass lang=es.
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query.trim(),
      'limit': '8',
      'lat': '$_photonLat',
      'lon': '$_photonLon',
      'bbox': _photonBbox,
    });

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final features = (json['features'] as List?) ?? [];

      final seen = <String>{};
      final results = <CitySuggestion>[];

      for (final f in features) {
        final props = f['properties'] as Map<String, dynamic>? ?? {};
        final name = (props['name'] as String?) ?? '';
        if (name.isEmpty) continue;

        // Skip streets, houses, POIs — keep only settlements.
        final osmValue = (props['osm_value'] as String?) ?? '';
        final type = (props['type'] as String?) ?? '';
        if (type == 'street' || type == 'house') continue;
        if (osmValue.isNotEmpty && !_placeTypes.contains(osmValue)) continue;

        // Build readable label: "Tandil, Buenos Aires, Argentina"
        final state = (props['state'] as String?) ?? '';
        final country = (props['country'] as String?) ?? '';
        final parts = [name, if (state.isNotEmpty) state, if (country.isNotEmpty) country];
        final display = parts.join(', ');

        // Deduplicate by lowercase name.
        if (seen.contains(name.toLowerCase())) continue;
        seen.add(name.toLowerCase());

        results.add(CitySuggestion(name: name, displayName: display));
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  // ── Georef — API del Servicio de Normalización de Datos Geográficos ───────
  // Official Argentine government API: https://apis.datos.gob.ar/georef/api/
  // Searches both municipios and localidades and merges results.
  Future<List<CitySuggestion>> _searchGeoref(String query) async {
    try {
      final results = await Future.wait([
        _georefEndpoint('municipios', query),
        _georefEndpoint('localidades', query),
      ]);

      final seen = <String>{};
      final merged = <CitySuggestion>[];

      for (final list in results) {
        for (final s in list) {
          if (seen.contains(s.name.toLowerCase())) continue;
          seen.add(s.name.toLowerCase());
          merged.add(s);
          if (merged.length >= 8) break;
        }
        if (merged.length >= 8) break;
      }

      return merged;
    } catch (_) {
      return [];
    }
  }

  Future<List<CitySuggestion>> _georefEndpoint(
      String endpoint, String query) async {
    final uri = Uri.https('apis.datos.gob.ar', '/georef/api/$endpoint', {
      'nombre': query.trim(),
      'campos': 'nombre,provincia.nombre',
      'max': '6',
    });

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 6));

    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (json[endpoint] as List?) ?? [];

    return items.map((item) {
      final nombre = (item['nombre'] as String?) ?? '';
      final provincia = (item['provincia']?['nombre'] as String?) ?? '';
      final display = provincia.isNotEmpty ? '$nombre, $provincia' : nombre;
      return CitySuggestion(name: nombre, displayName: display);
    }).where((s) => s.name.isNotEmpty).toList();
  }

  // ── Geocoding ─────────────────────────────────────────────────────────────
  /// Returns the (lat, lon) centroid of a city name using Georef.
  /// Returns null if not found or on error.
  Future<(double lat, double lon)?> geocodeCity(String cityName) async {
    final q = cityName.trim();
    if (q.isEmpty) return null;
    for (final endpoint in ['municipios', 'localidades']) {
      try {
        final uri = Uri.https('apis.datos.gob.ar', '/georef/api/$endpoint', {
          'nombre': q,
          'campos': 'nombre,centroide.lat,centroide.lon',
          'max': '1',
        });
        final response = await http
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 6));
        if (response.statusCode != 200) continue;
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final items = (json[endpoint] as List?) ?? [];
        if (items.isEmpty) continue;
        final centroide = items.first['centroide'] as Map<String, dynamic>?;
        if (centroide == null) continue;
        final lat = (centroide['lat'] as num?)?.toDouble();
        final lon = (centroide['lon'] as num?)?.toDouble();
        if (lat != null && lon != null) return (lat, lon);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  // ── Distance helpers ──────────────────────────────────────────────────────
  /// Haversine distance in km between two lat/lon points.
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;

  /// Detour ratio: (origin→stop + stop→dest) / (origin→dest).
  /// Values >> 1.0 mean the stop is far off route.
  static double detourRatio(
    double oLat, double oLon,
    double sLat, double sLon,
    double dLat, double dLon,
  ) {
    final direct = distanceKm(oLat, oLon, dLat, dLon);
    if (direct < 1) return 1.0; // origin ≈ destination, skip check
    final withStop =
        distanceKm(oLat, oLon, sLat, sLon) + distanceKm(sLat, sLon, dLat, dLon);
    return withStop / direct;
  }
}
