import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerRequest {
  const PassengerRequest({
    required this.id,
    required this.userId,
    required this.passengerName,
    required this.originAddress,
    required this.destinationAddress,
    required this.dateFrom,
    required this.dateTo,
    required this.seatsNeeded,
    required this.hasPet,
    required this.isSmoker,
    this.departureTime,
    this.departureTimeTo,
    this.maxPrice,
    this.description,
    this.avgRating,
  });

  final String id;
  final String userId;
  final String passengerName;
  final String originAddress;
  final String destinationAddress;
  final DateTime dateFrom;
  final DateTime? dateTo;
  final int seatsNeeded;
  final bool hasPet;
  final bool isSmoker;
  final String? departureTime;
  final String? departureTimeTo;
  final int? maxPrice;
  final String? description;
  final double? avgRating;

  String get formattedDateRange {
    final from = '${dateFrom.day.toString().padLeft(2, '0')}/${dateFrom.month.toString().padLeft(2, '0')}';
    if (dateTo == null ||
        (dateFrom.year == dateTo!.year &&
            dateFrom.month == dateTo!.month &&
            dateFrom.day == dateTo!.day)) {
      return from;
    }
    final to = '${dateTo!.day.toString().padLeft(2, '0')}/${dateTo!.month.toString().padLeft(2, '0')}';
    return '$from – $to';
  }

  String get timeWindow {
    if (departureTime == null) return '';
    if (departureTimeTo == null) return departureTime!.substring(0, 5);
    return '${departureTime!.substring(0, 5)} – ${departureTimeTo!.substring(0, 5)}';
  }

  factory PassengerRequest.fromJson(Map<String, dynamic> json) {
    final profile = (json['profiles'] as Map<String, dynamic>?) ?? {};
    return PassengerRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      passengerName: (profile['full_name'] as String?) ?? 'Pasajero',
      originAddress: (json['origin_address'] as String?) ?? '',
      destinationAddress: (json['destination_address'] as String?) ?? '',
      dateFrom: DateTime.parse(json['date_from'] as String),
      dateTo: json['date_to'] != null ? DateTime.parse(json['date_to'] as String) : null,
      seatsNeeded: json['seats_needed'] as int,
      hasPet: json['has_pet'] as bool,
      isSmoker: json['is_smoker'] as bool,
      departureTime: json['departure_time'] as String?,
      departureTimeTo: json['departure_time_to'] as String?,
      maxPrice: json['max_price'] as int?,
      description: json['description'] as String?,
      avgRating: (profile['avg_rating_passenger'] as num?)?.toDouble(),
    );
  }
}

class PassengerRequestRepository {
  final _client = Supabase.instance.client;

  /// Insert a new trip alert (passenger request).
  Future<void> publishRequest({
    required String originAddress,
    required String destinationAddress,
    required DateTime dateFrom,
    DateTime? dateTo,
    required int seatsNeeded,
    required bool hasPet,
    required bool isSmoker,
    required int maxPrice,
    String? departureTime,   // "HH:MM"
    String? departureTimeTo, // "HH:MM"
    String? description,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    await _client.from('trip_alerts').insert({
      'user_id': user.id,
      'origin_address': originAddress,
      'destination_address': destinationAddress,
      'date_from': dateFrom.toIso8601String().substring(0, 10),
      if (dateTo != null) 'date_to': dateTo.toIso8601String().substring(0, 10),
      'seats_needed': seatsNeeded,
      'has_pet': hasPet,
      'is_smoker': isSmoker,
      'max_price': maxPrice,
      if (departureTime != null) 'departure_time': departureTime,
      if (departureTimeTo != null) 'departure_time_to': departureTimeTo,
      if (description != null && description.isNotEmpty) 'description': description,
      'is_active': true,
    });
  }

  /// Fetch active trip alerts for the driver's search screen.
  /// Optionally filter by [origin] and/or [destination] (case-insensitive substring).
  Future<List<PassengerRequest>> fetchRequests({
    String? origin,
    String? destination,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    var query = _client
        .from('trip_alerts')
        .select('*, profiles!user_id(full_name, avg_rating_passenger)')
        .eq('is_active', true);

    if (origin != null && origin.isNotEmpty) {
      query = query.ilike('origin_address', '%$origin%');
    }
    if (destination != null && destination.isNotEmpty) {
      query = query.ilike('destination_address', '%$destination%');
    }
    if (dateFrom != null) {
      query = query.gte('date_to', dateFrom.toIso8601String().substring(0, 10));
    }
    if (dateTo != null) {
      query = query.lte('date_from', dateTo.toIso8601String().substring(0, 10));
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List)
        .map((row) => PassengerRequest.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
