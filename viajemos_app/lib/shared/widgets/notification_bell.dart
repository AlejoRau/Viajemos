import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/notifications/data/notifications_provider.dart';
import '../../features/notifications/domain/app_notification.dart';

class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _toggle() {
    if (_overlay != null) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _showOverlay() {
    // Fetch fresh data every time the dropdown opens.
    ref.read(notificationsListProvider.notifier).refresh();

    final overlay = Overlay.of(context);
    _overlay = OverlayEntry(
      builder: (_) => _NotificationDropdown(
        layerLink: _layerLink,
        onDismiss: _removeOverlay,
        onViewAll: () {
          _removeOverlay();
          context.push('/notifications');
        },
      ),
    );
    overlay.insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(notificationUnreadCountProvider);
    return CompositedTransformTarget(
      link: _layerLink,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(
              unread > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: _toggle,
          ),
          if (unread > 0)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Dropdown overlay ─────────────────────────────────────────────────────────
// Uses its OWN WidgetRef (from build), NOT the parent's ref.
// This is critical: the overlay lives in a separate Flutter overlay stack,
// so only its own local ref drives correct rebuilds and keeps the provider alive.

class _NotificationDropdown extends ConsumerWidget {
  final LayerLink layerLink;
  final VoidCallback onDismiss;
  final VoidCallback onViewAll;

  const _NotificationDropdown({
    required this.layerLink,
    required this.onDismiss,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsListProvider);
    final latest3 = state.whenOrNull(
      data: (list) => list.take(3).toList(),
    );

    return Stack(
      children: [
        // Backdrop — tapping outside closes the dropdown
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // Dropdown card
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 4),
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: Colors.transparent,
              child: _DropdownCard(
                notifications: latest3 ?? [],
                loading: state is AsyncLoading,
                onTapNotification: (n) {
                  if (!n.read) {
                    ref
                        .read(notificationsListProvider.notifier)
                        .markRead(n.id);
                  }
                },
                onViewAll: onViewAll,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownCard extends StatelessWidget {
  final List<AppNotification> notifications;
  final bool loading;
  final void Function(AppNotification) onTapNotification;
  final VoidCallback onViewAll;

  const _DropdownCard({
    required this.notifications,
    required this.loading,
    required this.onTapNotification,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            const Divider(height: 1, color: AppColors.border),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (notifications.isEmpty)
              const _EmptyDropdown()
            else
              ...notifications.map(
                (n) => _DropdownItem(
                  notification: n,
                  onTap: () => onTapNotification(n),
                ),
              ),
            const Divider(height: 1, color: AppColors.border),
            _ViewAllButton(onTap: onViewAll),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.notifications_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          SizedBox(width: 8),
          Text(
            'Notificaciones',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _DropdownItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? AppColors.primaryLight.withValues(alpha: 0.35) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SmallTypeIcon(type: notification.type),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isUnread ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 4),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays} días';
  }
}

class _SmallTypeIcon extends StatelessWidget {
  final String type;
  const _SmallTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      'trip_request' => (Icons.person_add_rounded, const Color(0xFF7C3AED)),
      'invitation'   => (Icons.card_travel_rounded, const Color(0xFF059669)),
      'message'      => (Icons.chat_bubble_rounded, AppColors.primary),
      'trip_update'  => (Icons.directions_car_rounded, const Color(0xFFD97706)),
      _              => (Icons.notifications_rounded, AppColors.textSecondary),
    };
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _EmptyDropdown extends StatelessWidget {
  const _EmptyDropdown();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 32,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 8),
          Text(
            'Sin notificaciones nuevas',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: AppColors.pageBackground,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ver todas las notificaciones',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
