import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class SearchTripsScreen extends StatelessWidget {
  const SearchTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: const Color(0xFF1E293B),
          onPressed: () => context.go('/passenger'),
        ),
        title: const Text(
          'Buscar Viaje',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FilterCard(),
            const SizedBox(height: 32),
            const Text(
              'RECIENTES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentSearch('Palermo', 'La Plata'),
            _buildRecentSearch('Rosario', 'San Nicolás'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearch(String from, String to) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 12),
          Text(
            '$from → $to',
            style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}

class _FilterCard extends StatefulWidget {
  const _FilterCard();

  @override
  State<_FilterCard> createState() => _FilterCardState();
}

class _FilterCardState extends State<_FilterCard> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('ORIGEN'),
          _buildTextField('¿Desde dónde salís?', Icons.search, _fromController),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInputLabel('DESTINO'),
              const Text(
                '(Opcional)',
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          _buildTextField('¿A dónde vas?', Icons.location_on, _toController),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildDateInput('DESDE', _fromDateController)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateInput('HASTA', _toDateController)),
            ],
          ),
          const SizedBox(height: 20),
          _buildInputLabel('PRECIO MÁXIMO (ARS)'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ej: 15000',
                prefixIcon: Icon(Icons.attach_money, color: Color(0xFF1A73E8), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.push('/passenger/search-results', extra: {
                'origin': _fromController.text.trim(),
                'destination': _toController.text.trim().isEmpty ? null : _toController.text.trim(),
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Buscar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF1A73E8), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildDateInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [DayMonthFormatter()],
            decoration: const InputDecoration(
              hintText: 'DD/MM',
              suffixIcon: Icon(Icons.calendar_month, color: Color(0xFF64748B), size: 18),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
        ),
      ],
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
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(_initials, style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.bold)),
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
                      Text('${trip.rating}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(trip.origin, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 16, color: Color(0xFF1A73E8)),
              ),
              Text(trip.destination, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (trip.stops > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(20)),
                  child: Text('${trip.stops} parada${trip.stops > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1A73E8), fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text('📅 ${trip.date}  🕐 ${trip.time}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Viajeros: ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              for (int i = 0; i < (trip.totalSeats - trip.availableSeats); i++)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: CircleAvatar(radius: 14, backgroundColor: const Color(0xFF1A73E8),
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11))),
                ),
              for (int i = 0; i < trip.availableSeats; i++)
                const Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: CircleAvatar(radius: 14, backgroundColor: Color(0xFFE5E7EB)),
                ),
              const SizedBox(width: 6),
              Text('${trip.availableSeats}/${trip.totalSeats} disponibles',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${trip.pricePerSeat.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8)),
          ),
          if (trip.acceptsPets || trip.acceptsSmokers) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (trip.acceptsPets)
                  _Badge(label: 'Mascotas', icon: Icons.pets_rounded, bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A)),
                if (trip.acceptsPets && trip.acceptsSmokers) const SizedBox(width: 8),
                if (trip.acceptsSmokers)
                  _Badge(label: 'Fumadores', icon: Icons.smoking_rooms_rounded, bg: const Color(0xFFFFF7ED), fg: const Color(0xFFEA580C)),
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
