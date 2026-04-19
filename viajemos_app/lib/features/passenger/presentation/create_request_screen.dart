import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/formatters/date_formatter.dart';
import '../../../shared/services/city_search_service.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/providers/request_success_provider.dart';
import '../../../shared/providers/dirty_form_provider.dart';
import '../data/passenger_request_repository.dart';
import '../../history/data/history_repository.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({
    super.key,
    this.prefillOrigin,
    this.prefillDestination,
    this.prefillDateFrom,
    this.prefillDateTo,
  });

  final String? prefillOrigin;
  final String? prefillDestination;
  final DateTime? prefillDateFrom;
  final DateTime? prefillDateTo;

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
  bool _showErrors = false;

  // Last city name confirmed via autocomplete selection (null = not validated)
  String? _lastValidatedOrigin;
  String? _lastValidatedDest;

  @override
  void initState() {
    super.initState();
    _originController.addListener(_onOriginChanged);
    _destinationController.addListener(_onDestChanged);
    // Pre-fill from search if coming from empty results
    if (widget.prefillOrigin != null && widget.prefillOrigin!.isNotEmpty) {
      _originController.text = widget.prefillOrigin!;
      _lastValidatedOrigin = widget.prefillOrigin;
    }
    if (widget.prefillDestination != null && widget.prefillDestination!.isNotEmpty) {
      _destinationController.text = widget.prefillDestination!;
      _lastValidatedDest = widget.prefillDestination;
    }
    if (widget.prefillDateFrom != null) _dateFrom = widget.prefillDateFrom;
    if (widget.prefillDateTo != null) _dateTo = widget.prefillDateTo;
  }

  bool get _originValidated =>
      _lastValidatedOrigin != null &&
      _lastValidatedOrigin!.toLowerCase() ==
          _originController.text.trim().toLowerCase();

  bool get _destValidated =>
      _lastValidatedDest != null &&
      _lastValidatedDest!.toLowerCase() ==
          _destinationController.text.trim().toLowerCase();

  bool get _hasRequiredErrors =>
      _originController.text.trim().isEmpty ||
      _destinationController.text.trim().isEmpty ||
      _dateFrom == null;

  bool get _hasAnyData =>
      _originController.text.trim().isNotEmpty ||
      _destinationController.text.trim().isNotEmpty ||
      _dateFrom != null;

  void _markDirty() {
    if (!ref.read(dirtyFormProvider)) {
      ref.read(dirtyFormProvider.notifier).state = true;
    }
  }

  void _clearDirty() => ref.read(dirtyFormProvider.notifier).state = false;

  void _onOriginChanged() {
    _markDirty();
    if (_lastValidatedOrigin != null &&
        _lastValidatedOrigin!.toLowerCase() !=
            _originController.text.trim().toLowerCase()) {
      _lastValidatedOrigin = null;
    }
    if (_showErrors) setState(() {});
  }

  void _onDestChanged() {
    _markDirty();
    if (_lastValidatedDest != null &&
        _lastValidatedDest!.toLowerCase() !=
            _destinationController.text.trim().toLowerCase()) {
      _lastValidatedDest = null;
    }
    if (_showErrors) setState(() {});
  }

  void _applyFromAlert(Map<String, dynamic> raw) {
    final origin = raw['origin_address'] as String? ?? '';
    final dest = raw['destination_address'] as String? ?? '';
    setState(() {
      _originController.text = origin;
      _destinationController.text = dest;
      _lastValidatedOrigin = origin.isNotEmpty ? origin : null;
      _lastValidatedDest = dest.isNotEmpty ? dest : null;
    });
  }

  Future<void> _openHistoryPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlertHistoryPickerSheet(
        onSelect: (raw) {
          Navigator.pop(context);
          _applyFromAlert(raw);
        },
      ),
    );
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasAnyData) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Salir sin guardar?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text(
          'Si salís ahora, los cambios que hiciste se van a perder.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Descartar cambios'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _clearDirty();
    _originController.removeListener(_onOriginChanged);
    _destinationController.removeListener(_onDestChanged);
    _originController.dispose();
    _destinationController.dispose();
    _timeFromController.dispose();
    _timeToController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_hasRequiredErrors) return 'required';
    if (!_originValidated) return 'Seleccioná el origen de la lista de ciudades';
    if (!_destValidated) return 'Seleccioná el destino de la lista de ciudades';
    if (_originController.text.trim().toLowerCase() ==
        _destinationController.text.trim().toLowerCase()) {
      return 'El origen y el destino no pueden ser iguales';
    }
    if (_dateTo != null && _dateTo!.isBefore(_dateFrom!)) return 'La fecha de fin debe ser igual o posterior al inicio';
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
      setState(() => _showErrors = true);
      if (error != 'required') AppToast.show(context, message: error);
      return;
    }

    setState(() => _publishing = true);
    try {
      await PassengerRequestRepository().publishRequest(
        originAddress: _originController.text.trim(),
        destinationAddress: _destinationController.text.trim(),
        dateFrom: _dateFrom!,
        dateTo: _dateTo,
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
        final RequestSuccess success = (
          originCity: _originController.text.trim(),
          destinationCity: _destinationController.text.trim(),
          dateFrom: _dateFrom!,
          dateTo: _dateTo,
          timeFrom: _timeFromController.text.trim(),
          timeTo: _timeToController.text.trim(),
          seats: _seats,
          maxPrice: _price,
          hasPet: _hasPet,
        );
        ref.read(requestSuccessProvider.notifier).state = success;
        _clearDirty();
        context.go('/passenger');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Error al publicar: $e');
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required ValueChanged<String> onSelected,
  }) {
    return CityAutocompleteField(
      controller: controller,
      hint: placeholder,
      icon: icon,
      defaultSuggestions: popularArgentineCities,
      citySearchSource: CitySearchSource.georef,
      onSelected: onSelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && mounted) { _clearDirty(); context.go('/passenger'); }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Publicar pedido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (await _confirmDiscard() && mounted) { _clearDirty(); context.go('/passenger'); }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Usar pedido anterior',
            icon: const Icon(Icons.history_rounded),
            onPressed: _openHistoryPicker,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── RUTA ──────────────────────────────────────────────────────
            const _SectionHeader(icon: Icons.alt_route_rounded, title: 'Ruta'),
            const SizedBox(height: 20),
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
                          onSelected: (name) =>
                              setState(() => _lastValidatedOrigin = name),
                        ),
                        if (_showErrors && _originController.text.trim().isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, left: 4),
                            child: Text('Este campo es obligatorio',
                                style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          )
                        else if (_showErrors && !_originValidated)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, left: 4),
                            child: Text('Seleccioná una ciudad de la lista',
                                style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          ),
                        const SizedBox(height: 12),
                        _buildLocationInput(
                          controller: _destinationController,
                          placeholder: 'Destino',
                          icon: Icons.near_me_rounded,
                          onSelected: (name) =>
                              setState(() => _lastValidatedDest = name),
                        ),
                        if (_showErrors && _destinationController.text.trim().isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, left: 4),
                            child: Text('Este campo es obligatorio',
                                style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          )
                        else if (_showErrors && !_destValidated)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, left: 4),
                            child: Text('Seleccioná una ciudad de la lista',
                                style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(height: 1, thickness: 2.5, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 40),

            // ── FECHA Y HORA ───────────────────────────────────────────────
            const _SectionHeader(icon: Icons.calendar_today_rounded, title: 'Fecha y hora'),
            const SizedBox(height: 8),
            const Text(
              'Indicá en qué período querés salir. No es ida y vuelta.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            const _SubLabel('RANGO DE SALIDA'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DatePickerInput(
                        label: 'No antes del',
                        value: _dateFrom,
                        onPicked: (d) { _markDirty(); setState(() {
                          _dateFrom = d;
                          if (_dateTo != null && _dateTo!.isBefore(d)) _dateTo = d;
                        }); },
                      ),
                      if (_showErrors && _dateFrom == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 4, left: 4),
                          child: Text('Este campo es obligatorio',
                              style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 14, left: 8, right: 8),
                  child: Text('y', style: TextStyle(color: Color(0xFF64748B))),
                ),
                Expanded(
                  child: _DatePickerInput(
                    label: 'No después del (opc.)',
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
            const Divider(height: 1, thickness: 2.5, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 40),

            // ── ASIENTOS Y PRECIO ─────────────────────────────────────────
            const _SectionHeader(icon: Icons.payments_outlined, title: 'Asientos y precio'),
            const SizedBox(height: 20),
            _SeatsAndPriceCard(
              seats: _seats,
              price: _price,
              onSeatsChanged: (v) => setState(() => _seats = v),
              onPriceChanged: (v) => setState(() => _price = v),
            ),

            const SizedBox(height: 32),
            const Divider(height: 1, thickness: 2.5, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 40),

            // ── PREFERENCIAS ──────────────────────────────────────────────
            const _SectionHeader(icon: Icons.tune_rounded, title: 'Mis preferencias'),
            const SizedBox(height: 16),
            _PreferenceToggle(
              icon: Icons.pets_rounded,
              title: 'Tengo mascota',
              value: _hasPet,
              onChanged: (v) => setState(() => _hasPet = v),
            ),

            const SizedBox(height: 32),
            const Divider(height: 1, thickness: 2.5, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 40),

            // ── DESCRIPCIÓN ───────────────────────────────────────────────
            const _SubLabel('DESCRIPCIÓN (OPCIONAL)'),
            const SizedBox(height: 10),
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
    ));
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
              const Expanded(
                child: Column(
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
              ),
              const SizedBox(width: 12),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio máximo por asiento',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      r'Lo que estás dispuesto a pagar',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                    prefixText: 'ARS ',
                    prefixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

// ── Alert History Picker Sheet ─────────────────────────────────────────────

class _AlertHistoryPickerSheet extends StatefulWidget {
  const _AlertHistoryPickerSheet({required this.onSelect});
  final void Function(Map<String, dynamic> raw) onSelect;

  @override
  State<_AlertHistoryPickerSheet> createState() => _AlertHistoryPickerSheetState();
}

class _AlertHistoryPickerSheetState extends State<_AlertHistoryPickerSheet> {
  List<Map<String, dynamic>>? _alerts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final alerts = await HistoryRepository().fetchPassengerAlertSummaries();
      if (mounted) setState(() { _alerts = alerts; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _alerts = []; _loading = false; });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Mis pedidos',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              const Text('Tocá uno para copiar sus datos',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_alerts == null || _alerts!.isEmpty)
                    ? const Center(
                        child: Text('No tenés pedidos creados',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.textSecondary)))
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _alerts!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final t = _alerts![i];
                          final origin = t['origin_address'] as String? ?? '';
                          final destination = t['destination_address'] as String? ?? '';
                          final dateFrom = _formatDate(t['date_from'] as String?);
                          final dateTo = t['date_to'] != null
                              ? _formatDate(t['date_to'] as String?)
                              : null;
                          final isActive = t['is_active'] as bool? ?? false;
                          return InkWell(
                            onTap: () => widget.onSelect(t),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                border: Border.all(
                                    color: isActive
                                        ? AppColors.primary.withOpacity(0.35)
                                        : AppColors.border,
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                    Row(children: [
                                      Expanded(
                                        child: Text(
                                          '$origin  →  $destination',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isActive) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('Activo',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary)),
                                        ),
                                      ],
                                    ]),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.calendar_today_rounded,
                                          size: 12, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        dateTo != null
                                            ? '$dateFrom – $dateTo'
                                            : dateFrom,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary),
                                      ),
                                    ]),
                                  ]),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.content_copy_rounded,
                                    size: 18, color: AppColors.primary),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
              lastDate: DateTime(
                DateTime.now().year,
                DateTime.now().month + 1,
                DateTime.now().day,
              ),
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
