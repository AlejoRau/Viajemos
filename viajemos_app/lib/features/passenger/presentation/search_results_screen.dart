import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class _Trip {
  const _Trip({
    required this.driverName,
    required this.rating,
    required this.reviewCount,
    required this.origin,
    required this.destination,
    required this.stops,
    required this.date,
    this.endDate,
    required this.time,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.acceptsPets,
    required this.acceptsSmokers,
    required this.car,
    this.passengerInitials = const [],
  });
  final String driverName;
  final double rating;
  final int reviewCount;
  final String origin;
  final String destination;
  final int stops;
  final String date;
  final String? endDate;
  final String time;
  final int totalSeats;
  final int availableSeats;
  final int pricePerSeat;
  final bool acceptsPets;
  final bool acceptsSmokers;
  final String car;
  final List<String> passengerInitials;
}

const _mockTrips = [
  _Trip(driverName: 'Carlos Rodríguez', rating: 4.8, reviewCount: 23, origin: 'Buenos Aires', destination: 'Córdoba', stops: 2, date: '05/04', endDate: '07/04', time: '08:00', totalSeats: 4, availableSeats: 2, pricePerSeat: 6500, acceptsPets: true, acceptsSmokers: false, car: 'Toyota Corolla · Gris', passengerInitials: ['ML', 'JP']),
  _Trip(driverName: 'Ana López', rating: 4.9, reviewCount: 41, origin: 'Rosario', destination: 'Buenos Aires', stops: 0, date: '06/04', time: '14:30', totalSeats: 3, availableSeats: 2, pricePerSeat: 4000, acceptsPets: false, acceptsSmokers: false, car: 'Honda Civic · Blanco', passengerInitials: ['GR']),
  _Trip(driverName: 'Diego Fernández', rating: 4.7, reviewCount: 17, origin: 'Mendoza', destination: 'San Luis', stops: 1, date: '08/04', time: '10:00', totalSeats: 5, availableSeats: 3, pricePerSeat: 5500, acceptsPets: true, acceptsSmokers: true, car: 'Ford Focus · Negro', passengerInitials: ['AM', 'SV']),
  _Trip(driverName: 'Laura Gómez', rating: 4.6, reviewCount: 9, origin: 'Buenos Aires', destination: 'Mar del Plata', stops: 0, date: '05/04', time: '06:00', totalSeats: 3, availableSeats: 1, pricePerSeat: 3500, acceptsPets: false, acceptsSmokers: false, car: 'Volkswagen Gol · Rojo', passengerInitials: ['NB', 'TC']),
];

String _formatDate(String date) {
  const months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  final parts = date.split('/');
  if (parts.length != 2) return date;
  final day = int.tryParse(parts[0]) ?? 0;
  final month = int.tryParse(parts[1]) ?? 0;
  if (month < 1 || month > 12 || day < 1) return date;
  return '$day de ${months[month - 1]}';
}

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({
    super.key,
    required this.origin,
    this.destination,
  });

  final String origin;
  final String? destination;

  String get _title {
    final from = origin.isNotEmpty ? origin : 'Origen';
    if (destination != null && destination!.isNotEmpty) {
      return '$from  →  $destination';
    }
    return '$from  →';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mockTrips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _TripCard(trip: _mockTrips[i]),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final _Trip trip;

  String get _initials {
    final parts = trip.driverName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return trip.driverName.substring(0, 2).toUpperCase();
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripDetailsSheet(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conductor + precio
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(_initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.driverName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFACC15)),
                          const SizedBox(width: 2),
                          Text('${trip.rating}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${trip.pricePerSeat.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Ruta
            Row(
              children: [
                Text(trip.origin, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                ),
                Text(trip.destination, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                if (trip.stops > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                    child: Text('${trip.stops} parada${trip.stops > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // Fecha y hora
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${trip.date}  •  ${trip.time}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),

            // Badges
            if (trip.acceptsPets || trip.acceptsSmokers) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (trip.acceptsPets)
                    _Badge(label: 'Mascotas', icon: Icons.pets_rounded, bg: AppColors.greenLight, fg: AppColors.green),
                  if (trip.acceptsPets && trip.acceptsSmokers) const SizedBox(width: 6),
                  if (trip.acceptsSmokers)
                    _Badge(label: 'Fumadores', icon: Icons.smoking_rooms_rounded, bg: AppColors.orangeLight, fg: AppColors.orange),
                ],
              ),
            ],
            const SizedBox(height: 10),

            // Viajeros
            Row(
              children: [
                const Text(
                  'Viajeros:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                for (int i = 0; i < (trip.totalSeats - trip.availableSeats); i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        i < trip.passengerInitials.length ? trip.passengerInitials[i] : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                for (int i = 0; i < trip.availableSeats; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.inputBackground,
                      child: const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  '${trip.totalSeats - trip.availableSeats}/${trip.totalSeats}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Auto
            Row(
              children: [
                const Icon(Icons.directions_car_rounded, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(trip.car, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripDetailsSheet extends StatelessWidget {
  const _TripDetailsSheet({required this.trip});
  final _Trip trip;

  String get _initials {
    final parts = trip.driverName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return trip.driverName.substring(0, 2).toUpperCase();
  }

  String get _dateTitle {
    final from = _formatDate(trip.date);
    if (trip.endDate != null) return '$from - ${_formatDate(trip.endDate!)}';
    return from;
  }

  String get _formattedPrice =>
      '\$${trip.pricePerSeat.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fecha
                  Text(
                    _dateTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Ruta
                  Row(
                    children: [
                      Text(
                        trip.origin,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward, size: 15, color: AppColors.primary),
                      ),
                      Text(
                        trip.destination,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 20),

                  // Conductor
                  GestureDetector(
                    onTap: () {
                      // TODO: navegar al perfil del conductor
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.driverName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFACC15)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${trip.rating}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '· ${trip.reviewCount} opiniones',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // Detalles del viaje
                  _DetailRow(icon: Icons.access_time_rounded, text: '${trip.date}  ·  ${trip.time}'),
                  const SizedBox(height: 10),
                  _DetailRow(icon: Icons.directions_car_rounded, text: trip.car),
                  if (trip.stops > 0) ...[
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.place_rounded,
                      text: '${trip.stops} parada${trip.stops > 1 ? 's' : ''} en el camino',
                    ),
                  ],
                  if (trip.acceptsPets || trip.acceptsSmokers) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (trip.acceptsPets)
                          _Badge(label: 'Mascotas', icon: Icons.pets_rounded, bg: AppColors.greenLight, fg: AppColors.green),
                        if (trip.acceptsPets && trip.acceptsSmokers) const SizedBox(width: 8),
                        if (trip.acceptsSmokers)
                          _Badge(label: 'Fumadores', icon: Icons.smoking_rooms_rounded, bg: AppColors.orangeLight, fg: AppColors.orange),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Viajeros
                  const Text(
                    'Viajeros',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (int i = 0; i < (trip.totalSeats - trip.availableSeats); i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              i < trip.passengerInitials.length ? trip.passengerInitials[i] : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      for (int i = 0; i < trip.availableSeats; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.inputBackground,
                            child: const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '${trip.totalSeats - trip.availableSeats}/${trip.totalSeats}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Precio
                  Row(
                    children: [
                      Text(
                        _formattedPrice,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'por asiento',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Botón fijo
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: enviar solicitud
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Solicitud enviada a ${trip.driverName}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  elevation: 0,
                ),
                child: const Text(
                  'Enviar solicitud',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, required this.bg, required this.fg});
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
