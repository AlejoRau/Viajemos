import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/trip_search_result.dart';

class TripSearchRepository {
  final _client = Supabase.instance.client;

  static const _select = '''
      id,
      owner_id,
      origin_address,
      destination_address,
      pickup_address,
      dropoff_address,
      departure_date,
      departure_time,
      available_seats,
      seats_taken,
      price_per_seat,
      split_costs,
      allows_pets,
      picks_up_at_door,
      drops_off_at_door,
      via,
      stops,
      description,
      profiles!owner_id(full_name, avg_rating, avatar_url),
      vehicles!vehicle_id(brand, model, color),
      trip_requests!trip_id(status, passenger_id, profiles!passenger_id(full_name, avatar_url))
    ''';

  /// Fetches raw trip rows applying optional server-side filters.
  Future<List<Map<String, dynamic>>> _fetchRaw({
    String? origin,
    String? destination,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? maxPrice,
  }) async {
    var query = _client.from('trips').select(_select).inFilter('status', ['open', 'full']);
    if (origin != null && origin.isNotEmpty) {
      query = query.ilike('origin_address', '%$origin%');
    }
    if (destination != null && destination.isNotEmpty) {
      query = query.ilike('destination_address', '%$destination%');
    }
    if (dateFrom != null) {
      query = query.gte('departure_date', dateFrom.toIso8601String().substring(0, 10));
    }
    if (dateTo != null) {
      query = query.lte('departure_date', dateTo.toIso8601String().substring(0, 10));
    }
    if (maxPrice != null && maxPrice > 0) {
      query = query.lte('price_per_seat', maxPrice);
    }
    final data = await query
        .order('departure_date', ascending: true)
        .order('departure_time', ascending: true, nullsFirst: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<TripSearchResult>> searchTrips({
    required String origin,
    String? destination,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? maxPrice,
  }) async {
    // Q1 — normal: origin matches origin_address AND destination matches destination_address
    final q1Rows = await _fetchRaw(
      origin: origin,
      destination: destination,
      dateFrom: dateFrom,
      dateTo: dateTo,
      maxPrice: maxPrice,
    );

    final results = <String, TripSearchResult>{};
    for (final row in q1Rows) {
      results[row['id'] as String] = TripSearchResult.fromJson(row);
    }

    if (destination != null && destination.isNotEmpty) {
      // Q2 — alighting at stop: origin matches, check stops array for destination
      final q2Rows = await _fetchRaw(
        origin: origin,
        destination: null,
        dateFrom: dateFrom,
        dateTo: dateTo,
        maxPrice: maxPrice,
      );
      for (final row in q2Rows) {
        final id = row['id'] as String;
        if (results.containsKey(id)) continue;
        final stops = (row['stops'] as List<dynamic>?)?.cast<String>() ?? [];
        final matched = _findMatchingStop(stops, destination);
        if (matched != null) {
          results[id] = TripSearchResult.fromJson(row).copyWith(alightingStop: matched);
        }
      }

      // Q3 — boarding at stop: destination matches, check stops array for origin
      final q3Rows = await _fetchRaw(
        origin: null,
        destination: destination,
        dateFrom: dateFrom,
        dateTo: dateTo,
        maxPrice: maxPrice,
      );
      for (final row in q3Rows) {
        final id = row['id'] as String;
        if (results.containsKey(id)) continue;
        final stops = (row['stops'] as List<dynamic>?)?.cast<String>() ?? [];
        final matched = _findMatchingStop(stops, origin);
        if (matched != null) {
          results[id] = TripSearchResult.fromJson(row).copyWith(boardingStop: matched);
        }
      }
    }

    final list = results.values.toList();
    // Available trips first, full trips at the bottom
    list.sort((a, b) =>
        (a.freeSeats == 0 ? 1 : 0).compareTo(b.freeSeats == 0 ? 1 : 0));
    return list;
  }

  /// Returns the first stop that case-insensitively contains [query], or null.
  String? _findMatchingStop(List<String> stops, String query) {
    final q = query.toLowerCase();
    for (final stop in stops) {
      if (stop.toLowerCase().contains(q)) return stop;
    }
    return null;
  }

  Future<TripSearchResult?> fetchTripById(String tripId) async {
    final row = await _client
        .from('trips')
        .select(_select)
        .eq('id', tripId)
        .maybeSingle();
    if (row == null) return null;
    return TripSearchResult.fromJson(row as Map<String, dynamic>);
  }

  Future<List<Map<String, String?>>> fetchTripPassengers(String tripId) async {
    final data = await _client
        .from('trip_requests')
        .select('passenger_id, profiles!passenger_id(full_name, avatar_url)')
        .eq('trip_id', tripId)
        .eq('status', 'accepted') as List;

    return data.map((row) {
      final profile = row['profiles'] as Map<String, dynamic>? ?? {};
      return {
        'userId': row['passenger_id'] as String?,
        'name': profile['full_name'] as String? ?? 'Pasajero',
        'avatarUrl': profile['avatar_url'] as String?,
      };
    }).toList();
  }

  Future<void> createTripRequest({
    required String tripId,
    required int seatsRequested,
    String? message,
    String? passengerPickupAddress,
    String? passengerDropoffAddress,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    await _client.from('trip_requests').insert({
      'trip_id': tripId,
      'passenger_id': user.id,
      'seats_requested': seatsRequested,
      'status': 'pending',
      if (message != null && message.isNotEmpty) 'message': message,
      if (passengerPickupAddress?.isNotEmpty == true)
        'passenger_pickup_address': passengerPickupAddress,
      if (passengerDropoffAddress?.isNotEmpty == true)
        'passenger_dropoff_address': passengerDropoffAddress,
    });
  }
}
