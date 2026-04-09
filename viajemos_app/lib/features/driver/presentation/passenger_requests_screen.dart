import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/formatters/date_formatter.dart';
import '../../../shared/services/city_search_service.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';
import '../../history/data/history_repository.dart';
import '../../passenger/data/passenger_request_repository.dart';

// ── Pantalla de filtro ────────────────────────────────────────────────────────

class PassengerRequestsFilterScreen extends StatefulWidget {
  const PassengerRequestsFilterScreen({super.key});

  @override
  State<PassengerRequestsFilterScreen> createState() =>
      _PassengerRequestsFilterScreenState();
}

class _PassengerRequestsFilterScreenState
    extends State<PassengerRequestsFilterScreen> {
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: const Color(0xFF1E293B),
          onPressed: () => context.go('/driver'),
        ),
        title: const Text(
          'Pedidos de pasajeros',
          style: TextStyle(
              color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        child: Container(
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
              // ORIGEN
              _label('ORIGEN'),
              _inputField(
                controller: _originController,
                hint: 'Ciudad de origen (Opcional)',
                icon: Icons.trip_origin_rounded,
              ),
              const SizedBox(height: 16),

              // DESTINO
              _label('DESTINO'),
              _inputField(
                controller: _destController,
                hint: 'Destino (Opcional)',
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 20),

              // Fechas
              _label('FECHA'),
              Row(
                children: [
                  Expanded(child: _dateField('DESDE', _fromDateController)),
                  const SizedBox(width: 12),
                  Expanded(child: _dateField('HASTA', _toDateController)),
                ],
              ),
              const SizedBox(height: 28),

              // Botón
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go(
                    '/driver/passenger-requests',
                    extra: {
                      'origin': _originController.text.trim(),
                      'destination': _destController.text.trim(),
                      'dateFrom': _fromDateController.text.trim(),
                      'dateTo': _toDateController.text.trim(),
                    },
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Buscar pedidos',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B))),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) =>
      CityAutocompleteField(
        controller: controller,
        hint: hint,
        icon: icon,
        iconColor: const Color(0xFF1A73E8),
        defaultSuggestions: popularArgentineCities,
        citySearchSource: CitySearchSource.georef,
      );

  Widget _dateField(String label, TextEditingController controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B))),
          ),
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
                suffixIcon: Icon(Icons.calendar_month,
                    color: Color(0xFF64748B), size: 18),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ),
          ),
        ],
      );
}

// ── Pantalla de resultados ────────────────────────────────────────────────────

class PassengerRequestsScreen extends ConsumerStatefulWidget {
  const PassengerRequestsScreen({
    super.key,
    this.origin = '',
    this.destination = '',
    this.dateFrom = '',
    this.dateTo = '',
  });

  final String origin;
  final String destination;
  final String dateFrom;
  final String dateTo;

  @override
  ConsumerState<PassengerRequestsScreen> createState() =>
      _PassengerRequestsScreenState();
}

class _PassengerRequestsScreenState
    extends ConsumerState<PassengerRequestsScreen> {
  late Future<List<PassengerRequest>> _requestsFuture;
  DateTime? _filterDate;

  final List<DateTime> _nextDays = List.generate(
    14,
    (index) => DateTime.now().add(Duration(days: index)),
  );

  @override
  void initState() {
    super.initState();
    _requestsFuture = _fetchRequests();
  }

  Future<List<PassengerRequest>> _fetchRequests() {
    DateTime? from;
    DateTime? to;
    final now = DateTime.now();
    final year = now.year;

    if (widget.dateFrom.isNotEmpty) {
      final parts = widget.dateFrom.split('/');
      if (parts.length == 2) {
        from = DateTime(year, int.parse(parts[1]), int.parse(parts[0]));
      }
    }
    if (widget.dateTo.isNotEmpty) {
      final parts = widget.dateTo.split('/');
      if (parts.length == 2) {
        to = DateTime(year, int.parse(parts[1]), int.parse(parts[0]));
      }
    }

    return PassengerRequestRepository().fetchRequests(
      origin: widget.origin.isEmpty ? null : widget.origin,
      destination: widget.destination.isEmpty ? null : widget.destination,
      dateFrom: from,
      dateTo: to,
    );
  }

  String _formatDateShort(DateTime date) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dayName = days[date.weekday - 1];
    return '$dayName ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Future<void> _showOfferSheet(PassengerRequest request) async {
    // Load driver's active trips before showing the sheet
    List<ActiveDriverTrip> driverTrips;
    try {
      driverTrips = await ref
          .read(historyRepositoryProvider)
          .fetchActiveDriverTrips();
    } catch (_) {
      driverTrips = [];
    }

    if (!mounted) return;

    // Filter only trips with available seats
    final availableTrips =
        driverTrips.where((t) => t.freeSeats > 0).toList();

    if (availableTrips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No tenés viajes activos con lugares disponibles para ofrecer.')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OfferSheet(
        request: request,
        availableTrips: availableTrips,
      ),
    );
  }

  String get _appBarTitle {
    final origin =
        widget.origin.isNotEmpty ? widget.origin : 'Pedidos';
    final dest = widget.destination;
    return dest.isEmpty ? '$origin  →' : '$origin  →  $dest';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver'),
        ),
      ),
      body: Column(
        children: [
          // Filtro de fecha
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: AppColors.pageBackground,
            child: Container(
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
                      Icon(Icons.calendar_today_rounded,
                          size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Text('Filtrar por fecha',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary),
                  items: [
                    DropdownMenuItem<DateTime>(
                      value: null,
                      child: Text('Todas las fechas',
                          style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.7),
                              fontSize: 14)),
                    ),
                    ..._nextDays.map((date) => DropdownMenuItem(
                          value: date,
                          child: Text(_formatDateShort(date),
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _filterDate = v),
                ),
              ),
            ),
          ),

          // Lista
          Expanded(
            child: FutureBuilder<List<PassengerRequest>>(
              future: _requestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }
                var requests = snapshot.data ?? [];

                // Client-side date filter from dropdown
                if (_filterDate != null) {
                  final fd = _filterDate!;
                  requests = requests.where((r) {
                    return !r.dateFrom.isAfter(
                            DateTime(fd.year, fd.month, fd.day, 23, 59)) &&
                        !r.dateTo.isBefore(
                            DateTime(fd.year, fd.month, fd.day));
                  }).toList();
                }

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        const Text('No hay pedidos por ahora',
                            style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) => _RequestCard(
                    request: requests[i],
                    onOffer: () => _showOfferSheet(requests[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onOffer});
  final PassengerRequest request;
  final VoidCallback onOffer;

  String _formatPrice(int price) => '\$${price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  String get _initials {
    final parts = request.passengerName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return request.passengerName.isNotEmpty
        ? request.passengerName[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOffer,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Passenger + max price
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(_initials,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.passengerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (request.avgRating != null) ...[
                            const Icon(Icons.star_rounded,
                                size: 15, color: Color(0xFFFACC15)),
                            const SizedBox(width: 3),
                            Text(
                              request.avgRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ] else
                            const Text('Sin calificación',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  request.maxPrice != null
                      ? _formatPrice(request.maxPrice!)
                      : 'A convenir',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: request.maxPrice != null
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route
            Row(
              children: [
                Flexible(
                  child: Text(request.originAddress,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      overflow: TextOverflow.ellipsis),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward,
                      size: 15, color: AppColors.primary),
                ),
                Flexible(
                  child: Text(request.destinationAddress,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date & time
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(request.formattedDateRange,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                if (request.timeWindow.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(request.timeWindow,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // Seats visualization
            Row(
              children: [
                const Text('Viajeros:',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                for (int i = 0; i < request.seatsNeeded; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.person,
                          size: 14, color: Colors.white),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  '${request.seatsNeeded} asiento${request.seatsNeeded > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),

            // Badges
            if (request.hasPet || request.isSmoker) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (request.hasPet)
                    _Badge(
                        label: 'Mascota',
                        icon: Icons.pets_rounded,
                        bg: AppColors.greenLight,
                        fg: AppColors.green),
                  if (request.isSmoker)
                    _Badge(
                        label: 'Fumador',
                        icon: Icons.smoking_rooms_rounded,
                        bg: AppColors.orangeLight,
                        fg: AppColors.orange),
                ],
              ),
            ],

            if (request.description != null &&
                request.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                request.description!,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            // Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Ofrecer viaje',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Offer Sheet ───────────────────────────────────────────────────────────────

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({
    required this.request,
    required this.availableTrips,
  });
  final PassengerRequest request;
  final List<ActiveDriverTrip> availableTrips;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  final _messageController = TextEditingController();
  ActiveDriverTrip? _selectedTrip;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.availableTrips.length == 1) {
      _selectedTrip = widget.availableTrips.first;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _tripLabel(ActiveDriverTrip t) {
    String cityOf(String addr) {
      final parts = addr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.length <= 1) return addr.trim();
      if (RegExp(r'^\d').hasMatch(parts.first)) return parts.last;
      return parts.first;
    }

    final date =
        '${t.departureDate.day.toString().padLeft(2, '0')}/${t.departureDate.month.toString().padLeft(2, '0')}';
    return '${cityOf(t.originAddress)} → ${cityOf(t.destinationAddress)}  ·  $date  ·  ${t.freeSeats} lugar${t.freeSeats != 1 ? 'es' : ''}';
  }

  Future<void> _send() async {
    if (_selectedTrip == null || _sending) return;
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.rpc('send_trip_invitation', params: {
        'p_trip_alert_id': widget.request.id,
        'p_trip_id': _selectedTrip!.id,
        'p_message': _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Oferta enviada a ${widget.request.passengerName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al enviar oferta: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ofrecer viaje a ${widget.request.passengerName}',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.request.originAddress} → ${widget.request.destinationAddress}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Trip selector
          const Text(
            'SELECCIONÁ TU VIAJE',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              border: Border.all(color: AppColors.border, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ActiveDriverTrip>(
                value: _selectedTrip,
                isExpanded: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                hint: const Text('Elegí un viaje',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14)),
                items: widget.availableTrips
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            _tripLabel(t),
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTrip = v),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Message
          const Text(
            'MENSAJE (OPCIONAL)',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Ej: Hola, paso cerca de tu zona!',
              hintStyle: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedTrip == null || _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar oferta',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.label,
      required this.icon,
      required this.bg,
      required this.fg});
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
