import 'package:supabase_flutter/supabase_flutter.dart';

class TripRepository {
  final _client = Supabase.instance.client;

  Future<String> createTrip({
    required String originAddress,
    required String destinationAddress,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
    required int availableSeats,
    required int pricePerSeat,
    required DateTime departureDate,
    String? departureTimeFrom,
    required bool allowsPets,
    required bool picksUpAtDoor,
    required bool dropsOffAtDoor,
    required List<String> via,
    required List<String> stops,
    required bool splitCosts,
    String? pickupAddress,
    String? dropoffAddress,
    String? description,
    String? vehicleId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final payload = <String, dynamic>{
      'owner_id': user.id,
      'origin_address': originAddress,
      'destination_address': destinationAddress,
      'available_seats': availableSeats,
      'price_per_seat': pricePerSeat,
      'departure_date': departureDate.toIso8601String().substring(0, 10),
      'allows_pets': allowsPets,
      'picks_up_at_door': picksUpAtDoor,
      'drops_off_at_door': dropsOffAtDoor,
      'via': via,
      'stops': stops,
      'split_costs': splitCosts,
      if (pickupAddress != null && pickupAddress.isNotEmpty)
        'pickup_address': pickupAddress,
      if (dropoffAddress != null && dropoffAddress.isNotEmpty)
        'dropoff_address': dropoffAddress,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (originLat != null && originLng != null)
        'origin_location': 'POINT($originLng $originLat)',
      if (destLat != null && destLng != null)
        'destination_location': 'POINT($destLng $destLat)',
      if (departureTimeFrom != null && departureTimeFrom.isNotEmpty)
        'departure_time': departureTimeFrom,
    };

    final response = await _client
        .from('trips')
        .insert(payload)
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<List<Map<String, dynamic>>> fetchDriverTripSummaries() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final data = await _client
        .from('trips')
        .select('id, origin_address, destination_address, departure_date, departure_time, via, status')
        .eq('owner_id', userId)
        .order('departure_date', ascending: false) as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> fetchTripForRepeat(String tripId) async {
    return await _client
        .from('trips')
        .select(
            'origin_address, destination_address, departure_time, allows_pets, picks_up_at_door, drops_off_at_door, via, stops, description, vehicle_id')
        .eq('id', tripId)
        .maybeSingle();
  }

  Future<int> countActiveTrips() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;
    final data = await _client
        .from('trips')
        .select('id')
        .eq('owner_id', userId)
        .inFilter('status', ['active', 'full']) as List;
    return data.length;
  }
}
