import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/role_provider.dart';

// Mock data — reemplazar con datos de Supabase cuando esté listo

class _DriverPassenger {
  const _DriverPassenger({required this.name, required this.rating});
  final String name;
  final double rating;
}

class _DriverTrip {
  _DriverTrip({
    required this.id,
    required this.date,
    required this.origin,
    required this.destination,
    required this.rating,
    required this.earnings,
    required this.passengers,
    this.pricePerSeat,
    this.departureTime,
    this.stops,
  });
  final String id;
  final DateTime date;
  final String origin;
  final String destination;
  final double rating;
  final int earnings;
  final List<_DriverPassenger> passengers;
  final int? pricePerSeat;
  final String? departureTime;
  final List<String>? stops;

  int get participantCount => passengers.length;
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
    pricePerSeat: 6500,
    departureTime: '08:00',
    stops: const ['Rosario', 'Villa María'],
    passengers: const [
      _DriverPassenger(name: 'María García', rating: 5.0),
      _DriverPassenger(name: 'Lucas Pérez', rating: 4.8),
      _DriverPassenger(name: 'Sofía Romero', rating: 4.9),
    ],
  ),
  _DriverTrip(
    id: '2',
    date: DateTime(2026, 3, 15),
    origin: 'Mendoza',
    destination: 'San Luis',
    rating: 4.7,
    earnings: 16500,
    pricePerSeat: 5500,
    departureTime: '09:30',
    passengers: const [
      _DriverPassenger(name: 'Carlos Díaz', rating: 4.7),
      _DriverPassenger(name: 'Ana Torres', rating: 4.6),
      _DriverPassenger(name: 'Martín López', rating: 5.0),
    ],
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
              const Icon(Icons.people_rounded,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${trip.participantCount} pasajero${trip.participantCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _DriverTripDetailSheet(trip: trip),
                ),
                child: const Text(
                  'Ver detalles',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

// ── Driver trip detail sheet ───────────────────────────────────────────────

class _DriverTripDetailSheet extends StatelessWidget {
  const _DriverTripDetailSheet({required this.trip});
  final _DriverTrip trip;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${trip.date.day.toString().padLeft(2, '0')}/${trip.date.month.toString().padLeft(2, '0')}/${trip.date.year}';

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.origin} → ${trip.destination}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(dateStr,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            if (trip.departureTime != null) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.access_time_rounded,
                                  size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(trip.departureTime!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Rating badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 18, color: Color(0xFFEAB308)),
                        const SizedBox(width: 4),
                        Text(
                          trip.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF713F12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.border),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: [
                  // ── Resumen económico ──────────────────────────────────
                  _DetailSection(
                    icon: Icons.attach_money_rounded,
                    title: 'Resumen económico',
                    child: Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            label: 'Total ganado',
                            value: '+\$${_formatNum(trip.earnings)}',
                            valueColor: AppColors.primary,
                            valueFontSize: 20,
                            bold: true,
                          ),
                        ),
                        if (trip.pricePerSeat != null)
                          Expanded(
                            child: _InfoTile(
                              label: 'Precio por asiento',
                              value: '\$${_formatNum(trip.pricePerSeat!)}',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Paradas ────────────────────────────────────────────
                  _DetailSection(
                    icon: Icons.place_rounded,
                    title: 'Ruta',
                    child: _StopsTimeline(
                      origin: trip.origin,
                      destination: trip.destination,
                      stops: trip.stops,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Pasajeros ──────────────────────────────────────────
                  _DetailSection(
                    icon: Icons.people_rounded,
                    title: 'Pasajeros (${trip.passengers.length})',
                    child: Column(
                      children: trip.passengers.map((p) {
                        final initials = p.name
                            .split(' ')
                            .take(2)
                            .map((w) => w[0])
                            .join();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 14,
                                      color: Color(0xFFFACC15)),
                                  const SizedBox(width: 3),
                                  Text(
                                    p.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000),
              blurRadius: 4,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StopsTimeline extends StatefulWidget {
  const _StopsTimeline({
    required this.origin,
    required this.destination,
    this.stops,
  });
  final String origin;
  final String destination;
  final List<String>? stops;

  @override
  State<_StopsTimeline> createState() => _StopsTimelineState();
}

class _StopsTimelineState extends State<_StopsTimeline> {
  static const int _collapseThreshold = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final stops = widget.stops ?? <String>[];
    final shouldCollapse = stops.length > _collapseThreshold;
    final visibleStops = shouldCollapse && !_expanded
        ? stops.take(2).toList()
        : stops;
    final visiblePoints = [widget.origin, ...visibleStops, widget.destination];
    final hiddenCount = stops.length - 2;

    return Column(
      children: [
        for (int i = 0; i < visiblePoints.length; i++)
          _TimelineRow(
            label: visiblePoints[i],
            isFirst: i == 0,
            isLast: i == visiblePoints.length - 1,
            showLine: i < visiblePoints.length - 1,
            // Insert collapsed indicator between last visible stop and destination
            insertCollapsed: shouldCollapse &&
                !_expanded &&
                i == visiblePoints.length - 2,
            hiddenCount: hiddenCount,
            onExpand: () => setState(() => _expanded = true),
          ),
        if (shouldCollapse && _expanded)
          GestureDetector(
            onTap: () => setState(() => _expanded = false),
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 6),
              child: Text(
                'Ver menos',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.isFirst,
    required this.isLast,
    required this.showLine,
    this.insertCollapsed = false,
    this.hiddenCount = 0,
    this.onExpand,
  });
  final String label;
  final bool isFirst;
  final bool isLast;
  final bool showLine;
  final bool insertCollapsed;
  final int hiddenCount;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isFirst || isLast
                        ? AppColors.primary
                        : const Color(0xFFCBD5E1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFirst || isLast
                          ? AppColors.primary
                          : const Color(0xFF94A3B8),
                      width: 1.5,
                    ),
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Label + optional collapsed indicator
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isFirst || isLast
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (insertCollapsed) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onExpand,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+ $hiddenCount paradas más',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontSize = 15,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final double valueFontSize;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
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
