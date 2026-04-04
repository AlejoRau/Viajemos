import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/suggestion_chip_input.dart';
import '../../../shared/formatters/date_formatter.dart';
import 'trip_map_screen.dart';

final _placeInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s,.\-]'),
);

const _routeSuggestions = [
  'Ruta Nacional 9',
  'Ruta Nacional 3',
  'Ruta Nacional 7',
  'Ruta Nacional 14',
  'Ruta Nacional 40',
  'Ruta Nacional 11',
  'Ruta Nacional 34',
  'Ruta Nacional 8',
  'Autopista del Sol (RN9)',
  'Autopista Rosario–Córdoba',
  'Autopista Buenos Aires–La Plata',
  'Ruta Provincial 2',
  'Ruta Provincial 6',
];

const _citySuggestions = [
  'Rosario',
  'Córdoba',
  'Mendoza',
  'Tucumán',
  'Mar del Plata',
  'Bahía Blanca',
  'Santa Fe',
  'San Luis',
  'La Plata',
  'Neuquén',
  'Salta',
  'Jujuy',
  'Paraná',
  'Posadas',
  'Las Flores',
  'Pergamino',
  'Venado Tuerto',
  'Villa María',
  'San Pedro',
  'Azul',
  'Olavarría',
  'Tandil',
  'Junín',
  'Rafaela',
];

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeFromController = TextEditingController();
  final _timeToController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _acceptsPets = false;
  bool _picksUpPassengers = false;   // Paso a buscar a cada pasajero
  bool _dropsOffPassengers = false;  // Dejo a cada pasajero en su destino
  final List<String> _routes = [];
  final List<String> _stops = [];

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _timeFromController.dispose();
    _timeToController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onNext(BuildContext context) async {
    // If driver picks up AND drops off at door, no maps needed
    if (_picksUpPassengers && _dropsOffPassengers) {
      _publish(context);
      return;
    }

    // Step 1: origin map (only if driver does NOT pick up at door)
    if (!_picksUpPassengers) {
      final origin = await Navigator.push<MapResult>(
        context,
        MaterialPageRoute(
          builder: (_) => const TripMapScreen(title: 'Punto de salida'),
        ),
      );
      if (origin == null) return; // user cancelled
    }

    // Step 2: destination map (only if driver does NOT drop off at door)
    if (!_dropsOffPassengers && context.mounted) {
      final dest = await Navigator.push<MapResult>(
        context,
        MaterialPageRoute(
          builder: (_) => const TripMapScreen(title: 'Punto de llegada'),
        ),
      );
      if (dest == null) return; // user cancelled
    }

    if (context.mounted) _publish(context);
  }

  void _publish(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Viaje publicado con éxito!'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
    context.go('/driver');
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        inputFormatters: [_placeInputFormatter],
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: placeholder,
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear viaje'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── RUTA ──────────────────────────────────────────────────────
            const _SectionHeader(icon: Icons.alt_route_rounded, title: 'Ruta'),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      children: [
                        const Icon(Icons.circle, size: 12, color: Color(0xFF94A3B8)),
                        Expanded(
                          child: Container(width: 2, color: const Color(0xFFE2E8F0)),
                        ),
                        const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildLocationInput(
                          controller: _originController,
                          placeholder: 'Origen',
                          icon: Icons.search,
                        ),
                        const SizedBox(height: 12),
                        _buildLocationInput(
                          controller: _destinationController,
                          placeholder: 'Destino',
                          icon: Icons.near_me_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _SubLabel('PARADAS INTERMEDIAS'),
            const SizedBox(height: 8),
            SuggestionChipInput(
              label: 'Paradas intermedias',
              hint: 'Añadir parada...',
              suggestions: _citySuggestions,
              chips: _stops,
              onAdd: (v) => setState(() => _stops.add(v)),
              onRemove: (i) => setState(() => _stops.removeAt(i)),
              prefixIcon: Icons.add_location_alt_outlined,
            ),

            const SizedBox(height: 32),

            // ── VÍAS / RUTAS ───────────────────────────────────────────────
            const _SectionHeader(icon: Icons.directions_rounded, title: 'Vías / Rutas'),
            const SizedBox(height: 16),
            SuggestionChipInput(
              label: 'Rutas que va a usar',
              hint: 'Añadir vía o número de ruta...',
              suggestions: _routeSuggestions,
              chips: _routes,
              onAdd: (v) => setState(() => _routes.add(v)),
              onRemove: (i) => setState(() => _routes.removeAt(i)),
              prefixIcon: Icons.add_road_rounded,
            ),

            const SizedBox(height: 32),

            // ── FECHA Y HORA ───────────────────────────────────────────────
            const _SectionHeader(icon: Icons.calendar_today_rounded, title: 'Fecha y hora'),
            const SizedBox(height: 16),
            const _SubLabel('FECHA DE SALIDA'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _dateController.text =
                        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}';
                  });
                }
              },
              child: AbsorbPointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      hintText: 'Seleccionar fecha',
                      hintStyle:
                          TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      suffixIcon: Icon(Icons.calendar_month_rounded,
                          color: Color(0xFF64748B), size: 18),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _SubLabel('VENTANA DE SALIDA'),
            const SizedBox(height: 8),
            _RangeInputRow(
              label1: 'Entre las',
              label2: 'Y las',
              controller1: _timeFromController,
              controller2: _timeToController,
              formatter: TimeFormatter(),
              hint1: 'ej: 11:00',
              hint2: 'ej: 13:00',
              icon: Icons.access_time_rounded,
            ),

            const SizedBox(height: 32),

            // ── ASIENTOS Y PRECIO ─────────────────────────────────────────
            const _SectionHeader(icon: Icons.payments_outlined, title: 'Asientos y precio'),
            const SizedBox(height: 16),
            const _SeatsAndPriceCard(),

            const SizedBox(height: 32),

            // ── PREFERENCIAS ──────────────────────────────────────────────
            const _SectionHeader(icon: Icons.tune_rounded, title: 'Preferencias del conductor'),
            const SizedBox(height: 12),
            _PreferenceToggle(
              icon: Icons.pets_rounded,
              title: 'Acepta mascotas',
              value: _acceptsPets,
              onChanged: (v) => setState(() => _acceptsPets = v),
            ),
            const SizedBox(height: 8),
            _PreferenceToggle(
              icon: Icons.house_rounded,
              title: 'Paso a buscar a cada pasajero',
              value: _picksUpPassengers,
              onChanged: (v) => setState(() => _picksUpPassengers = v),
            ),
            const SizedBox(height: 8),
            _PreferenceToggle(
              icon: Icons.door_front_door_rounded,
              title: 'Dejo a cada pasajero en su destino',
              value: _dropsOffPassengers,
              onChanged: (v) => setState(() => _dropsOffPassengers = v),
            ),

            const SizedBox(height: 32),

            // ── DESCRIPCIÓN ───────────────────────────────────────────────
            const _SubLabel('DESCRIPCIÓN (OPCIONAL)'),
            const SizedBox(height: 8),
            _DescriptionField(controller: _descriptionController),

            const SizedBox(height: 40),

            // ── BOTÓN SIGUIENTE ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _onNext(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: Text(
                  _picksUpPassengers && _dropsOffPassengers
                      ? 'Publicar viaje'
                      : 'Siguiente',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── PRIVATE WIDGETS ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _RangeInputRow extends StatelessWidget {
  const _RangeInputRow({
    required this.label1,
    required this.label2,
    required this.controller1,
    required this.controller2,
    required this.formatter,
    required this.icon,
    this.hint1 = 'DD/MM',
    this.hint2 = 'DD/MM',
  });

  final String label1;
  final String label2;
  final TextEditingController controller1;
  final TextEditingController controller2;
  final TextInputFormatter formatter;
  final IconData icon;
  final String hint1;
  final String hint2;

  Widget _buildBox(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [formatter],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildBox(label1, controller1, hint1)),
        const Padding(
          padding: EdgeInsets.only(top: 14, left: 8, right: 8),
          child: Text('y', style: TextStyle(color: Color(0xFF64748B))),
        ),
        Expanded(child: _buildBox(label2, controller2, hint2)),
      ],
    );
  }
}

class _SeatsAndPriceCard extends StatefulWidget {
  const _SeatsAndPriceCard();

  @override
  State<_SeatsAndPriceCard> createState() => _SeatsAndPriceCardState();
}

class _SeatsAndPriceCardState extends State<_SeatsAndPriceCard> {
  int _seats = 3;
  final _priceController = TextEditingController(text: '4500');

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Asientos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asientos disponibles',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    'Excluyéndote a ti',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() { if (_seats > 1) _seats--; }),
                      icon: const Icon(Icons.remove, color: AppColors.primary),
                    ),
                    Text(
                      '$_seats',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _seats++),
                      icon: const Icon(Icons.add, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Precio
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precio por asiento',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    r'Recomendado: $4.500',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: const InputDecoration(
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 12, top: 12),
                      child: Text(
                        'ARS',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

class _PreferenceToggle extends StatelessWidget {
  const _PreferenceToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF1E293B)),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        maxLines: 4,
        maxLength: 300,
        decoration: const InputDecoration(
          hintText: 'Detalles sobre el punto de encuentro, equipaje, etc.',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          counterText: '',
        ),
      ),
    );
  }
}
