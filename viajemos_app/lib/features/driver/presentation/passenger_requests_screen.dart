import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/radius_slider.dart';

class _PassengerRequest {
  const _PassengerRequest({
    required this.name,
    required this.origin,
    required this.destination,
    required this.date,
    required this.seats,
    required this.hasPet,
    required this.isSmoker,
    this.price,
  });
  final String name;
  final String origin;
  final String destination;
  final String date;
  final int seats;
  final bool hasPet;
  final bool isSmoker;
  final double? price;
}

const _mockRequests = [
  _PassengerRequest(name: 'María González', origin: 'Rosario', destination: 'Buenos Aires', date: '05/04/2026', seats: 2, hasPet: true, isSmoker: false, price: 5500),
  _PassengerRequest(name: 'Juan Pérez', origin: 'Mendoza', destination: 'San Juan', date: '10/04/2026', seats: 1, hasPet: false, isSmoker: false),
  _PassengerRequest(name: 'Sofía Martínez', origin: 'Córdoba', destination: 'Buenos Aires', date: '08/04/2026', seats: 3, hasPet: false, isSmoker: true, price: 4200),
];

class PassengerRequestsScreen extends StatefulWidget {
  const PassengerRequestsScreen({super.key});

  @override
  State<PassengerRequestsScreen> createState() => _PassengerRequestsScreenState();
}

class _PassengerRequestsScreenState extends State<PassengerRequestsScreen> {
  double _radiusOri = 100;
  double _radiusDest = 100;
  DateTime? _filterDate;
  final String _originActive = 'Tandil';
  final String _destActive = '-';

  final List<DateTime> _nextDays = List.generate(
    14,
    (index) => DateTime.now().add(Duration(days: index)),
  );

  String _formatDateShort(DateTime date) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dayName = days[date.weekday - 1];
    return '$dayName ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  void _showOfferSheet(_PassengerRequest request) {
    final priceController = TextEditingController(text: request.price?.toInt().toString() ?? '');
    final cityController = TextEditingController(text: request.destination);
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Ofrecer viaje a ${request.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tu precio ofrecido (\$)',
                hintText: 'Ej: 5000',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'Ciudad de destino',
                prefixIcon: Icon(Icons.location_on_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mensaje para el pasajero',
                hintText: 'Escribe algo para convencer al pasajero...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Oferta enviada a ${request.name}')),
                );
              },
              child: const Text('Confirmar oferta'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos de pasajeros'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver'),
        ),
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.pageBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📍 Saliendo desde',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          Text(_originActive,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('🏁 Hacia',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          Text(_destActive,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _destActive == '-' ? AppColors.textSecondary : AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RadiusSlider(
                  label: 'Rango máximo salida',
                  value: _radiusOri,
                  onChanged: (v) => setState(() => _radiusOri = v),
                ),
                const SizedBox(height: 8),
                RadiusSlider(
                  label: 'Rango máximo destino',
                  value: _radiusDest,
                  onChanged: (v) => setState(() => _radiusDest = v),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    border: Border.all(color: AppColors.border, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DateTime>(
                      value: _filterDate,
                      alignment: AlignmentDirectional.centerStart,
                      hint: const Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Filtrar por fecha', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                      items: [
                        DropdownMenuItem<DateTime>(
                          value: null,
                          child: Text('Todas las fechas',
                              style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7), fontSize: 14)),
                        ),
                        ..._nextDays.map((date) => DropdownMenuItem(
                              value: date,
                              child: Text(_formatDateShort(date),
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                            )),
                      ],
                      onChanged: (v) => setState(() => _filterDate = v),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _mockRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, i) => _RequestCard(
                request: _mockRequests[i],
                destFilter: _destActive,
                onOffer: () => _showOfferSheet(_mockRequests[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onOffer, required this.destFilter});
  final _PassengerRequest request;
  final String destFilter;
  final VoidCallback onOffer;

  String _getDist(String city) {
    // Mock de distancias desde Tandil o entre ciudades
    final dists = {
      'Rosario': 450,
      'Buenos Aires': 350,
      'Ayacucho': 72,
      'Rauch': 70,
      'Mendoza': 1100,
      'San Juan': 1200,
      'Córdoba': 800,
    };
    return '${dists[city] ?? 100} kms';
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
          // Header: Nombre y Precio
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(request.name[0],
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Text(request.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: request.price != null ? AppColors.greenLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  request.price != null ? '\$${request.price!.toInt()}' : 'A convenir',
                  style: TextStyle(
                    color: request.price != null ? AppColors.green : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ruta
          Row(
            children: [
              Text('${request.origin} (${_getDist(request.origin)})', style: const TextStyle(fontWeight: FontWeight.w500)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
              ),
              Text(
                destFilter == '-'
                    ? request.destination
                    : '${request.destination} (${_getDist(request.destination)})',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Fecha y asientos
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(request.date, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              const Icon(Icons.people_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${request.seats} asiento${request.seats > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),

          // Badges
          if (request.hasPet || request.isSmoker) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (request.hasPet)
                  _Badge(label: 'Mascota', icon: Icons.pets_rounded, bg: AppColors.greenLight, fg: AppColors.green),
                if (request.hasPet && request.isSmoker) const SizedBox(width: 8),
                if (request.isSmoker)
                  _Badge(label: 'Fumador', icon: Icons.smoking_rooms_rounded, bg: AppColors.orangeLight, fg: AppColors.orange),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Botón
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOffer,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
              child: const Text('Ofrecer viaje'),
            ),
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
