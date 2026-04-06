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
}
