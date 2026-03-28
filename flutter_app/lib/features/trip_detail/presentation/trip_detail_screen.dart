import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const seatsTotal = 4;
    const seatsTaken = 1;
    const seatsAvailable = seatsTotal - seatsTaken;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _MapPlaceholder(context: context)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _DriverCard(),
                    const SizedBox(height: 16),
                    _TripInfoCard(),
                    const SizedBox(height: 16),
                    _PassengersCard(
                      seatsTotal: seatsTotal,
                      seatsTaken: seatsTaken,
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // CTA button
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Pedir unirse al viaje',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map placeholder (route line visual) ─────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.35,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x664CAF7D), Color(0x661B6B3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Route line
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(height: 3, color: AppColors.primary),
                  Positioned(
                    left: -6,
                    top: -9,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    top: -9,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(ctx).padding.top + 12,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).maybePop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 8)
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Driver Card ──────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage:
                            const NetworkImage('https://i.pravatar.cc/150?img=11'),
                        backgroundColor: AppColors.muted,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Martín López', style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text('4.9',
                                style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.textPrimary)),
                            const SizedBox(width: 6),
                            Text('•',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary)),
                            const SizedBox(width: 6),
                            Text('23 viajes',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _IconBtn(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () {}),
                      const SizedBox(width: 8),
                      _IconBtn(icon: Icons.phone_outlined, onTap: () {}),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  'Viaje directo por autopista, salgo puntual. Acepto mascotas pequeñas.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primarySubtle,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
    );
  }
}

// ─── Trip Info Card ───────────────────────────────────────────────────────────

class _TripInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalles del viaje', style: AppTextStyles.h4),
            const SizedBox(height: 16),

            // Route
            _DetailRow(
              icon: Icons.location_on_rounded,
              iconColor: AppColors.primary,
              label: 'Origen',
              value: 'Córdoba Capital',
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Container(
                  width: 2, height: 20, color: AppColors.muted,
                  margin: const EdgeInsets.symmetric(vertical: 4)),
            ),
            _DetailRow(
              icon: Icons.location_on_rounded,
              iconColor: AppColors.accent,
              label: 'Destino',
              value: 'Buenos Aires',
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Grid 2x2
            Row(
              children: [
                Expanded(
                  child: _MetaItem(
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppColors.primaryLight,
                    label: 'Fecha',
                    value: '28 de marzo',
                  ),
                ),
                Expanded(
                  child: _MetaItem(
                    icon: Icons.access_time_rounded,
                    iconColor: AppColors.primaryLight,
                    label: 'Hora',
                    value: '08:00',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetaItem(
                    icon: Icons.people_outline_rounded,
                    iconColor: AppColors.primaryLight,
                    label: 'Asientos',
                    value: '3 disponibles',
                  ),
                ),
                Expanded(
                  child: _MetaItem(
                    icon: Icons.attach_money_rounded,
                    iconColor: AppColors.accent,
                    label: 'Precio',
                    value: '\$2500',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            Text(value, style: AppTextStyles.labelMedium),
          ],
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary, fontSize: 11)),
            Text(value,
                style: AppTextStyles.labelMedium
                    .copyWith(fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

// ─── Passengers Card ──────────────────────────────────────────────────────────

class _PassengersCard extends StatelessWidget {
  const _PassengersCard({
    required this.seatsTotal,
    required this.seatsTaken,
  });
  final int seatsTotal;
  final int seatsTaken;

  @override
  Widget build(BuildContext context) {
    final seatsAvailable = seatsTotal - seatsTaken;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pasajeros confirmados ($seatsTaken)',
                style: AppTextStyles.h4),
            const SizedBox(height: 14),
            Row(
              children: [
                // Confirmed passenger
                _AvatarSlot(
                  imageUrl: 'https://i.pravatar.cc/150?img=9',
                  name: 'Ana',
                ),
                const SizedBox(width: 14),
                // Empty slots
                ...List.generate(
                  seatsAvailable,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.muted,
                                width: 2,
                                style: BorderStyle.solid),
                          ),
                          child: const Icon(Icons.person_outline_rounded,
                              color: AppColors.muted, size: 24),
                        ),
                        const SizedBox(height: 4),
                        Text('Libre',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarSlot extends StatelessWidget {
  const _AvatarSlot({required this.imageUrl, required this.name});
  final String imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundImage: NetworkImage(imageUrl),
          backgroundColor: AppColors.muted,
        ),
        const SizedBox(height: 4),
        Text(name,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
