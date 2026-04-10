import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/suggestion_chip_input.dart';
import '../../../shared/formatters/date_formatter.dart';
import '../../../features/vehicles/data/vehicles_provider.dart';
import '../../../features/vehicles/domain/vehicle.dart';
import '../../../shared/widgets/vehicle_selector_sheet.dart';
import '../../../shared/services/city_search_service.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';
import '../data/trip_repository.dart';
import 'trip_map_screen.dart';

const _routeSuggestions = [
  // Nacionales principales
  'Ruta Nacional 2',
  'Ruta Nacional 3',
  'Ruta Nacional 7',
  'Ruta Nacional 8',
  'Ruta Nacional 9',
  'Ruta Nacional 11',
  'Ruta Nacional 12',
  'Ruta Nacional 14',
  'Ruta Nacional 19',
  'Ruta Nacional 20',
  'Ruta Nacional 22',
  'Ruta Nacional 33',
  'Ruta Nacional 34',
  'Ruta Nacional 36',
  'Ruta Nacional 38',
  'Ruta Nacional 40',
  'Ruta Nacional 42',
  'Ruta Nacional 51',
  'Ruta Nacional 60',
  'Ruta Nacional 68',
  'Ruta Nacional 74',
  'Ruta Nacional 76',
  'Ruta Nacional 158',
  'Ruta Nacional 188',
  // Autopistas
  'Autopista del Sol (RN9)',
  'Autopista Rosario–Córdoba (RN9)',
  'Autopista Buenos Aires–La Plata (RN1)',
  'Autopista Riccheri (RN1)',
  'Autopista Ezeiza–Cañuelas (RN205)',
  'Autopista Córdoba–Villa Carlos Paz',
  'Autopista Rosario–Santa Fe',
  'Autopista Illia (Bs. As.)',
  // Provinciales frecuentes
  'Ruta Provincial 2 (Buenos Aires)',
  'Ruta Provincial 6 (Buenos Aires)',
  'Ruta Provincial 11 (Santa Fe)',
  'Ruta Provincial 20 (Córdoba)',
  'Ruta Provincial 38 (Córdoba)',
  'Ruta Provincial 45 (Córdoba)',
  'Ruta Provincial 55 (Córdoba)',
  'Ruta Provincial 74 (Buenos Aires)',
];

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _timeFromController = TextEditingController();
  final _timeToController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _acceptsPets = false;
  bool _picksUpPassengers = false;
  bool _dropsOffPassengers = false;
  final List<String> _routes = [];
  final List<String> _stops = [];
  String? _timeError;

  int _seats = 3;
  int _price = 4500;
  bool _splitCosts = false;

  DateTime? _departureDate;
  MapResult? _originResult;
  MapResult? _destResult;

  Vehicle? _selectedVehicle;
  bool _publishing = false;

  // Validation state — set true on first publish attempt to show inline errors
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _timeFromController.addListener(_onTimeChanged);
    _timeFromController.addListener(_onFieldChanged);
    _timeToController.addListener(_onTimeChanged);
    // Rebuild when origin/destination/time change so error hints update live
    _originController.addListener(_onFieldChanged);
    _destinationController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_showErrors) setState(() {});
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _timeFromController.dispose();
    _timeToController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onTimeChanged() {
    final from = _parseMinutes(_timeFromController.text.trim());
    final toText = _timeToController.text.trim();
    final to = toText.isEmpty ? null : _parseMinutes(toText);
    String? error;
    if (from != null && to != null && to <= from) {
      error = 'La hora de fin debe ser mayor que la de inicio';
    }
    if (error != _timeError) setState(() => _timeError = error);
  }

  String get _dateDisplayText {
    if (_departureDate == null) return '';
    final d = _departureDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _openVehicleSelector(List<Vehicle> existing) async {
    // Show bottom sheet with existing vehicles + add option
    final selected = await showModalBottomSheet<Vehicle?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VehiclePickerSheet(
        vehicles: existing,
        onAddNew: () async {
          Navigator.pop(context); // close picker
          final input = await showModalBottomSheet<VehicleInput>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const VehicleSelectorSheet(),
          );
          if (input == null || !mounted) return;
          try {
            final newVehicle = await ref
                .read(vehiclesRepositoryProvider)
                .addVehicle(
                  brand: input.brand,
                  model: input.model,
                  color: input.color,
                  colorHex: input.colorHex,
                );
            ref.invalidate(vehiclesProvider);
            setState(() => _selectedVehicle = newVehicle);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al guardar el vehículo: $e')),
              );
            }
          }
        },
      ),
    );
    if (selected != null) setState(() => _selectedVehicle = selected);
  }

  /// Parses "HH:mm" → minutes from midnight, or null if invalid.
  int? _parseMinutes(String text) {
    final parts = text.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  bool get _hasRequiredErrors {
    if (_originController.text.trim().isEmpty) return true;
    if (_destinationController.text.trim().isEmpty) return true;
    if (_departureDate == null) return true;
    if (_timeFromController.text.trim().isEmpty) return true;
    if (_selectedVehicle == null) return true;
    return false;
  }

  Future<void> _onNext() async {
    // Trigger inline validation display
    if (_hasRequiredErrors) {
      setState(() => _showErrors = true);
      return;
    }

    // Validate time format
    final fromText = _timeFromController.text.trim();
    final toText = _timeToController.text.trim();
    final fromMin = _parseMinutes(fromText);
    if (fromMin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Formato de hora inválido (usá HH:mm)')),
      );
      return;
    }
    if (toText.isNotEmpty) {
      final toMin = _parseMinutes(toText);
      if (toMin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Formato de hora de fin inválido (usá HH:mm)')),
        );
        return;
      }
      if (toMin <= fromMin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'La hora de fin debe ser mayor que la hora de inicio')),
        );
        return;
      }
    }

    // Origin map (only if driver does NOT pick up at door)
    if (!_picksUpPassengers) {
      final origin = await Navigator.push<MapResult>(
        context,
        MaterialPageRoute(
          builder: (_) => TripMapScreen(
            title: 'Punto de salida',
            initialCity: _originController.text.trim().isEmpty
                ? null
                : _originController.text.trim(),
          ),
        ),
      );
      if (origin == null) return;
      _originResult = origin;
    }

    // Destination map (only if driver does NOT drop off at door)
    if (!_dropsOffPassengers && mounted) {
      final dest = await Navigator.push<MapResult>(
        context,
        MaterialPageRoute(
          builder: (_) => TripMapScreen(
            title: 'Punto de llegada',
            initialCity: _destinationController.text.trim().isEmpty
                ? null
                : _destinationController.text.trim(),
          ),
        ),
      );
      if (dest == null) return;
      _destResult = dest;
    }

    if (mounted) await _publish();
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    try {
      final repo = TripRepository();
      await repo.createTrip(
        // City names always used as the trip title (origin/destination)
        originAddress: _originController.text.trim(),
        destinationAddress: _destinationController.text.trim(),
        // Specific street-level addresses from map pin (only when driver set them)
        pickupAddress: _picksUpPassengers ? null : _originResult?.address,
        dropoffAddress: _dropsOffPassengers ? null : _destResult?.address,
        originLat: _originResult?.lat,
        originLng: _originResult?.lng,
        destLat: _destResult?.lat,
        destLng: _destResult?.lng,
        availableSeats: _seats,
        pricePerSeat: _splitCosts ? 0 : _price,
        departureDate: _departureDate!,
        departureTimeFrom: _timeFromController.text.trim(),
        allowsPets: _acceptsPets,
        picksUpAtDoor: _picksUpPassengers,
        dropsOffAtDoor: _dropsOffPassengers,
        via: _routes,
        stops: _stops,
        splitCosts: _splitCosts,
        description: _descriptionController.text.trim(),
        vehicleId: _selectedVehicle?.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Viaje publicado con éxito!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        context.go('/driver');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

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
            const _SectionHeader(
                icon: Icons.alt_route_rounded, title: 'Ruta'),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      children: [
                        const Icon(Icons.circle,
                            size: 12, color: Color(0xFF94A3B8)),
                        Expanded(
                          child: Container(
                              width: 2,
                              color: const Color(0xFFE2E8F0)),
                        ),
                        const Icon(Icons.location_on,
                            size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CityAutocompleteField(
                          controller: _originController,
                          hint: 'Origen',
                          icon: Icons.search,
                          defaultSuggestions: popularArgentineCities,
                          citySearchSource: CitySearchSource.georef,
                        ),
                        if (_showErrors &&
                            _originController.text.trim().isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              'Este campo es obligatorio',
                              style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        const SizedBox(height: 12),
                        CityAutocompleteField(
                          controller: _destinationController,
                          hint: 'Destino',
                          icon: Icons.near_me_rounded,
                          defaultSuggestions: popularArgentineCities,
                          citySearchSource: CitySearchSource.georef,
                        ),
                        if (_showErrors &&
                            _destinationController.text.trim().isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              'Este campo es obligatorio',
                              style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const _SectionHeader(
                    icon: Icons.add_location_alt_rounded,
                    title: 'Paradas'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      icon: const Icon(Icons.lightbulb_rounded,
                          color: Color(0xFFF59E0B), size: 32),
                      title: const Text(
                        '¿Por qué agregar paradas?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      content: const Text(
                        'Agregar paradas va a aumentar la exposición de tu viaje y hará que más gente pueda unirse a él!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                      ),
                      actionsAlignment: MainAxisAlignment.center,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Entendido'),
                        ),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.info_outline_rounded,
                      size: 15, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SuggestionChipInput(
              label: 'Ciudades (Opcional)',
              hint: 'Buscar ciudad...',
              chips: _stops,
              onAdd: (v) => setState(() => _stops.add(v)),
              onRemove: (i) => setState(() => _stops.removeAt(i)),
              prefixIcon: Icons.add_location_alt_outlined,
              asyncSearch: (query) async {
                final results = await CitySearchService.instance.search(
                  query,
                  overrideSource: CitySearchSource.georef,
                );
                return results.map((s) => s.name).toList();
              },
            ),

            const SizedBox(height: 32),

            // ── VEHÍCULO ───────────────────────────────────────────────────
            const _SectionHeader(
                icon: Icons.directions_car_rounded, title: 'Vehículo'),
            const SizedBox(height: 4),
            if (_showErrors && _selectedVehicle == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Este campo es obligatorio',
                  style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 8),
            vehiclesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: Colors.red)),
              data: (vehicles) => _VehicleSelector(
                vehicles: vehicles,
                selected: _selectedVehicle,
                hasError: _showErrors && _selectedVehicle == null,
                onTap: () => _openVehicleSelector(vehicles),
              ),
            ),

            const SizedBox(height: 32),

            // ── VÍAS / RUTAS ───────────────────────────────────────────────
            const _SectionHeader(
                icon: Icons.directions_rounded,
                title: 'Vías / Rutas'),
            const SizedBox(height: 16),
            SuggestionChipInput(
              label: 'Rutas (Opcional)',
              hint: 'Añadir vía o número de ruta...',
              suggestions: _routeSuggestions,
              chips: _routes,
              onAdd: (v) => setState(() => _routes.add(v)),
              onRemove: (i) => setState(() => _routes.removeAt(i)),
              prefixIcon: Icons.add_road_rounded,
            ),

            const SizedBox(height: 32),

            // ── FECHA Y HORA ───────────────────────────────────────────────
            const _SectionHeader(
                icon: Icons.calendar_today_rounded,
                title: 'Fecha y hora'),
            const SizedBox(height: 16),
            Row(
              children: [
                const _MedLabel('FECHA DE SALIDA'),
                if (_showErrors && _departureDate == null) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '— Este campo es obligatorio',
                    style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _departureDate = picked);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: Color(0xFF64748B), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _departureDate == null
                          ? 'Seleccionar fecha'
                          : _dateDisplayText,
                      style: TextStyle(
                        color: _departureDate == null
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const _MedLabel('HORA DE SALIDA'),
                if (_showErrors && _timeFromController.text.trim().isEmpty) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '— Este campo es obligatorio',
                    style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _RangeInputRow(
              label1: 'Salgo a las',
              label2: 'Hasta las (opcional)',
              controller1: _timeFromController,
              controller2: _timeToController,
              formatter: TimeFormatter(),
              hint1: 'ej: 11:00',
              hint2: 'ej: 13:00',
              icon: Icons.access_time_rounded,
            ),
            if (_timeError != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Text(
                    _timeError!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // ── ASIENTOS Y PRECIO ─────────────────────────────────────────
            const _SectionHeader(
                icon: Icons.payments_outlined,
                title: 'Asientos y precio'),
            const SizedBox(height: 16),
            _SeatsAndPriceCard(
              seats: _seats,
              price: _price,
              splitCosts: _splitCosts,
              onSeatsChanged: (v) => setState(() => _seats = v),
              onPriceChanged: (v) => setState(() => _price = v),
              onSplitCostsChanged: (v) => setState(() => _splitCosts = v),
            ),

            const SizedBox(height: 32),

            // ── PREFERENCIAS ──────────────────────────────────────────────
            const _SectionHeader(
                icon: Icons.tune_rounded,
                title: 'Preferencias del conductor'),
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
              onChanged: (v) =>
                  setState(() => _picksUpPassengers = v),
            ),
            const SizedBox(height: 8),
            _PreferenceToggle(
              icon: Icons.door_front_door_rounded,
              title: 'Dejo a cada pasajero en su destino',
              value: _dropsOffPassengers,
              onChanged: (v) =>
                  setState(() => _dropsOffPassengers = v),
            ),

            const SizedBox(height: 32),

            // ── DESCRIPCIÓN ───────────────────────────────────────────────
            const _SubLabel('DESCRIPCIÓN (OPCIONAL)'),
            const SizedBox(height: 8),
            _DescriptionField(controller: _descriptionController),

            const SizedBox(height: 40),

            // ── ERROR BANNER ──────────────────────────────────────────────
            if (_showErrors && _hasRequiredErrors) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hay campos obligatorios sin completar. Revisá los campos marcados en rojo.',
                        style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── BOTÓN PUBLICAR ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _publishing ? null : _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: _publishing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _picksUpPassengers && _dropsOffPassengers
                            ? 'Publicar viaje'
                            : 'Siguiente',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
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

// ── Vehicle selector UI ───────────────────────────────────────────────────────

class _VehicleSelector extends StatelessWidget {
  const _VehicleSelector({
    required this.vehicles,
    required this.selected,
    required this.onTap,
    this.hasError = false,
  });

  final List<Vehicle> vehicles;
  final Vehicle? selected;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasError ? const Color(0xFFFFF5F5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: hasError
              ? Border.all(color: const Color(0xFFDC2626), width: 1.5)
              : selected != null
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
        ),
        child: Row(
          children: [
            if (selected != null)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Color(selected!.colorHex),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFE2E8F0), width: 1),
                ),
              )
            else
              const Icon(Icons.directions_car_outlined,
                  color: Color(0xFF94A3B8), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected != null
                    ? '${selected!.brand} ${selected!.model} · ${selected!.color}'
                    : vehicles.isEmpty
                        ? 'Agregar vehículo'
                        : 'Seleccionar vehículo',
                style: TextStyle(
                  fontSize: 15,
                  color: selected != null
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet showing the user's existing vehicles + an "Add car" option.
class _VehiclePickerSheet extends StatelessWidget {
  const _VehiclePickerSheet({
    required this.vehicles,
    required this.onAddNew,
  });

  final List<Vehicle> vehicles;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Seleccioná tu vehículo',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final v in vehicles)
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(v.colorHex),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFE2E8F0), width: 1.5),
                ),
              ),
              title: Text('${v.brand} ${v.model}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
              subtitle: Text(v.color,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF64748B))),
              onTap: () => Navigator.of(context).pop(v),
            ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(Icons.add,
                  size: 18, color: AppColors.primary),
            ),
            title: const Text('Agregar vehículo',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
            onTap: onAddNew,
          ),
        ],
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

/// Slightly larger sublabel — used for date/time fields.
class _MedLabel extends StatelessWidget {
  const _MedLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF475569),
        letterSpacing: 0.4,
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

  Widget _buildBox(
      String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
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
              hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8), fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              suffixIcon: Icon(icon,
                  color: const Color(0xFF64748B), size: 18),
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
          child:
              Text('y', style: TextStyle(color: Color(0xFF64748B))),
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
    required this.splitCosts,
    required this.onSeatsChanged,
    required this.onPriceChanged,
    required this.onSplitCostsChanged,
  });

  final int seats;
  final int price;
  final bool splitCosts;
  final ValueChanged<int> onSeatsChanged;
  final ValueChanged<int> onPriceChanged;
  final ValueChanged<bool> onSplitCostsChanged;

  @override
  State<_SeatsAndPriceCard> createState() => _SeatsAndPriceCardState();
}

class _SeatsAndPriceCardState extends State<_SeatsAndPriceCard> {
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.price.toString());
  }

  @override
  void didUpdateWidget(_SeatsAndPriceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update text only when price changed externally (not from our own editing)
    if (oldWidget.price != widget.price) {
      final cursor = _priceController.selection;
      _priceController.text = widget.price.toString();
      // Restore cursor if still valid
      if (cursor.start <= _priceController.text.length) {
        _priceController.selection = cursor;
      }
    }
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
                    'Asientos disponibles',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1E293B)),
                  ),
                  Text(
                    'Excluyéndote a ti',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF64748B)),
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
                      icon: const Icon(Icons.remove,
                          color: AppColors.primary),
                    ),
                    Text(
                      '${widget.seats}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      onPressed: widget.seats < 5
                          ? () => widget.onSeatsChanged(widget.seats + 1)
                          : null,
                      icon: Icon(Icons.add,
                          color: widget.seats < 5
                              ? AppColors.primary
                              : const Color(0xFFCBD5E1)),
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
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1E293B)),
                  ),
                  Text(
                    r'Recomendado: $4.500',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Opacity(
                opacity: widget.splitCosts ? 0.4 : 1.0,
                child: Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.splitCosts
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Text(
                            'Se dividirán',
                            style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                                fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          onChanged: (v) =>
                              widget.onPriceChanged(int.tryParse(v) ?? 0),
                          decoration: const InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 12, top: 12),
                              child: Text(
                                'ARS',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 4),

          // Dividir gastos
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dividir gastos',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Activa esta opción si el precio del viaje será la división de los gastos totales del mismo',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: widget.splitCosts,
                onChanged: widget.onSplitCostsChanged,
                activeColor: AppColors.primary,
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
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: value
                  ? AppColors.primary
                  : const Color(0xFF94A3B8),
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 14,
                    color: value
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                    fontWeight: value
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
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
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: 4,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText:
              'Contá algo sobre el viaje, condiciones, paradas, etc.',
          hintStyle:
              TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
