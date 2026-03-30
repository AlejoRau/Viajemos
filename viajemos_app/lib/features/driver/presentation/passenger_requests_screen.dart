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
  });
  final String name;
  final String origin;
  final String destination;
  final String date;
  final int seats;
  final bool hasPet;
  final bool isSmoker;
}

const _mockRequests = [
  _PassengerRequest(name: 'María González', origin: 'Rosario', destination: 'Buenos Aires', date: '05/04/2026', seats: 2, hasPet: true, isSmoker: false),
  _PassengerRequest(name: 'Juan Pérez', origin: 'Mendoza', destination: 'San Juan', date: '10/04/2026', seats: 1, hasPet: false, isSmoker: false),
  _PassengerRequest(name: 'Sofía Martínez', origin: 'Córdoba', destination: 'Buenos Aires', date: '08/04/2026', seats: 3, hasPet: false, isSmoker: true),
];

class PassengerRequestsScreen extends StatefulWidget {
  const PassengerRequestsScreen({super.key});

  @override
  State<PassengerRequestsScreen> createState() => _PassengerRequestsScreenState();
}

class _PassengerRequestsScreenState extends State<PassengerRequestsScreen> {
  double _radius = 100;
  DateTime? _filterDate;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _filterDate = date);
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
                RadiusSlider(
                  label: 'Radio de búsqueda',
                  value: _radius,
                  onChanged: (v) => setState(() => _radius = v),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      border: Border.all(color: AppColors.border, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          _filterDate != null
                              ? '${_filterDate!.day}/${_filterDate!.month}/${_filterDate!.year}'
                              : 'Filtrar por fecha',
                          style: TextStyle(
                            color: _filterDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
              itemBuilder: (_, i) => _RequestCard(request: _mockRequests[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final _PassengerRequest request;

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
          // Nombre
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Text(request.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Text(request.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),

          // Ruta
          Row(
            children: [
              Text(request.origin, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
              ),
              Text(request.destination, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),

          // Fecha y asientos
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
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
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ofreciendo viaje a ${request.name}')),
              ),
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
