import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/trip_completion/data/trip_completion_repository.dart';

// ── Unread messages count (chat nav badge) ─────────────────────────────────

final unreadCountProvider =
    StateNotifierProvider<UnreadCountNotifier, int>((_) => UnreadCountNotifier());

class UnreadCountNotifier extends StateNotifier<int> {
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  UnreadCountNotifier() : super(0) {
    _fetch();
    _subscribe();
  }

  Future<void> _fetch() async {
    try {
      final result = await _client.rpc('get_total_unread_messages');
      if (mounted) state = (result as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  void _subscribe() {
    _channel = _client
        .channel('unread-messages-badge')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) => _fetch(),
        )
        .subscribe();
  }

  Future<void> refresh() => _fetch();

  @override
  void dispose() {
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}

// ── Pending invitations count (history nav badge, passengers only) ──────────

final pendingInvitationsCountProvider =
    StateNotifierProvider<PendingInvitationsNotifier, int>(
        (_) => PendingInvitationsNotifier());

class PendingInvitationsNotifier extends StateNotifier<int> {
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  PendingInvitationsNotifier() : super(0) {
    _fetch();
    _subscribe();
  }

  Future<void> _fetch() async {
    try {
      final result = await _client.rpc('get_total_pending_invitations');
      if (mounted) state = (result as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  void _subscribe() {
    _channel = _client
        .channel('pending-invitations-badge')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_invitations',
          callback: (_) => _fetch(),
        )
        .subscribe();
  }

  Future<void> refresh() => _fetch();

  @override
  void dispose() {
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}

// ── Pending trip requests count (history nav badge, drivers only) ───────────

final pendingRequestsCountProvider =
    StateNotifierProvider<PendingRequestsNotifier, int>(
        (_) => PendingRequestsNotifier());

class PendingRequestsNotifier extends StateNotifier<int> {
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  PendingRequestsNotifier() : super(0) {
    _fetch();
    _subscribe();
  }

  Future<void> _fetch() async {
    try {
      final result = await _client.rpc('get_total_pending_trip_requests');
      if (mounted) state = (result as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  void _subscribe() {
    _channel = _client
        .channel('pending-requests-badge')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_requests',
          callback: (_) => _fetch(),
        )
        .subscribe();
  }

  Future<void> refresh() => _fetch();

  @override
  void dispose() {
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}

// ── Pending passenger reviews count (history nav badge, passengers only) ────

final pendingPassengerReviewsCountProvider =
    StateNotifierProvider<PendingPassengerReviewsNotifier, int>(
        (_) => PendingPassengerReviewsNotifier());

class PendingPassengerReviewsNotifier extends StateNotifier<int> {
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  PendingPassengerReviewsNotifier() : super(0) {
    _fetch();
    _subscribe();
  }

  Future<void> _fetch() async {
    try {
      final count =
          await TripCompletionRepository().getPassengerPendingReviewsCount();
      if (mounted) state = count;
    } catch (_) {}
  }

  void _subscribe() {
    _channel = _client
        .channel('pending-passenger-reviews-badge')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'reviews',
          callback: (_) => _fetch(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'trips',
          callback: (_) => _fetch(),
        )
        .subscribe();
  }

  Future<void> refresh() => _fetch();

  @override
  void dispose() {
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}
