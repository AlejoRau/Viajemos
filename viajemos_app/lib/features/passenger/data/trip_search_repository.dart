import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/trip_search_result.dart';

class TripSearchRepository {
  final _client = Supabase.instance.client;

  Future<List<TripSearchResult>> searchTrips({
    required String origin,
    String? destination,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? maxPrice,
  }) async {
    var query = _client.from('trips').select('''
      id,
      owner_id,
      origin_address,
      destination_address,
      departure_date,
      departure_time,
      available_seats,
      seats_taken,
      price_per_seat,
      allows_pets,
      picks_up_at_door,
      drops_off_at_door,
      via,
      stops,
      description,
      profiles!owner_id(full_name, avg_rating),
      vehicles!vehicle_id(brand, model, color)
    ''').eq('status', 'open');

    if (origin.isNotEmpty) {
      query = query.ilike('origin_address', '%$origin%');
    }
    if (destination != null && destination.isNotEmpty) {
      query = query.ilike('destination_address', '%$destination%');
    }
    if (dateFrom != null) {
      query = query.gte(
          'departure_date', dateFrom.toIso8601String().substring(0, 10));
    }
    if (dateTo != null) {
      query = query.lte(
          'departure_date', dateTo.toIso8601String().substring(0, 10));
    }
    if (maxPrice != null && maxPrice > 0) {
      query = query.lte('price_per_seat', maxPrice);
    }

    final data = await query
        .order('departure_date', ascending: true)
        .order('departure_time', ascending: true, nullsFirst: false);

    return (data as List)
        // Client-side filter: only show trips with free seats
        .where((row) =>
            (row['seats_taken'] as int) < (row['available_seats'] as int))
        .map((row) =>
            TripSearchResult.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTripRequest({
    required String tripId,
    required int seatsRequested,
    String? message,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    await _client.from('trip_requests').insert({
      'trip_id': tripId,
      'passenger_id': user.id,
      'seats_requested': seatsRequested,
      'status': 'pending',
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }
}
