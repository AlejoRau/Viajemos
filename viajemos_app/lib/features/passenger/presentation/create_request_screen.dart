import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/formatters/date_formatter.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';
import '../data/passenger_request_repository.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _timeFromController = TextEditingController();
  final _timeToController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _hasPet = false;
  int _seats = 1;
  int _price = 4500;
  bool _publishing = false;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _timeFromController.dispose();
    _timeToController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_originController.text.trim().isEmpty) return 'Ingresá el origen';
    if (_destinationController.text.trim().isEmpty) return 'Ingresá el destino';
    if (_dateFrom == null) return 'Seleccioná la fecha de inicio';
    if (_dateTo == null) return 'Seleccioná la fecha de fin';
    if (_dateTo!.isBefore(_dateFrom!)) return 'La fecha de fin debe ser igual o posterior al inicio';
    final tf = _timeFromController.text.trim();
    final tt = _timeToController.text.trim();
    if (tf.isNotEmpty && tt.isNotEmpty) {
      final parts1 = tf.split(':');
      final parts2 = tt.split(':');
      if (parts1.length == 2 && parts2.length == 2) {
        final from = int.tryParse(parts1[0]) ?? 0;
        final to = int.tryParse(parts2[0]) ?? 0;
        final fromMin = int.tryParse(parts1[1]) ?? 0;
        final toMin = int.tryParse(parts2[1]) ?? 0;
        if (from * 60 + fromMin >= to * 60 + toMin) {
          return 'La hora de fin debe ser mayor a la de inicio';
        }
      }
    }
    return null;
  }

  Future<void> _publish() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade600),
      );
      return;
    }

    setState(() => _publishing = true);
    try {
      await PassengerRequestRepository().publishRequest(
        originAddress: _originController.text.trim(),
        destinationAddress: _destinationController.text.trim(),
        dateFrom: _dateFrom!,
        dateTo: _dateTo!,
        seatsNeeded: _seats,
        hasPet: _hasPet,
        isSmoker: false,
        maxPrice: _price,
        departureTime: _timeFromController.text.trim().isEmpty
            ? null
            : _timeFromController.text.trim(),
        departureTimeTo: _timeToController.text.trim().isEmpty
            ? null
            : _timeToController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pedido publicado con éxito!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        context.go('/passenger');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al publicar: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
  }) {
    return CityAutocompleteField(
      controller: controller,
      hint: placeholder,
      icon: icon,
    );
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

            const SizedBox(height: 32),

            // ── FECHA Y HORA ───────────────────────────────────────────────
            const _SectionHeader(icon: Icons.calendar_today_rounded, title: 'Fecha y hora'),
            const SizedBox(height: 16),
            const _SubLabel('FECHA DE VIAJE'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DatePickerInput(
                    label: 'Desde',
                    value: _dateFrom,
                    onPicked: (d) => setState(() {
                      _dateFrom = d;
                      if (_dateTo != null && _dateTo!.isBefore(d)) _dateTo = d;
                    }),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 14, left: 8, right: 8),
                  child: Text('y', style: TextStyle(color: Color(0xFF64748B))),
                ),
                Expanded(
                  child: _DatePickerInput(
                    label: 'Hasta',
                    value: _dateTo,
                    onPicked: (d) => setState(() => _dateTo = d),
                    firstDate: _dateFrom,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SubLabel('VENTANA HORARIA'),
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
            _SeatsAndPriceCard(
              seats: _seats,
              price: _price,
              onSeatsChanged: (v) => setState(() => _seats = v),
              onPriceChanged: (v) => setState(() => _price = v),
            ),

            const SizedBox(height: 32),

            // ── PREFERENCIAS ──────────────────────────────────────────────
            const _SectionHeader(icon: Icons.tune_rounded, title: 'Mis preferencias'),
            const SizedBox(height: 12),
            _PreferenceToggle(
              icon: Icons.pets_rounded,
              title: 'Tengo mascota',
              value: _hasPet,
              onChanged: (v) => setState(() => _hasPet = v),
            ),

            const SizedBox(height: 32),

            // ── DESCRIPCIÓN ───────────────────────────────────────────────
            const _SubLabel('DESCRIPCIÓN (OPCIONAL)'),
            const SizedBox(height: 8),
            _DescriptionField(controller: _descriptionController),

            const SizedBox(height: 40),

            // ── BOTÓN PUBLICAR ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _publishing ? null : _publish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: _publishing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Publicar pedido',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
  const _SeatsAndPriceCard({
    required this.seats,
    required this.price,
    required this.onSeatsChanged,
    required this.onPriceChanged,
  });

  final int seats;
  final int price;
  final ValueChanged<int> onSeatsChanged;
  final ValueChanged<int> onPriceChanged;

  @override
  State<_SeatsAndPriceCard> createState() => _SeatsAndPriceCardState();
}

class _SeatsAndPriceCardState extends State<_SeatsAndPriceCard> {
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: '${widget.price}');
  }

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
                    'Asientos necesarios',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    'Cantidad de lugares que necesitás',
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
                      onPressed: () {
                        if (widget.seats > 1) widget.onSeatsChanged(widget.seats - 1);
                      },
                      icon: const Icon(Icons.remove, color: AppColors.primary),
                    ),
                    Text(
                      '${widget.seats}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      onPressed: () {
                        if (widget.seats < 5) widget.onSeatsChanged(widget.seats + 1);
                      },
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
                    'Precio que buscas pagar por asiento',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    r'Lo que estás dispuesto a pagar',
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
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null) widget.onPriceChanged(parsed);
                  },
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

class _DatePickerInput extends StatelessWidget {
  const _DatePickerInput({
    required this.label,
    required this.value,
    required this.onPicked,
    this.firstDate,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  final DateTime? firstDate;

  @override
  Widget build(BuildContext context) {
    final displayText = value == null
        ? null
        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final initial = value ?? DateTime.now();
            final earliest = firstDate ?? DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initial.isBefore(earliest) ? earliest : initial,
              firstDate: earliest,
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) onPicked(picked);
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText ?? 'DD/MM',
                    style: TextStyle(
                      color: value == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF64748B), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
