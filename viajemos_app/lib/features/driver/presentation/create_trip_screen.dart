import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/widgets/suggestion_chip_input.dart';
import '../../../shared/formatters/date_formatter.dart';

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
  final _timeController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _seats = 1;
  bool _acceptsPets = false;
  bool _acceptsSmokers = false;
  bool _priceAcordado = false;
  final List<String> _routes = [];
  final List<String> _stops = [];

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear un viaje'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ruta
                  const SectionTitle('Ruta'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _originController,
                    inputFormatters: [_placeInputFormatter],
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Origen',
                      prefixIcon: Icon(Icons.location_on, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _destinationController,
                    inputFormatters: [_placeInputFormatter],
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Destino',
                      prefixIcon: Icon(Icons.location_on, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SuggestionChipInput(
                    label: 'Rutas que va a usar',
                    hint: 'Ej: Ruta Nacional 9...',
                    suggestions: _routeSuggestions,
                    chips: _routes,
                    onAdd: (v) => setState(() => _routes.add(v)),
                    onRemove: (i) => setState(() => _routes.removeAt(i)),
                    prefixIcon: Icons.route_rounded,
                  ),
                  const SizedBox(height: 12),
                  SuggestionChipInput(
                    label: 'Paradas intermedias',
                    hint: 'Ej: Las Flores...',
                    suggestions: _citySuggestions,
                    chips: _stops,
                    onAdd: (v) => setState(() => _stops.add(v)),
                    onRemove: (i) => setState(() => _stops.removeAt(i)),
                    prefixIcon: Icons.location_on_outlined,
                  ),

                  const SizedBox(height: 24),
                  // Fecha y hora
                  const SectionTitle('Fecha y hora'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [DayMonthFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'Fecha de salida',
                            hintText: 'DD/MM',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _timeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [TimeFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'Hora de salida',
                            hintText: 'HH:MM',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // Asientos y precio
                  const SectionTitle('Asientos y precio'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Asientos disponibles', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const Spacer(),
                      _Counter(
                        value: _seats,
                        onDecrement: () => setState(() => _seats = (_seats - 1).clamp(1, 10)),
                        onIncrement: () => setState(() => _seats = (_seats + 1).clamp(1, 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: _priceAcordado,
                        onChanged: (v) => setState(() {
                          _priceAcordado = v ?? false;
                          if (_priceAcordado) _priceController.clear();
                        }),
                        activeColor: AppColors.primary,
                      ),
                      const Text(
                        'Precio a acordar entre los participantes',
                        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if (!_priceAcordado) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Precio por asiento (ARS)',
                        prefixText: r'$ ',
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  // Preferencias
                  const SectionTitle('Preferencias del conductor'),
                  const SizedBox(height: 8),
                  _PreferenceRow(
                    label: 'Acepta mascotas',
                    value: _acceptsPets,
                    onChanged: (v) => setState(() => _acceptsPets = v),
                  ),
                  _PreferenceRow(
                    label: 'Acepta fumadores',
                    value: _acceptsSmokers,
                    onChanged: (v) => setState(() => _acceptsSmokers = v),
                  ),

                  const SizedBox(height: 24),
                  // Descripción
                  const SectionTitle('Descripción'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Información adicional sobre el viaje...',
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Botón fijo
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Viaje publicado con éxito!')),
                  );
                  context.go('/driver');
                },
                child: const Text('Publicar viaje'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  fontSize: 14,
                  color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.value, required this.onDecrement, required this.onIncrement});

  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: onDecrement,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: AppColors.border, width: 2),
          ),
          child: const Icon(Icons.remove, size: 18),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$value',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        OutlinedButton(
          onPressed: onIncrement,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: AppColors.border, width: 2),
          ),
          child: const Icon(Icons.add, size: 18),
        ),
      ],
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
