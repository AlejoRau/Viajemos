import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/role_provider.dart';
import '../../core/providers/badge_providers.dart';
import '../../core/theme/app_theme.dart';

/// AppBar title that shows the current role ("Conductor" / "Pasajero") with a
/// dropdown arrow. Tapping it opens a small menu to switch roles.
/// An orange dot is shown when the OTHER role has pending notifications.
class RoleSwitcherTitle extends ConsumerWidget {
  const RoleSwitcherTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final isConductor = role == '/driver';
    final label = isConductor ? 'Conductor' : 'Pasajero';
    final color = isConductor ? AppColors.primary : const Color(0xFF1E293B);

    // Notifications for the role the user is NOT currently on.
    final driverBadge = ref.watch(pendingRequestsCountProvider);
    final passengerBadge = ref.watch(pendingInvitationsCountProvider);
    final otherRoleBadge = isConductor ? passengerBadge : driverBadge;
    final hasOtherNotifications = otherRoleBadge > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showRoleMenu(
        context,
        ref,
        isConductor,
        driverBadge: driverBadge,
        passengerBadge: passengerBadge,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.passengerTitle.copyWith(color: color),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down_rounded, color: color, size: 22),
            ],
          ),
          if (hasOtherNotifications)
            Positioned(
              top: -2,
              right: -6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFF97316),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showRoleMenu(
    BuildContext context,
    WidgetRef ref,
    bool isConductor, {
    required int driverBadge,
    required int passengerBadge,
  }) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu<String>(
      context: context,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        0,
      ),
      items: [
        _roleItem(
          'Conductor',
          Icons.directions_car_rounded,
          '/driver',
          selected: isConductor,
          badge: driverBadge,
        ),
        _roleItem(
          'Pasajero',
          Icons.backpack_rounded,
          '/passenger',
          selected: !isConductor,
          badge: passengerBadge,
        ),
      ],
    ).then((value) {
      if (value == null || !context.mounted) return;
      ref.read(roleProvider.notifier).state = value;
      context.go(value);
    });
  }

  PopupMenuItem<String> _roleItem(
    String label,
    IconData icon,
    String value, {
    required bool selected,
    required int badge,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: selected ? AppColors.primary : const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? AppColors.primary : const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge > 9 ? '+9' : '$badge',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          else if (selected)
            const Icon(Icons.check_rounded,
                size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
}
