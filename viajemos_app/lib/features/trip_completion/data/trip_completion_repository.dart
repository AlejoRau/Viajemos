import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Models ─────────────────────────────────────────────────────────────────

class TripPendingAction {
  const TripPendingAction({
    required this.tripId,
    required this.originAddress,
    required this.destinationAddress,
    required this.departureDate,
    this.departureTime,
    required this.status,
    required this.passengerIds,
    required this.passengerNames,
    required this.passengerAvatars,
  });

  final String tripId;
  final String originAddress;
  final String destinationAddress;
  final DateTime departureDate;
  final String? departureTime; // "HH:MM:SS"
  final String status; // 'in_progress' | 'indeterminate'
  final List<String> passengerIds;
  final List<String> passengerNames;
  final List<String> passengerAvatars; // empty string = no avatar

  bool get isIndeterminate => status == 'indeterminate';

  String get formattedTime {
    if (departureTime == null) return '';
    return departureTime!.length >= 5 ? departureTime!.substring(0, 5) : departureTime!;
  }
}

class PassengerRating {
  const PassengerRating({
    required this.passengerId,
    required this.rating,
    this.comment,
  });

  final String passengerId;
  final int rating;
  final String? comment;

  Map<String, dynamic> toJson() => {
        'passenger_id': passengerId,
        'rating': rating,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };
}

// ── Repository ──────────────────────────────────────────────────────────────

class TripCompletionRepository {
  final _client = Supabase.instance.client;

  Future<List<TripPendingAction>> fetchDriverTripsPendingAction() async {
    final data = await _client.rpc('get_driver_trips_pending_action') as List;
    return data.map((row) {
      final m = row as Map<String, dynamic>;
      return TripPendingAction(
        tripId: m['trip_id'] as String,
        originAddress: m['origin_address'] as String,
        destinationAddress: m['destination_address'] as String,
        departureDate: DateTime.parse(m['departure_date'] as String),
        departureTime: m['departure_time'] as String?,
        status: m['status'] as String,
        passengerIds: List<String>.from(m['accepted_passenger_ids'] as List? ?? []),
        passengerNames: List<String>.from(m['accepted_passenger_names'] as List? ?? []),
        passengerAvatars: List<String>.from(m['accepted_passenger_avatars'] as List? ?? []),
      );
    }).toList();
  }

  Future<void> confirmTripCompleted({
    required String tripId,
    required List<PassengerRating> ratings,
  }) async {
    await _client.rpc('confirm_trip_completed', params: {
      'p_trip_id': tripId,
      'p_passenger_ratings': ratings.map((r) => r.toJson()).toList(),
    });
  }

  Future<void> resolveIndeterminateTrip({
    required String tripId,
    required bool wasCompleted,
    String? reason,
  }) async {
    await _client.rpc('resolve_indeterminate_trip', params: {
      'p_trip_id': tripId,
      'p_was_completed': wasCompleted,
      if (reason != null && reason.isNotEmpty) 'p_reason': reason,
    });
  }

  Future<int> getPassengerPendingReviewsCount() async {
    final result = await _client.rpc('get_passenger_pending_reviews_count');
    return (result as num?)?.toInt() ?? 0;
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

final tripCompletionRepositoryProvider =
    Provider<TripCompletionRepository>((_) => TripCompletionRepository());

/// Session-scoped set of trip IDs the passenger dismissed ("rate later").
/// Resets on app restart so the prompt reappears next session.
final dismissedReviewsProvider = StateProvider<Set<String>>((_) => {});
