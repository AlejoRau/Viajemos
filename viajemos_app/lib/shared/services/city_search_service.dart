import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CitySuggestion {
  const CitySuggestion({
    required this.name,
    required this.displayName,
  });

  /// Short name used as the value stored (e.g. "Tandil").
  final String name;

  /// Full label shown in the list (e.g. "Tandil, Buenos Aires, Argentina").
  final String displayName;
}

class CitySearchService {
  CitySearchService._();
  static final CitySearchService instance = CitySearchService._();

  // Bounding box for Argentina + surrounding LATAM region.
  // Photon returns results within this box first, then falls back globally.
  static const _bbox = '-73,-55,-53,-22';
  static const _lat = -34.0;
  static const _lon = -64.0;

  // Place types to keep — everything else (streets, shops, POIs) is discarded.
  static const _placeTypes = {
    'city', 'town', 'village', 'hamlet', 'municipality', 'administrative',
    'suburb', 'quarter', 'neighbourhood', 'locality', 'district',
  };

  Timer? _debounce;

  void debounce(Duration delay, void Function() fn) {
    _debounce?.cancel();
    _debounce = Timer(delay, fn);
  }

  void cancel() => _debounce?.cancel();

  Future<List<CitySuggestion>> search(String query) async {
    if (query.trim().isEmpty) return [];

    // Note: Photon only supports lang=de/en/fr/default — do NOT pass lang=es.
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query.trim(),
      'limit': '8',
      'lat': '$_lat',
      'lon': '$_lon',
      'bbox': _bbox,
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

        // Skip streets, houses, POIs — keep only settlements
        final osmValue = (props['osm_value'] as String?) ?? '';
        final type = (props['type'] as String?) ?? '';
        if (type == 'street' || type == 'house') continue;
        if (osmValue.isNotEmpty && !_placeTypes.contains(osmValue)) continue;

        // Build readable label: "Tandil, Buenos Aires, Argentina"
        final state = (props['state'] as String?) ?? '';
        final country = (props['country'] as String?) ?? '';
        final parts = [name, if (state.isNotEmpty) state, if (country.isNotEmpty) country];
        final display = parts.join(', ');

        // Deduplicate by lowercase name
        if (seen.contains(name.toLowerCase())) continue;
        seen.add(name.toLowerCase());

        results.add(CitySuggestion(name: name, displayName: display));
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}
