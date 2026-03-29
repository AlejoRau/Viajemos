import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../shared/formatters/date_formatter.dart';

// Allows letters, spaces, and common punctuation for place names
final _placeInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s,.\-]'),
);

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _seats = 1;
  bool _flexible = false;
  bool _hasPet = false;
  bool _isSmoker = false;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar pedido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/passenger'),
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
                  const SectionTitle('Ruta deseada'),
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

                  const SizedBox(height: 24),
                  // Fecha y hora
                  const SectionTitle('Fecha y horario'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [DayMonthFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'Fecha preferida',
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
                            labelText: 'Hora aprox.',
                            hintText: 'HH:MM',
                            prefixIcon: Icon(Icons.access_time_rounded, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Soy flexible con el horario',
                          style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                      Switch.adaptive(
                        value: _flexible,
                        onChanged: (v) => setState(() => _flexible = v),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // Asientos
                  const SectionTitle('Asientos'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Asientos necesarios',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => setState(() => _seats = (_seats - 1).clamp(1, 10)),
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
                        child: Text('$_seats',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ),
                      OutlinedButton(
                        onPressed: () => setState(() => _seats = (_seats + 1).clamp(1, 10)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: AppColors.border, width: 2),
                        ),
                        child: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  // Preferencias
                  const SectionTitle('Mis preferencias'),
                  const SizedBox(height: 8),
                  _PrefRow(label: 'Viajo con mascota', value: _hasPet, onChanged: (v) => setState(() => _hasPet = v)),
                  _PrefRow(label: 'Soy fumador', value: _isSmoker, onChanged: (v) => setState(() => _isSmoker = v)),

                  const SizedBox(height: 24),
                  // Descripción
                  const SectionTitle('Descripción (opcional)'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: const InputDecoration(hintText: 'Ej: Necesito llegar antes de las 18hs'),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

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
                    const SnackBar(content: Text('¡Pedido publicado con éxito!')),
                  );
                  context.go('/passenger');
                },
                child: const Text('Publicar pedido'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({required this.label, required this.value, required this.onChanged});
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
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}
