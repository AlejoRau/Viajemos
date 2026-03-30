import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/role_provider.dart';

// Mock data — reemplazar con datos de Supabase cuando esté listo

class _DriverTrip {
  _DriverTrip({
    required this.id,
    required this.date,
    required this.origin,
    required this.destination,
    required this.rating,
    required this.earnings,
    required this.participants,
  });
  final String id;
  final DateTime date;
  final String origin;
  final String destination;
  final double rating;
  final int earnings;
  final int participants;
}

class _PassengerTrip {
  _PassengerTrip({
    required this.id,
    required this.date,
    required this.origin,
    required this.destination,
    required this.driverName,
    required this.rating,
    required this.cost,
  });
  final String id;
  final DateTime date;
  final String origin;
  final String destination;
  final String driverName;
  final double rating;
  final int cost;
}

final _driverTrips = [
  _DriverTrip(
    id: '1',
    date: DateTime(2026, 3, 25),
    origin: 'Buenos Aires',
    destination: 'Córdoba',
    rating: 4.8,
    earnings: 19500,
    participants: 3,
  ),
  _DriverTrip(
    id: '2',
    date: DateTime(2026, 3, 15),
    origin: 'Mendoza',
    destination: 'San Luis',
    rating: 4.7,
    earnings: 16500,
    participants: 3,
  ),
];

final _passengerTrips = [
  _PassengerTrip(
    id: '1',
    date: DateTime(2026, 3, 20),
    origin: 'Rosario',
    destination: 'Buenos Aires',
    driverName: 'Ana López',
    rating: 5.0,
    cost: 4000,
  ),
  _PassengerTrip(
    id: '2',
    date: DateTime(2026, 3, 10),
    origin: 'La Plata',
    destination: 'Mar del Plata',
    driverName: 'Carlos Gómez',
    rating: 4.9,
    cost: 5500,
  ),
  _PassengerTrip(
    id: '3',
    date: DateTime(2026, 2, 28),
    origin: 'Buenos Aires',
    destination: 'Córdoba',
    driverName: 'Diego Martínez',
    rating: 4.7,
    cost: 6500,
  ),
  _PassengerTrip(
    id: '4',
    date: DateTime(2026, 2, 15),
    origin: 'Mendoza',
    destination: 'San Juan',
    driverName: 'Laura Fernández',
    rating: 5.0,
    cost: 3500,
  ),
];

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final isDriver = role == '/driver';

    return Scaffold(
      appBar: AppBar(title: const Text('Mi historial de viajes')),
      body: isDriver
            ? const _DriverHistoryBody()
            : const _PassengerHistoryBody(),
    );
  }
}

// ── Vista conductor ────────────────────────────────────────────────────────

class _DriverHistoryBody extends StatelessWidget {
  const _DriverHistoryBody();

  @override
  Widget build(BuildContext context) {
    final trips = _driverTrips;
    final totalEarnings = trips.fold(0, (sum, t) => sum + t.earnings);
    final avgRating = trips.fold(0.0, (sum, t) => sum + t.rating) / trips.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.directions_car_rounded,
                  value: '${trips.length}',
                  label: 'Viajes',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.star_rounded,
                  value: avgRating.toStringAsFixed(1),
                  label: 'Rating',
                  iconColor: const Color(0xFFFACC15),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  value: '\$${(totalEarnings / 1000).toStringAsFixed(0)}k',
                  label: 'Ganado',
                  valueFontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Lista
          const Text(
            'Viajes realizados',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...trips.map((trip) => _DriverTripCard(trip: trip)),
        ],
      ),
    );
  }
}

class _DriverTripCard extends StatelessWidget {
  const _DriverTripCard({required this.trip});
  final _DriverTrip trip;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${trip.date.day.toString().padLeft(2, '0')}/${trip.date.month.toString().padLeft(2, '0')}/${trip.date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Izquierda: ruta + fecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          trip.origin,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '→',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            trip.destination,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Derecha: rating + ganancias
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFFACC15)),
                      const SizedBox(width: 3),
                      Text(
                        trip.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+\$${_formatNum(trip.earnings)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${trip.participants} pasajero${trip.participants > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Ver detalles',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Vista pasajero ─────────────────────────────────────────────────────────

class _PassengerHistoryBody extends StatelessWidget {
  const _PassengerHistoryBody();

  @override
  Widget build(BuildContext context) {
    final trips = _passengerTrips;
    final totalSpent = trips.fold(0, (sum, t) => sum + t.cost);
    final avgRating = trips.fold(0.0, (sum, t) => sum + t.rating) / trips.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.location_on_rounded,
                  value: '${trips.length}',
                  label: 'Viajes',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.star_rounded,
                  value: avgRating.toStringAsFixed(1),
                  label: 'Rating',
                  iconColor: const Color(0xFFFACC15),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.attach_money_rounded,
                  value: '\$${(totalSpent / 1000).toStringAsFixed(0)}k',
                  label: 'Gastado',
                  valueFontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Lista
          const Text(
            'Viajes realizados',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...trips.map((trip) => _PassengerTripCard(trip: trip)),
        ],
      ),
    );
  }
}

class _PassengerTripCard extends StatelessWidget {
  const _PassengerTripCard({required this.trip});
  final _PassengerTrip trip;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${trip.date.day.toString().padLeft(2, '0')}/${trip.date.month.toString().padLeft(2, '0')}/${trip.date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Izquierda: ruta + fecha + conductor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          trip.origin,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '→',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            trip.destination,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Conductor: ${trip.driverName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Derecha: rating + costo
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFFACC15)),
                      const SizedBox(width: 3),
                      Text(
                        trip.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_formatNum(trip.cost)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: const Text(
                'Ver detalles',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets compartidos ────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
    this.valueFontSize = 24,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: iconColor ?? AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNum(int n) {
  // Formatea con punto como separador de miles: 19500 → 19.500
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return buffer.toString();
}
