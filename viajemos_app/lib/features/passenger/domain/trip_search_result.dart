class TripPassengerPreview {
  const TripPassengerPreview({required this.userId, required this.name, this.avatarUrl});
  final String userId;
  final String name;
  final String? avatarUrl;
}

class TripSearchResult {
  const TripSearchResult({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverRating,
    this.driverAvatarUrl,
    required this.originAddress,
    required this.destinationAddress,
    required this.departureDate,
    this.departureTime,
    required this.availableSeats,
    required this.seatsTaken,
    required this.pricePerSeat,
    required this.allowsPets,
    required this.picksUpAtDoor,
    required this.dropsOffAtDoor,
    required this.via,
    required this.stops,
    this.description,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleColor,
    this.passengers = const [],
    this.splitCosts = false,
    this.pickupAddress,
    this.dropoffAddress,
    this.boardingStop,
    this.alightingStop,
  });

  final String id;
  final String driverId;
  final String driverName;
  final double driverRating;
  final String? driverAvatarUrl;
  final String originAddress;
  final String destinationAddress;
  final String departureDate; // ISO "YYYY-MM-DD"
  final String? departureTime; // "HH:mm:ss" or null
  final int availableSeats;
  final int seatsTaken;
  final int pricePerSeat;
  final bool allowsPets;
  final bool picksUpAtDoor;
  final bool dropsOffAtDoor;
  final List<String> via;   // route names, e.g. "Ruta Nacional 9"
  final List<String> stops; // intermediate cities
  final String? description;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleColor;
  final List<TripPassengerPreview> passengers;
  final bool splitCosts;
  final String? pickupAddress;
  final String? dropoffAddress;
  /// Non-null when the passenger boards at an intermediate stop (not at the trip origin).
  final String? boardingStop;
  /// Non-null when the passenger alights at an intermediate stop (not at the final destination).
  final String? alightingStop;

  int get freeSeats => availableSeats - seatsTaken;

  String get vehicleDisplay {
    if (vehicleBrand == null) return '';
    return '$vehicleBrand $vehicleModel · $vehicleColor';
  }

  /// "15 de abril"
  String get formattedDate {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    try {
      final d = DateTime.parse(departureDate);
      return '${d.day} de ${months[d.month - 1]}';
    } catch (_) {
      return departureDate;
    }
  }

  /// "HH:mm" from "HH:mm:ss"
  String get formattedTime {
    if (departureTime == null) return '';
    return departureTime!.substring(0, 5);
  }

  /// Extracts the city name from a stored address string.
  /// Handles two formats:
  ///   "City, Province, Country"  → first segment  (from Nominatim place search)
  ///   "Number, Neighborhood, City" → last segment  (from map pin drop)
  static String _cityFromAddress(String address) {
    final parts = address
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length <= 1) return address.trim();
    // If the first segment is a street number, the city is the last segment.
    if (RegExp(r'^\d').hasMatch(parts.first)) return parts.last;
    return parts.first;
  }

  String get originCity => _cityFromAddress(originAddress);
  String get destinationCity => _cityFromAddress(destinationAddress);

  /// Returns the full address only when it contains more detail than just a city
  /// (i.e. has a comma — street number or neighborhood info).
  String? get originDetailAddress =>
      originAddress.contains(',') ? originAddress : null;
  String? get destinationDetailAddress =>
      destinationAddress.contains(',') ? destinationAddress : null;

  String get driverInitials {
    final parts = driverName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return driverName.isNotEmpty ? driverName[0].toUpperCase() : '?';
  }

  TripSearchResult copyWith({String? boardingStop, String? alightingStop}) {
    return TripSearchResult(
      id: id,
      driverId: driverId,
      driverName: driverName,
      driverRating: driverRating,
      driverAvatarUrl: driverAvatarUrl,
      originAddress: originAddress,
      destinationAddress: destinationAddress,
      departureDate: departureDate,
      departureTime: departureTime,
      availableSeats: availableSeats,
      seatsTaken: seatsTaken,
      pricePerSeat: pricePerSeat,
      allowsPets: allowsPets,
      picksUpAtDoor: picksUpAtDoor,
      dropsOffAtDoor: dropsOffAtDoor,
      via: via,
      stops: stops,
      description: description,
      vehicleBrand: vehicleBrand,
      vehicleModel: vehicleModel,
      vehicleColor: vehicleColor,
      passengers: passengers,
      splitCosts: splitCosts,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      boardingStop: boardingStop ?? this.boardingStop,
      alightingStop: alightingStop ?? this.alightingStop,
    );
  }

  factory TripSearchResult.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};
    final vehicle = json['vehicles'] as Map<String, dynamic>?;
    return TripSearchResult(
      id: json['id'] as String,
      driverId: json['owner_id'] as String,
      driverName: (profile['full_name'] as String?) ?? 'Conductor',
      driverRating: (profile['avg_rating'] as num?)?.toDouble() ?? 0.0,
      driverAvatarUrl: profile['avatar_url'] as String?,
      originAddress: json['origin_address'] as String,
      destinationAddress: json['destination_address'] as String,
      departureDate: json['departure_date'] as String,
      departureTime: json['departure_time'] as String?,
      availableSeats: json['available_seats'] as int,
      seatsTaken: json['seats_taken'] as int,
      pricePerSeat: (json['price_per_seat'] as num).toInt(),
      allowsPets: json['allows_pets'] as bool? ?? false,
      picksUpAtDoor: json['picks_up_at_door'] as bool? ?? false,
      dropsOffAtDoor: json['drops_off_at_door'] as bool? ?? false,
      via: (json['via'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      stops: (json['stops'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      description: json['description'] as String?,
      vehicleBrand: vehicle?['brand'] as String?,
      vehicleModel: vehicle?['model'] as String?,
      vehicleColor: vehicle?['color'] as String?,
      splitCosts: json['split_costs'] as bool? ?? false,
      pickupAddress: json['pickup_address'] as String?,
      dropoffAddress: json['dropoff_address'] as String?,
      passengers: ((json['trip_requests'] as List?) ?? [])
          .where((r) => r['status'] == 'accepted')
          .map((r) {
            final p = r['profiles'] as Map<String, dynamic>? ?? {};
            return TripPassengerPreview(
              userId: r['passenger_id'] as String? ?? '',
              name: p['full_name'] as String? ?? 'Pasajero',
              avatarUrl: p['avatar_url'] as String?,
            );
          })
          .toList(),
    );
  }
}
