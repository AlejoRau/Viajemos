import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

enum _SortOption { fecha, precioAsc, precioDesc, asientos }

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
  _Trip(driverName: 'Carlos Rodríguez', rating: 4.8, origin: 'Buenos Aires', destination: 'Córdoba', stops: 2, date: '05/04', time: '08:00', totalSeats: 4, availableSeats: 2, pricePerSeat: 6500, acceptsPets: true, acceptsSmokers: false),
  _Trip(driverName: 'Ana López', rating: 4.9, origin: 'Rosario', destination: 'Buenos Aires', stops: 0, date: '06/04', time: '14:30', totalSeats: 3, availableSeats: 2, pricePerSeat: 4000, acceptsPets: false, acceptsSmokers: false),
  _Trip(driverName: 'Diego Fernández', rating: 4.7, origin: 'Mendoza', destination: 'San Luis', stops: 1, date: '08/04', time: '10:00', totalSeats: 5, availableSeats: 3, pricePerSeat: 5500, acceptsPets: true, acceptsSmokers: true),
  _Trip(driverName: 'Laura Gómez', rating: 4.6, origin: 'Buenos Aires', destination: 'Mar del Plata', stops: 0, date: '05/04', time: '06:00', totalSeats: 3, availableSeats: 1, pricePerSeat: 3500, acceptsPets: false, acceptsSmokers: false),
];

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  _SortOption _sort = _SortOption.fecha;

  List<_Trip> get _sorted {
    final list = List<_Trip>.from(_mockTrips);
    switch (_sort) {
      case _SortOption.fecha:
        list.sort((a, b) => a.date.compareTo(b.date));
      case _SortOption.precioAsc:
        list.sort((a, b) => a.pricePerSeat.compareTo(b.pricePerSeat));
      case _SortOption.precioDesc:
        list.sort((a, b) => b.pricePerSeat.compareTo(a.pricePerSeat));
      case _SortOption.asientos:
        list.sort((a, b) => b.availableSeats.compareTo(a.availableSeats));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_sorted.length} viajes encontrados'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
          children: [
            // Filtros
            Container(
            color: AppColors.pageBackground,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ordenar por',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Fecha',
                        icon: Icons.calendar_today_rounded,
                        selected: _sort == _SortOption.fecha,
                        onTap: () => setState(() => _sort = _SortOption.fecha),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Precio ↑',
                        icon: Icons.attach_money_rounded,
                        selected: _sort == _SortOption.precioAsc,
                        onTap: () => setState(() => _sort = _SortOption.precioAsc),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Precio ↓',
                        icon: Icons.money_off_rounded,
                        selected: _sort == _SortOption.precioDesc,
                        onTap: () => setState(() => _sort = _SortOption.precioDesc),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Más asientos',
                        icon: Icons.event_seat_rounded,
                        selected: _sort == _SortOption.asientos,
                        onTap: () => setState(() => _sort = _SortOption.asientos),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Resultados
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _TripCard(trip: _sorted[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
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

          // Fecha, hora y asientos
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${trip.date}  •  ${trip.time}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              const Icon(Icons.event_seat_rounded, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${trip.availableSeats}/${trip.totalSeats} libres',
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
