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
    this.originExactAddress,
    this.destinationExactAddress,
    this.departureTime,
    this.avgTripRating,
  });

  final String id;
  final DateTime departureDate;
  final String originAddress;
  final String destinationAddress;
  final String? originExactAddress;
  final String? destinationExactAddress;
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
    required this.status,
    this.originExactAddress,
    this.destinationExactAddress,
    this.departureTime,
  });

  final String id;
  final DateTime departureDate;
  final String originAddress;
  final String destinationAddress;
  final String? originExactAddress;
  final String? destinationExactAddress;
  final int pricePerSeat;
  final String driverName;
  final double driverRating;
  final String status; // 'pending' | 'accepted' | 'declined'
  final String? departureTime;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
}

// Active request (pending or accepted, future trip)
class ActivePassengerRequest {
  const ActivePassengerRequest({
    required this.id,
    required this.tripId,
    required this.departureDate,
    required this.originAddress,
    required this.destinationAddress,
    required this.pricePerSeat,
    required this.seatsRequested,
    required this.status,
    required this.driverName,
    required this.driverId,
    required this.driverRating,
    this.departureTime,
    this.driverAvatarUrl,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleColor,
  });

  final String id; // request_id
  final String tripId;
  final DateTime departureDate;
  final String originAddress;
  final String destinationAddress;
  final int pricePerSeat;
  final int seatsRequested;
  final String status; // 'pending' | 'accepted'
  final String driverName;
  final String driverId;
  final double driverRating;
  final String? departureTime;
  final String? driverAvatarUrl;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleColor;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  String get vehicleDisplay {
    if (vehicleBrand == null) return '';
    return '$vehicleBrand $vehicleModel · $vehicleColor';
  }
}

// Completed trip (accepted request, departure date in the past)
class PassengerCompletedTrip {
  const PassengerCompletedTrip({
    required this.id,
    required this.tripId,
    required this.departureDate,
    required this.originAddress,
    required this.destinationAddress,
    required this.pricePerSeat,
    required this.driverName,
    required this.driverId,
    required this.driverRating,
    required this.hasRated,
    required this.via,
    this.departureTime,
    this.driverAvatarUrl,
    this.myRating,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleColor,
  });

  final String id; // request_id
  final String tripId;
  final DateTime departureDate;
  final String originAddress;
  final String destinationAddress;
  final int pricePerSeat;
  final String driverName;
  final String driverId;
  final double driverRating;
  final bool hasRated;
  final List<String> via;
  final String? departureTime;
  final String? driverAvatarUrl;
  final int? myRating;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleColor;

  String get vehicleDisplay {
    if (vehicleBrand == null) return '';
    return '$vehicleBrand $vehicleModel · $vehicleColor';
  }
}

// Passenger's own trip alert (pedido de viaje) with pending invitation count
class MyTripAlert {
  const MyTripAlert({
    required this.id,
    required this.originAddress,
    required this.destinationAddress,
    required this.dateFrom,
    required this.dateTo,
    required this.seatsNeeded,
    required this.pendingInvitations,
    required this.timeFlexible,
    this.departureTime,
    this.departureTimeTo,
    this.maxPrice,
    this.description,
    this.hasPet = false,
    this.isSmoker = false,
  });

  final String id;
  final String originAddress;
  final String destinationAddress;
  final DateTime dateFrom;
  final DateTime dateTo;
  final int seatsNeeded;
  final int pendingInvitations;
  final bool timeFlexible;
  final String? departureTime; // "HH:mm"
  final String? departureTimeTo;
  final int? maxPrice;
  final String? description;
  final bool hasPet;
  final bool isSmoker;

  bool get hasInvitations => pendingInvitations > 0;
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
    required this.acceptedPassengerIds,
    required this.acceptedPassengerRequestIds,
    required this.acceptedPassengerAvatarUrls,
    required this.via,
    required this.stops,
    required this.allowsPets,
    required this.picksUpAtDoor,
    required this.dropsOffAtDoor,
    required this.isPrivate,
    this.originExactAddress,
    this.destinationExactAddress,
    this.departureTime,
    this.description,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleColor,
  });

  final String id;
  final DateTime departureDate;
  final String originAddress;
  final String destinationAddress;
  final String? originExactAddress;
  final String? destinationExactAddress;
  final int availableSeats;
  final int seatsTaken;
  final int pricePerSeat;
  final String status;
  final int pendingRequestsCount;
  final List<String> acceptedPassengerNames;
  final List<String> acceptedPassengerIds;
  final List<String> acceptedPassengerRequestIds;
  final List<String?> acceptedPassengerAvatarUrls;
  final List<String> via;
  final List<String> stops;
  final bool allowsPets;
  final bool picksUpAtDoor;
  final bool dropsOffAtDoor;
  final bool isPrivate;
  final String? departureTime;
  final String? description;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleColor;

  int get freeSeats => availableSeats - seatsTaken;
  bool get isFull => status == 'full';

  String get vehicleDisplay {
    if (vehicleBrand == null) return '';
    return '$vehicleBrand $vehicleModel · $vehicleColor';
  }
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
    this.passengerAvatarUrl,
    this.message,
  });

  final String requestId;
  final String passengerId;
  final String passengerName;
  final String? passengerAvatarUrl;
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

  Future<Map<String, Map<String, String?>>> _fetchExactAddresses(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final rows = await _client
          .from('trips')
          .select('id, pickup_address, dropoff_address')
          .inFilter('id', ids) as List;
      return {
        for (final r in rows)
          r['id'] as String: {
            'pickup_address': r['pickup_address'] as String?,
            'dropoff_address': r['dropoff_address'] as String?,
          }
      };
    } catch (_) {
      return {};
    }
  }

  Future<List<ActiveDriverTrip>> fetchActiveDriverTrips() async {
    final data = await _client.rpc('get_driver_active_trips') as List;
    final ids = data.map((r) => r['id'] as String).toList();
    final exactAddrs = await _fetchExactAddresses(ids);
    return data.map((row) {
      final id = row['id'] as String;
      final timeRaw = row['departure_time'] as String?;
      return ActiveDriverTrip(
        id: id,
        departureDate: DateTime.parse(row['departure_date'] as String),
        originAddress: row['origin_address'] as String,
        destinationAddress: row['destination_address'] as String,
        originExactAddress: exactAddrs[id]?['pickup_address'],
        destinationExactAddress: exactAddrs[id]?['dropoff_address'],
        availableSeats: (row['available_seats'] as int?) ?? 0,
        seatsTaken: (row['seats_taken'] as int?) ?? 0,
        pricePerSeat: (row['price_per_seat'] as num).toInt(),
        status: row['status'] as String,
        pendingRequestsCount: (row['pending_requests_count'] as num?)?.toInt() ?? 0,
        acceptedPassengerNames:
            (row['accepted_passenger_names'] as List?)?.cast<String>() ?? [],
        acceptedPassengerIds:
            (row['accepted_passenger_ids'] as List?)?.cast<String>() ?? [],
        acceptedPassengerRequestIds:
            (row['accepted_passenger_request_ids'] as List?)?.cast<String>() ?? [],
        acceptedPassengerAvatarUrls:
            (row['accepted_passenger_avatar_urls'] as List?)?.cast<String?>() ?? [],
        via: (row['via'] as List?)?.cast<String>() ?? [],
        stops: (row['stops'] as List?)?.cast<String>() ?? [],
        allowsPets: row['allows_pets'] as bool? ?? false,
        picksUpAtDoor: row['picks_up_at_door'] as bool? ?? false,
        dropsOffAtDoor: row['drops_off_at_door'] as bool? ?? false,
        isPrivate: row['is_private'] as bool? ?? false,
        departureTime: timeRaw != null && timeRaw.length >= 5
            ? timeRaw.substring(0, 5)
            : null,
        description: row['description'] as String?,
        vehicleBrand: row['vehicle_brand'] as String?,
        vehicleModel: row['vehicle_model'] as String?,
        vehicleColor: row['vehicle_color'] as String?,
      );
    }).toList();
  }

  Future<void> toggleTripPrivacy(String tripId, bool isPrivate) async {
    await _client.rpc('toggle_trip_privacy', params: {
      'p_trip_id': tripId,
      'p_is_private': isPrivate,
    });
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
        passengerAvatarUrl: row['passenger_avatar_url'] as String?,
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

  Future<void> cancelTrip(String tripId, {String? message}) async {
    await _client.rpc('cancel_trip', params: {
      'p_trip_id': tripId,
      'p_message': message,
    });
  }

  Future<void> expelPassenger(String requestId, {String? message}) async {
    await _client.rpc('expel_passenger', params: {
      'p_request_id': requestId,
      'p_message': message,
    });
  }

  Future<List<DriverTripHistory>> fetchDriverHistory() async {
    final data = await _client.rpc('get_driver_history') as List;
    final ids = data.map((r) => r['id'] as String).toList();
    final exactAddrs = await _fetchExactAddresses(ids);
    return data.map((row) {
      final id = row['id'] as String;
      final passengers = (row['passengers'] as List? ?? [])
          .map((p) => PassengerInTrip(
                name: p['name'] as String? ?? 'Pasajero',
                rating: (p['rating'] as num?)?.toDouble() ?? 0.0,
              ))
          .toList();
      final timeRaw = row['departure_time'] as String?;
      return DriverTripHistory(
        id: id,
        departureDate: DateTime.parse(row['departure_date'] as String),
        originAddress: row['origin_address'] as String,
        destinationAddress: row['destination_address'] as String,
        originExactAddress: exactAddrs[id]?['pickup_address'],
        destinationExactAddress: exactAddrs[id]?['dropoff_address'],
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
    final tripIds = data
        .map((r) => r['trip_id'] as String?)
        .whereType<String>()
        .toList();
    final exactAddrs = await _fetchExactAddresses(tripIds);
    return data.map((row) {
      final tripId = row['trip_id'] as String?;
      final timeRaw = row['departure_time'] as String?;
      return PassengerTripHistory(
        id: row['request_id'] as String,
        departureDate: DateTime.parse(row['departure_date'] as String),
        originAddress: row['origin_address'] as String,
        destinationAddress: row['destination_address'] as String,
        originExactAddress: tripId == null ? null : (exactAddrs[tripId] ?? {})['pickup_address'],
        destinationExactAddress: tripId == null ? null : (exactAddrs[tripId] ?? {})['dropoff_address'],
        pricePerSeat: (row['price_per_seat'] as num).toInt(),
        driverName: row['driver_name'] as String? ?? 'Conductor',
        driverRating: (row['driver_rating'] as num?)?.toDouble() ?? 0.0,
        status: row['status'] as String? ?? 'accepted',
        departureTime: timeRaw != null && timeRaw.length >= 5
            ? timeRaw.substring(0, 5)
            : null,
      );
    }).toList();
  }

  Future<void> updatePassengerPendingStatuses() async {
    await _client.rpc('update_passenger_pending_statuses');
  }

  Future<List<ActivePassengerRequest>> fetchPassengerActiveRequests() async {
    final data = await _client.rpc('get_passenger_active_requests') as List;
    return data.map((row) {
      final timeRaw = row['departure_time'] as String?;
      return ActivePassengerRequest(
        id: row['request_id'] as String,
        tripId: row['trip_id'] as String,
        departureDate: DateTime.parse(row['departure_date'] as String),
        originAddress: row['origin_address'] as String,
        destinationAddress: row['destination_address'] as String,
        pricePerSeat: (row['price_per_seat'] as num).toInt(),
        seatsRequested: (row['seats_requested'] as int?) ?? 1,
        status: row['status'] as String,
        driverName: row['driver_name'] as String? ?? 'Conductor',
        driverId: row['driver_id'] as String,
        driverRating: (row['driver_rating'] as num?)?.toDouble() ?? 0.0,
        driverAvatarUrl: row['driver_avatar_url'] as String?,
        departureTime: timeRaw != null && timeRaw.length >= 5
            ? timeRaw.substring(0, 5)
            : null,
        vehicleBrand: row['vehicle_brand'] as String?,
        vehicleModel: row['vehicle_model'] as String?,
        vehicleColor: row['vehicle_color'] as String?,
      );
    }).toList();
  }

  Future<List<PassengerCompletedTrip>> fetchPassengerCompletedTrips() async {
    final data = await _client.rpc('get_passenger_completed_trips') as List;
    return data.map((row) {
      final timeRaw = row['departure_time'] as String?;
      return PassengerCompletedTrip(
        id: row['request_id'] as String,
        tripId: row['trip_id'] as String,
        departureDate: DateTime.parse(row['departure_date'] as String),
        originAddress: row['origin_address'] as String,
        destinationAddress: row['destination_address'] as String,
        pricePerSeat: (row['price_per_seat'] as num).toInt(),
        driverName: row['driver_name'] as String? ?? 'Conductor',
        driverId: row['driver_id'] as String,
        driverRating: (row['driver_rating'] as num?)?.toDouble() ?? 0.0,
        hasRated: row['has_rated'] as bool? ?? false,
        via: (row['via'] as List?)?.cast<String>() ?? [],
        departureTime: timeRaw != null && timeRaw.length >= 5
            ? timeRaw.substring(0, 5)
            : null,
        driverAvatarUrl: row['driver_avatar_url'] as String?,
        myRating: row['my_rating'] as int?,
        vehicleBrand: row['vehicle_brand'] as String?,
        vehicleModel: row['vehicle_model'] as String?,
        vehicleColor: row['vehicle_color'] as String?,
      );
    }).toList();
  }

  Future<void> cancelPassengerRequest(String requestId) async {
    await _client.rpc(
      'cancel_passenger_request',
      params: {'p_request_id': requestId},
    );
  }

  String? _trimTime(dynamic v) {
    final s = v as String?;
    if (s == null || s.length < 5) return null;
    return s.substring(0, 5);
  }

  Future<List<MyTripAlert>> fetchMyTripAlerts() async {
    final data = await _client.rpc('get_my_trip_alerts') as List;
    return data.map((row) {
      return MyTripAlert(
        id: row['alert_id'] as String,
        originAddress: row['origin_address'] as String,
        destinationAddress: row['destination_address'] as String,
        dateFrom: DateTime.parse(row['date_from'] as String),
        dateTo: DateTime.parse(row['date_to'] as String),
        seatsNeeded: (row['seats_needed'] as int?) ?? 1,
        pendingInvitations: (row['pending_invitations'] as int?) ?? 0,
        timeFlexible: row['time_flexible'] as bool? ?? true,
        departureTime: _trimTime(row['departure_time']),
        departureTimeTo: _trimTime(row['departure_time_to']),
        maxPrice: row['max_price'] as int?,
        description: row['description'] as String?,
        hasPet: row['has_pet'] as bool? ?? false,
        isSmoker: row['is_smoker'] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> deactivateAlert(String alertId) async {
    await _client.rpc('deactivate_trip_alert', params: {'p_alert_id': alertId});
  }

  Future<void> submitDriverReview({
    required String tripId,
    required String driverId,
    required int rating,
    String? comment,
  }) async {
    await _client.rpc('submit_driver_review', params: {
      'p_trip_id': tripId,
      'p_driver_id': driverId,
      'p_rating': rating,
      'p_comment': comment,
    });
  }

  Future<Map<String, dynamic>?> fetchTripForRepeat(String tripId) async {
    return await _client
        .from('trips')
        .select(
            'origin_address, destination_address, departure_time, allows_pets, picks_up_at_door, drops_off_at_door, via, stops, description, vehicle_id')
        .eq('id', tripId)
        .maybeSingle();
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

final passengerActiveRequestsProvider =
    FutureProvider.autoDispose<List<ActivePassengerRequest>>((ref) async {
  await ref.read(historyRepositoryProvider).updatePassengerPendingStatuses();
  return ref.read(historyRepositoryProvider).fetchPassengerActiveRequests();
});

final passengerCompletedTripsProvider =
    FutureProvider.autoDispose<List<PassengerCompletedTrip>>((ref) {
  return ref.read(historyRepositoryProvider).fetchPassengerCompletedTrips();
});

final myTripAlertsProvider =
    FutureProvider.autoDispose<List<MyTripAlert>>((ref) {
  return ref.read(historyRepositoryProvider).fetchMyTripAlerts();
});
