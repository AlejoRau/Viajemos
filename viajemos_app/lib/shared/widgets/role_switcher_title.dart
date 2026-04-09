import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/role_provider.dart';
import '../../core/theme/app_theme.dart';

/// AppBar title that shows the current role ("Conductor" / "Pasajero") with a
/// dropdown arrow. Tapping it opens a small menu to switch roles.
class RoleSwitcherTitle extends ConsumerWidget {
  const RoleSwitcherTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final isConductor = role == '/driver';
    final label = isConductor ? 'Conductor' : 'Pasajero';
    final color = isConductor ? AppColors.primary : const Color(0xFF1E293B);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showRoleMenu(context, ref, isConductor),
      child: Row(
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
    );
  }

  void _showRoleMenu(BuildContext context, WidgetRef ref, bool isConductor) {
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
        _roleItem('Conductor', Icons.directions_car_rounded, '/driver',
            selected: isConductor),
        _roleItem('Pasajero', Icons.backpack_rounded, '/passenger',
            selected: !isConductor),
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
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w400,
              color: selected
                  ? AppColors.primary
                  : const Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          if (selected)
            const Icon(Icons.check_rounded,
                size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
}
