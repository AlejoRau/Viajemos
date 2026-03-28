import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  static const _pastTrips = [
    _TripHistoryItem(
      origin: 'Córdoba',
      destination: 'Buenos Aires',
      date: '15 mar 2026',
      price: 2500,
      role: 'Pasajero',
      status: 'Completado',
    ),
    _TripHistoryItem(
      origin: 'Buenos Aires',
      destination: 'Rosario',
      date: '02 mar 2026',
      price: 1800,
      role: 'Conductor',
      status: 'Completado',
    ),
    _TripHistoryItem(
      origin: 'Córdoba',
      destination: 'Villa Carlos Paz',
      date: '20 feb 2026',
      price: 900,
      role: 'Pasajero',
      status: 'Completado',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionLabel('Viaje actual'),
                const SizedBox(height: 10),
                _CurrentTripCard(),
                const SizedBox(height: 24),
                _SectionLabel('Historial'),
                const SizedBox(height: 10),
                ..._pastTrips.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HistoryCard(trip: t),
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis viajes',
              style: AppTextStyles.h2.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text('3 viajes completados',
              style:
                  AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.labelMedium
            .copyWith(color: AppColors.textSecondary));
  }
}

// ─── Current Trip Card ────────────────────────────────────────────────────────

class _CurrentTripCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tu próximo viaje', style: AppTextStyles.h4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text('Confirmado',
                    style: AppTextStyles.labelXSmall
                        .copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text('Córdoba', style: AppTextStyles.labelMedium),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
                width: 2,
                height: 18,
                color: AppColors.muted,
                margin: const EdgeInsets.symmetric(vertical: 3)),
          ),
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text('Buenos Aires', style: AppTextStyles.labelMedium),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Mañana, 08:00',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              const Icon(Icons.people_outline_rounded,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('2/4 asientos',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.trip});
  final _TripHistoryItem trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(Icons.directions_car_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(trip.origin, style: AppTextStyles.labelMedium),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward,
                          size: 12, color: AppColors.textSecondary),
                    ),
                    Text(trip.destination, style: AppTextStyles.labelMedium),
                  ],
                ),
                const SizedBox(height: 3),
                Text(trip.date,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${trip.price}',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primary)),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(trip.role,
                    style: AppTextStyles.labelXSmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripHistoryItem {
  const _TripHistoryItem({
    required this.origin,
    required this.destination,
    required this.date,
    required this.price,
    required this.role,
    required this.status,
  });
  final String origin;
  final String destination;
  final String date;
  final int price;
  final String role;
  final String status;
}
