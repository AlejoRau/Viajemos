import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _ProfileHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionLabel('Mi cuenta'),
                const SizedBox(height: 8),
                _MenuCard(items: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Mis datos',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.star_outline_rounded,
                    label: 'Mis reseñas',
                    trailing: _Badge('4.9'),
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.directions_car_outlined,
                    label: 'Mis viajes',
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 20),
                _SectionLabel('Configuración'),
                const SizedBox(height: 8),
                _MenuCard(items: [
                  _MenuItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notificaciones',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Privacidad',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Ayuda',
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 20),
                _MenuCard(items: [
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Cerrar sesión',
                    labelColor: AppColors.destructive,
                    iconColor: AppColors.destructive,
                    showChevron: false,
                    onTap: () {},
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xE61B6B3A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 32,
        left: 24,
        right: 24,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundImage:
                    const NetworkImage('https://i.pravatar.cc/150?img=3'),
                backgroundColor: AppColors.primaryLight,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Lucas García',
              style: AppTextStyles.h2.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text('lucas@email.com',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(value: '23', label: 'Viajes'),
              const SizedBox(width: 24),
              _StatChip(value: '4.9', label: 'Calificación'),
              const SizedBox(width: 24),
              _StatChip(value: '12', label: 'Reseñas'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style:
                AppTextStyles.h3.copyWith(color: Colors.white, fontSize: 20)),
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
      ],
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.labelSmall
            .copyWith(color: AppColors.textSecondary, letterSpacing: 0.5));
  }
}

// ─── Menu Card ────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              item,
              if (!isLast)
                const Divider(height: 1, indent: 52),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.labelColor,
    this.iconColor,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? labelColor;
  final Color? iconColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 22,
                color: iconColor ?? AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: labelColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  )),
            ),
            if (trailing != null) trailing!,
            if (showChevron) ...[
              if (trailing != null) const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: AppColors.accent),
          const SizedBox(width: 3),
          Text(text,
              style: AppTextStyles.labelXSmall
                  .copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}
