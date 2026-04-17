import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 0),
                    _NextTripCard(),
                    const SizedBox(height: 16),
                    _QuickActionCard(
                      title: 'Solicitudes pendientes',
                      subtitle: '3 personas quieren unirse',
                      badge: '3',
                      badgeColor: AppColors.accent,
                      borderColor: AppColors.accentSubtle,
                      onTap: () => Navigator.of(context).pushNamed('/trip-requests'),
                    ),
                    const SizedBox(height: 12),
                    _ActionGrid(),
                  ]),
                ),
              ),
            ],
          ),

          // FAB
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => Navigator.of(context).pushNamed('/create-trip'),
              backgroundColor: AppColors.primary,
              elevation: 6,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
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
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buenos días, Lucas 👋',
              style: AppTextStyles.h2.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            '¿Listo para tu próximo viaje?',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ─── Next Trip Card ───────────────────────────────────────────────────────────

class _NextTripCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tu próximo viaje', style: AppTextStyles.h4),
                  _Badge(label: 'Confirmado', color: AppColors.primarySubtle, textColor: AppColors.primary),
                ],
              ),
              const SizedBox(height: 16),

              // Route
              _RouteRow(
                iconColor: AppColors.primary,
                label: 'Desde',
                place: 'Córdoba',
              ),
              _RouteDivider(),
              _RouteRow(
                iconColor: AppColors.accent,
                label: 'Hasta',
                place: 'Buenos Aires',
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Meta row
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('Mañana, 08:00', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('2/4 asientos', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Passengers
              Text('Pasajeros confirmados',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              _PassengerAvatars(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.iconColor, required this.label, required this.place});
  final Color iconColor;
  final String label;
  final String place;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.location_on_rounded, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            Text(place, style: AppTextStyles.labelMedium),
          ],
        ),
      ],
    );
  }
}

class _RouteDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 9),
      child: Container(
        width: 2,
        height: 20,
        color: AppColors.muted,
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }
}

class _PassengerAvatars extends StatelessWidget {
  final _passengers = const [
    {'name': 'María', 'url': 'https://i.pravatar.cc/150?img=5'},
    {'name': 'Carlos', 'url': 'https://i.pravatar.cc/150?img=12'},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ..._passengers.map((p) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(p['url']!),
                    backgroundColor: AppColors.muted,
                  ),
                  const SizedBox(height: 4),
                  Text(p['name']!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            )),
        Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.muted, width: 2),
              ),
              child: Center(
                child: Text('+2',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(height: 4),
            Text('Libres',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.borderColor,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;
  final Color? borderColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h4),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: badgeColor ?? AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(badge!,
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
                ),
              )
            else if (trailing != null)
              trailing!,
          ],
        ),
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.textColor});
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(label, style: AppTextStyles.labelXSmall.copyWith(color: textColor)),
    );
  }
}

// ─── Action Grid ──────────────────────────────────────────────────────────────

class _ActionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            label: 'Publicar viaje',
            icon: Icons.directions_car_rounded,
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF2D8A57)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.of(context).pushNamed('/create-trip'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            label: 'Buscar viajes',
            icon: Icons.search_rounded,
            gradient: const LinearGradient(
              colors: [AppColors.accent, Color(0xFFE09520)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.of(context).pushNamed('/search'),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
