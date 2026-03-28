import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final Set<String> _activeFilters = {};

  static const _filters = ['Hoy', 'Precio ↑', 'Con foto'];

  static const _trips = [
    _TripData(
      id: '1',
      driverName: 'Martín López',
      driverRating: 4.9,
      driverImageUrl: 'https://i.pravatar.cc/150?img=11',
      origin: 'Córdoba',
      destination: 'Buenos Aires',
      date: 'Mañana',
      time: '08:00',
      seatsTotal: 4,
      seatsTaken: 1,
      price: 2500,
    ),
    _TripData(
      id: '2',
      driverName: 'Laura Fernández',
      driverRating: 4.7,
      driverImageUrl: 'https://i.pravatar.cc/150?img=20',
      origin: 'Córdoba',
      destination: 'Buenos Aires',
      date: 'Mañana',
      time: '10:30',
      seatsTotal: 3,
      seatsTaken: 0,
      price: 2800,
    ),
    _TripData(
      id: '3',
      driverName: 'Diego Romero',
      driverRating: 4.6,
      driverImageUrl: 'https://i.pravatar.cc/150?img=14',
      origin: 'Córdoba',
      destination: 'Buenos Aires',
      date: 'Mañana',
      time: '14:00',
      seatsTotal: 4,
      seatsTaken: 2,
      price: 2300,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _SearchHeader(
            activeFilters: _activeFilters,
            onFilterTap: (f) => setState(() {
              _activeFilters.contains(f)
                  ? _activeFilters.remove(f)
                  : _activeFilters.add(f);
            }),
            filters: _filters,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              itemCount: _trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _TripCard(trip: _trips[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header with search + filters ────────────────────────────────────────────

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.activeFilters,
    required this.onFilterTap,
    required this.filters,
  });

  final Set<String> activeFilters;
  final ValueChanged<String> onFilterTap;
  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Buscar viajes',
                  style: AppTextStyles.h3.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 14),

          // Search box
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Escribir ciudad inicio',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white54),
                          border: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(color: Colors.white.withOpacity(0.2), height: 16),
                Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Escribir ciudad destino',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white54),
                          border: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...filters.map((f) {
                  final active = activeFilters.contains(f);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onFilterTap(f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          f,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: active ? AppColors.primary : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trip Card ────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final _TripData trip;

  @override
  Widget build(BuildContext context) {
    final seatsAvailable = trip.seatsTotal - trip.seatsTaken;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/trip-detail'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Driver row
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(trip.driverImageUrl),
                  backgroundColor: AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.driverName, style: AppTextStyles.labelMedium),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 15, color: AppColors.accent),
                          const SizedBox(width: 3),
                          Text(
                            trip.driverRating.toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${trip.price}',
                      style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                    ),
                    Text('por asiento',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Route + time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(trip.origin, style: AppTextStyles.labelMedium),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          width: 2,
                          height: 18,
                          color: AppColors.muted,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(trip.destination,
                              style: AppTextStyles.labelMedium),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(trip.date,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(trip.time, style: AppTextStyles.h4),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),

            // Seats row
            Row(
              children: [
                const Icon(Icons.people_outline_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '$seatsAvailable ${seatsAvailable == 1 ? 'asiento' : 'asientos'}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                // Seat dots
                Row(
                  children: List.generate(trip.seatsTotal, (i) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < trip.seatsTaken
                            ? AppColors.muted
                            : AppColors.primaryLight,
                      ),
                    ),
                  )),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text('Ver viaje',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _TripData {
  const _TripData({
    required this.id,
    required this.driverName,
    required this.driverRating,
    required this.driverImageUrl,
    required this.origin,
    required this.destination,
    required this.date,
    required this.time,
    required this.seatsTotal,
    required this.seatsTaken,
    required this.price,
  });

  final String id;
  final String driverName;
  final double driverRating;
  final String driverImageUrl;
  final String origin;
  final String destination;
  final String date;
  final String time;
  final int seatsTotal;
  final int seatsTaken;
  final int price;
}
