import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/app_notification.dart';
import 'notifications_repository.dart';

// ── Unread count badge ──────────────────────────────────────────────────────

final notificationUnreadCountProvider =
    StateNotifierProvider<_UnreadCountNotifier, int>(
        (_) => _UnreadCountNotifier());

class _UnreadCountNotifier extends StateNotifier<int> {
  final _client = Supabase.instance.client;
  RealtimeChannel? _channel;

  _UnreadCountNotifier() : super(0) {
    _fetch();
    _subscribe();
  }

  Future<void> _fetch() async {
    try {
      final repo = NotificationsRepository();
      final count = await repo.getUnreadCount();
      if (mounted) state = count;
    } catch (_) {}
  }

  void _subscribe() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    _channel = _client
        .channel('notifications-badge')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (_) => _fetch(),
        )
        .subscribe();
  }

  void refresh() => _fetch();

  @override
  void dispose() {
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}

// ── Latest notifications list (dropdown + screen) ───────────────────────────
// NOT autoDispose: provider lives for the app lifetime so it is never destroyed
// while the dropdown/screen is open, which would cause a stale re-fetch that
// flips notifications back to unread. Callers are responsible for calling
// refresh() when they first open the dropdown or screen.

final notificationsListProvider =
    StateNotifierProvider<NotificationsListNotifier,
        AsyncValue<List<AppNotification>>>((_) => NotificationsListNotifier());

class NotificationsListNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final _repo = NotificationsRepository();

  NotificationsListNotifier() : super(const AsyncValue.loading()) {
    _fetch();
  }

  Future<void> _fetch() async {
    // Set loading FIRST so no user interaction is possible until fresh data
    // arrives. This eliminates the race between a background fetch and an
    // optimistic update the user applies while the fetch is in-flight.
    if (mounted) state = const AsyncValue.loading();
    try {
      final items = await _repo.fetchLatest(limit: 50);
      if (mounted) state = AsyncValue.data(items);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(String id) async {
    final list = state.asData?.value;
    if (list == null) return;
    if (mounted) {
      state = AsyncValue.data(
        list.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
      );
    }
    // Await the DB write so it commits before any subsequent refresh can race it.
    // Do NOT re-fetch on error — keep the optimistic update.
    try {
      await _repo.markRead(id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final list = state.asData?.value;
    if (list == null) return;
    if (mounted) {
      state = AsyncValue.data(list.map((n) => n.copyWith(read: true)).toList());
    }
    try {
      await _repo.markAllRead();
    } catch (_) {}
  }

  void refresh() => _fetch();
}
