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
      trip_requests!trip_id(status, profiles!passenger_id(full_name, avatar_url))
    ''').inFilter('status', ['open', 'full']);

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

    // Sort: available trips first, full trips at the bottom
    final rows = (data as List).cast<Map<String, dynamic>>();
    rows.sort((a, b) {
      final aFull = (a['seats_taken'] as int) >= (a['available_seats'] as int);
      final bFull = (b['seats_taken'] as int) >= (b['available_seats'] as int);
      return (aFull ? 1 : 0).compareTo(bFull ? 1 : 0);
    });
    return rows.map((row) => TripSearchResult.fromJson(row)).toList();
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
        'name': profile['full_name'] as String? ?? 'Pasajero',
        'avatarUrl': profile['avatar_url'] as String?,
      };
    }).toList();
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
