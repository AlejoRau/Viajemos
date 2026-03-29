import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/radius_slider.dart';
import '../../../shared/formatters/date_formatter.dart';

class _Trip {
  const _Trip({
    required this.driverName,
    required this.rating,
    required this.origin,
    required this.destination,
    required this.stops,
    required this.date,
    required this.time,
    required this.totalSeats,
    required this.availableSeats,
    required this.pricePerSeat,
    required this.acceptsPets,
    required this.acceptsSmokers,
  });
  final String driverName;
  final double rating;
  final String origin;
  final String destination;
  final int stops;
  final String date;
  final String time;
  final int totalSeats;
  final int availableSeats;
  final int pricePerSeat;
  final bool acceptsPets;
  final bool acceptsSmokers;
}

const _mockTrips = [
  _Trip(driverName: 'Carlos Rodríguez', rating: 4.8, origin: 'Buenos Aires', destination: 'Córdoba', stops: 2, date: '05/04/2026', time: '08:00', totalSeats: 4, availableSeats: 2, pricePerSeat: 6500, acceptsPets: true, acceptsSmokers: false),
  _Trip(driverName: 'Ana López', rating: 4.9, origin: 'Rosario', destination: 'Buenos Aires', stops: 0, date: '06/04/2026', time: '14:30', totalSeats: 3, availableSeats: 2, pricePerSeat: 4000, acceptsPets: false, acceptsSmokers: false),
  _Trip(driverName: 'Diego Fernández', rating: 4.7, origin: 'Mendoza', destination: 'San Luis', stops: 1, date: '08/04/2026', time: '10:00', totalSeats: 5, availableSeats: 3, pricePerSeat: 5500, acceptsPets: true, acceptsSmokers: true),
];

class SearchTripsScreen extends StatefulWidget {
  const SearchTripsScreen({super.key});

  @override
  State<SearchTripsScreen> createState() => _SearchTripsScreenState();
}

class _SearchTripsScreenState extends State<SearchTripsScreen> {
  double _originRadius = 50;
  double _destinationRadius = 50;
  int _seatsNeeded = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar viajes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/passenger'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Formulario de búsqueda
            Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Origen *',
                      prefixIcon: Icon(Icons.location_on, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadiusSlider(
                    label: 'Radio de búsqueda (origen)',
                    value: _originRadius,
                    onChanged: (v) => setState(() => _originRadius = v),
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Destino (opcional)',
                      prefixIcon: Icon(Icons.location_on, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadiusSlider(
                    label: 'Radio de búsqueda (destino)',
                    value: _destinationRadius,
                    onChanged: (v) => setState(() => _destinationRadius = v),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          inputFormatters: [DayMonthFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'Entre',
                            hintText: 'DD/MM',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          inputFormatters: [DayMonthFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'Hasta',
                            hintText: 'DD/MM',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Lugares que busco', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => setState(() => _seatsNeeded = (_seatsNeeded - 1).clamp(1, 10)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: AppColors.border, width: 2),
                        ),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$_seatsNeeded',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ),
                      OutlinedButton(
                        onPressed: () => setState(() => _seatsNeeded = (_seatsNeeded + 1).clamp(1, 10)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: AppColors.border, width: 2),
                        ),
                        child: const Icon(Icons.add, size: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/passenger/search-results'),
                    child: const Text('Buscar'),
                  ),
                ],
              ),
            ),

            if (false) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Viajes disponibles (${_mockTrips.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: _mockTrips.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) => _TripCard(trip: _mockTrips[i]),
              ),
            ],
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conductor
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Text(_initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.driverName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFACC15)),
                      const SizedBox(width: 2),
                      Text('${trip.rating}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Ruta
          Row(
            children: [
              Text(trip.origin, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
              ),
              Text(trip.destination, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (trip.stops > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
                  child: Text('${trip.stops} parada${trip.stops > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Fecha y hora
          Text('📅 ${trip.date}  🕐 ${trip.time}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),

          // Asientos disponibles (avatares)
          Row(
            children: [
              const Text('Viajeros: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              for (int i = 0; i < (trip.totalSeats - trip.availableSeats); i++)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: CircleAvatar(radius: 14, backgroundColor: AppColors.primary,
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11))),
                ),
              for (int i = 0; i < trip.availableSeats; i++)
                const Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: CircleAvatar(radius: 14, backgroundColor: Color(0xFFE5E7EB)),
                ),
              const SizedBox(width: 6),
              Text('${trip.availableSeats}/${trip.totalSeats} disponibles',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),

          // Precio
          Text(
            '\$${trip.pricePerSeat.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),

          // Badges
          if (trip.acceptsPets || trip.acceptsSmokers) ...[
            const SizedBox(height: 8),
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
          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ver detalles del viaje con ${trip.driverName}')),
            ),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            child: const Text('Ver detalles'),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
