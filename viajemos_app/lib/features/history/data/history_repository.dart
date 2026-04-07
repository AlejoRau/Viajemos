import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Models ─────────────────────────────────────────────────────────────────

class PassengerInTrip {
  const PassengerInTrip({required this.name, required this.rating});
  final String name;
  final double rating;
}

class DriverTripHistory {
  const DriverTripHistory({
    required this.id,
    required this.departureDate,
    required this.originAddress,
    required this.destinationAddress,
    required this.pricePerSeat,
    required this.seatsTaken,
    required this.via,
    required this.passengers,
    this.departureTime,
    this.avgTripRating,
  });

  final String id;
  final DateTime departureDate;
  final String originAddress;
  final String destinationAddress;
  final int pricePerSeat;
  final int seatsTaken;
  final List<String> via;
  final List<PassengerInTrip> passengers;
  final String? departureTime;
  final double? avgTripRating;

  int get earnings => pricePerSeat * seatsTaken;
}

class PassengerTripHistory {
  const PassengerTripHistory({
    required this.id,
    required this.departureDate,
    required this.originAddress,
    required this.destinationAddress,
    required this.pricePerSeat,
    required this.driverName,
    required this.driverRating,
    this.departureTime,
  });

  final String id;
  final DateTime departureDate;
  final String originAddress;
  final String destinationAddress;
  final int pricePerSeat;
  final String driverName;
  final double driverRating;
  final String? departureTime;
}

class ActiveDriverTrip {
  const ActiveDriverTrip({
    required this.id,
    required this.departureDate,
    required this.originAddress,
    required this.destinationAddress,
    required this.availableSeats,
    required this.seatsTaken,
    required this.pricePerSeat,
    required this.status,
    required this.pendingRequestsCount,
    required this.acceptedPassengerNames,
    this.departureTime,
  });

  final String id;
  final DateTime departureDate;
  final String originAddress;
  final String destinationAddress;
  final int availableSeats;
  final int seatsTaken;
  final int pricePerSeat;
  final String status;
  final int pendingRequestsCount;
  final List<String> acceptedPassengerNames;
  final String? departureTime;

  int get freeSeats => availableSeats - seatsTaken;
  bool get isFull => status == 'full';
}

class TripRequestEntry {
  const TripRequestEntry({
    required this.requestId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerRating,
    required this.passengerTrips,
    required this.seatsRequested,
    required this.createdAt,
    this.message,
  });

  final String requestId;
  final String passengerId;
  final String passengerName;
  final double passengerRating;
  final int passengerTrips;
  final int seatsRequested;
  final String? message;
  final DateTime createdAt;
}

// ── Repository ─────────────────────────────────────────────────────────────

class HistoryRepository {
  final _client = Supabase.instance.client;

  Future<void> updatePastTripStatuses() async {
    await _client.rpc('update_own_past_trip_statuses');
  }

  Future<List<ActiveDriverTrip>> fetchActiveDriverTrips() async {
    final data = await _client.rpc('get_driver_active_trips') as List;
    return data.map((row) {
      final timeRaw = row['departure_time'] as String?;
      return ActiveDriverTrip(
        id: row['id'] as String,
        departureDate: DateTime.parse(row['departure_date'] as String),
        originAddress: row['origin_address'] as String,
        destinationAddress: row['destination_address'] as String,
        availableSeats: (row['available_seats'] as int?) ?? 0,
        seatsTaken: (row['seats_taken'] as int?) ?? 0,
        pricePerSeat: (row['price_per_seat'] as num).toInt(),
        status: row['status'] as String,
        pendingRequestsCount: (row['pending_requests_count'] as num?)?.toInt() ?? 0,
        acceptedPassengerNames:
            (row['accepted_passenger_names'] as List?)?.cast<String>() ?? [],
        departureTime: timeRaw != null && timeRaw.length >= 5
            ? timeRaw.substring(0, 5)
            : null,
      );
    }).toList();
  }

  Future<List<TripRequestEntry>> fetchPendingRequests(String tripId) async {
    final data = await _client.rpc(
      'get_trip_pending_requests',
      params: {'p_trip_id': tripId},
    ) as List;
    return data.map((row) {
      return TripRequestEntry(
        requestId: row['request_id'] as String,
        passengerId: row['passenger_id'] as String,
        passengerName: row['passenger_name'] as String? ?? 'Pasajero',
        passengerRating: (row['passenger_rating'] as num?)?.toDouble() ?? 0.0,
        passengerTrips: (row['passenger_trips'] as int?) ?? 0,
        seatsRequested: (row['seats_requested'] as int?) ?? 1,
        message: row['message'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<void> acceptRequest(String requestId) async {
    await _client
        .from('trip_requests')
        .update({'status': 'accepted'})
        .eq('id', requestId);
  }

  Future<void> declineRequest(String requestId) async {
    await _client
        .from('trip_requests')
        .update({'status': 'declined'})
        .eq('id', requestId);
  }

  Future<List<DriverTripHistory>> fetchDriverHistory() async {
    final data = await _client.rpc('get_driver_history') as List;
    return data.map((row) {
      final passengers = (row['passengers'] as List? ?? [])
          .map((p) => PassengerInTrip(
                name: p['name'] as String? ?? 'Pasajero',
                rating: (p['rating'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
      final timeRaw = row['departure_time'] as String?;
      return DriverTripHistory(
        id: row['id'] as String,
        departureDate: DateTime.parse(row['departure_date'] as String),
        originAddress: row['origin_address'] as String,
        destinationAddress: row['destination_address'] as String,
        pricePerSeat: (row['price_per_seat'] as num).toInt(),
        seatsTaken: (row['seats_taken'] as int?) ?? 0,
        via: (row['via'] as List?)?.cast<String>() ?? [],
        departureTime: timeRaw != null && timeRaw.length >= 5
            ? timeRaw.substring(0, 5)
            : null,
        avgTripRating: (row['avg_trip_rating'] as num?)?.toDouble(),
        passengers: passengers,
      );
    }).toList();
  }

  Future<List<PassengerTripHistory>> fetchPassengerHistory() async {
    final data = await _client.rpc('get_passenger_history') as List;
    return data.map((row) {
      final timeRaw = row['departure_time'] as String?;
      return PassengerTripHistory(
        id: row['request_id'] as String,
        departureDate: DateTime.parse(row['departure_date'] as String),
        originAddress: row['origin_address'] as String,
        destinationAddress: row['destination_address'] as String,
        pricePerSeat: (row['price_per_seat'] as num).toInt(),
        driverName: row['driver_name'] as String? ?? 'Conductor',
        driverRating: (row['driver_rating'] as num?)?.toDouble() ?? 0.0,
        departureTime: timeRaw != null && timeRaw.length >= 5
            ? timeRaw.substring(0, 5)
            : null,
      );
    }).toList();
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final historyRepositoryProvider =
    Provider<HistoryRepository>((_) => HistoryRepository());

final activeDriverTripsProvider =
    FutureProvider.autoDispose<List<ActiveDriverTrip>>((ref) {
  return ref.read(historyRepositoryProvider).fetchActiveDriverTrips();
});

final driverHistoryProvider =
    FutureProvider.autoDispose<List<DriverTripHistory>>((ref) async {
  await ref.read(historyRepositoryProvider).updatePastTripStatuses();
  return ref.read(historyRepositoryProvider).fetchDriverHistory();
});

final passengerHistoryProvider =
    FutureProvider.autoDispose<List<PassengerTripHistory>>((ref) {
  return ref.read(historyRepositoryProvider).fetchPassengerHistory();
});
