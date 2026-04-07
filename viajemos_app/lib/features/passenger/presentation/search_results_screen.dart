import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/public_profile_sheet.dart';
import '../data/trip_search_repository.dart';
import '../domain/trip_search_result.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.origin,
    this.destination,
    this.dateFromStr,
    this.dateToStr,
    this.maxPriceStr,
  });

  final String origin;
  final String? destination;
  final String? dateFromStr; // "DD/MM"
  final String? dateToStr;
  final String? maxPriceStr;

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState
    extends ConsumerState<SearchResultsScreen> {
  late Future<List<TripSearchResult>> _future;

  /// Parse "DD/MM" → DateTime (current year).
  DateTime? _parseDate(String? text) {
    if (text == null || text.isEmpty) return null;
    final parts = text.split('/');
    if (parts.length != 2) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (day == null || month == null) return null;
    return DateTime(DateTime.now().year, month, day);
  }

  @override
  void initState() {
    super.initState();
    _future = TripSearchRepository().searchTrips(
      origin: widget.origin,
      destination: widget.destination,
      dateFrom: _parseDate(widget.dateFromStr),
      dateTo: _parseDate(widget.dateToStr),
      maxPrice: int.tryParse(widget.maxPriceStr ?? ''),
    );
  }

  String get _title {
    final from =
        widget.origin.isNotEmpty ? widget.origin : 'Origen';
    if (widget.destination != null &&
        widget.destination!.isNotEmpty) {
      return '$from  →  ${widget.destination}';
    }
    return '$from  →';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<TripSearchResult>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al buscar viajes:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          final trips = snap.data ?? [];
          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 64, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 16),
                  const Text(
                    'No encontramos viajes\npara esa búsqueda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Modificar búsqueda'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 14),
            itemBuilder: (_, i) =>
                _TripCard(trip: trips[i]),
          );
        },
      ),
    );
  }
}

// ── Trip Card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final TripSearchResult trip;

  String _formatPrice(int price) => '\$${price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripDetailsSheet(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver + price
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(trip.driverInitials,
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
                      Text(trip.driverName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 15,
                              color: Color(0xFFFACC15)),
                          const SizedBox(width: 3),
                          Text(
                            trip.driverRating > 0
                                ? trip.driverRating.toStringAsFixed(1)
                                : 'Sin calificación',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatPrice(trip.pricePerSeat),
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route — show city names only
            Row(
              children: [
                Flexible(
                  child: Text(trip.originCity,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                      overflow: TextOverflow.ellipsis),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward,
                      size: 15, color: AppColors.primary),
                ),
                Flexible(
                  child: Text(trip.destinationCity,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            if (trip.stops.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.add_location_alt_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      'Paradas: ${trip.stops.join(' · ')}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (trip.via.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.add_road_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      'Rutas: ${trip.via.join(' · ')}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),

            // Date & time
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  trip.formattedTime.isNotEmpty
                      ? '${trip.formattedDate}  •  ${trip.formattedTime}'
                      : trip.formattedDate,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Seats available
            Row(
              children: [
                const Icon(Icons.event_seat_rounded,
                    size: 14,
                    color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  '${trip.freeSeats} lugar${trip.freeSeats != 1 ? 'es' : ''} disponible${trip.freeSeats != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary),
                ),
              ],
            ),

            // Badges — siempre visibles, grises si inactivos
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Badge(
                    label: 'Mascotas',
                    icon: Icons.pets_rounded,
                    bg: AppColors.greenLight,
                    fg: AppColors.green,
                    active: trip.allowsPets,
                    large: true),
                _Badge(
                    label: 'Pasa a buscarte',
                    icon: Icons.home_rounded,
                    bg: const Color(0xFFEFF6FF),
                    fg: const Color(0xFF1D4ED8),
                    active: trip.picksUpAtDoor,
                    large: true),
                _Badge(
                    label: 'Te deja en destino',
                    icon: Icons.where_to_vote_rounded,
                    bg: const Color(0xFFF5F3FF),
                    fg: const Color(0xFF6D28D9),
                    active: trip.dropsOffAtDoor,
                    large: true),
              ],
            ),

            // Seats visualization
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Viajeros:',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                for (int i = 0; i < trip.seatsTaken; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.person,
                          size: 14, color: Colors.white),
                    ),
                  ),
                for (int i = 0; i < trip.freeSeats; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.inputBackground,
                      child: const Icon(Icons.person_outline,
                          size: 14,
                          color: AppColors.textSecondary),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  '${trip.seatsTaken}/${trip.availableSeats}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),

            // Car
            if (trip.vehicleDisplay.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.directions_car_rounded,
                      size: 14,
                      color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(trip.vehicleDisplay,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Trip Details Sheet ────────────────────────────────────────────────────────

class _TripDetailsSheet extends StatefulWidget {
  const _TripDetailsSheet({required this.trip});
  final TripSearchResult trip;

  @override
  State<_TripDetailsSheet> createState() => _TripDetailsSheetState();
}

class _TripDetailsSheetState extends State<_TripDetailsSheet> {
  bool _sending = false;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  TripSearchResult get trip => widget.trip;

  String _formatPrice(int price) => '\$${price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  Future<void> _sendRequest() async {
    setState(() => _sending = true);
    try {
      await TripSearchRepository().createTripRequest(
        tripId: trip.id,
        seatsRequested: 1,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(content: Text('Solicitud enviada a ${trip.driverName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar la solicitud'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date title
                  Text(
                    trip.formattedDate,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),

                  // Route — cities
                  Row(
                    children: [
                      Flexible(
                        child: Text(trip.originCity,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B))),
                      ),
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward,
                            size: 15, color: AppColors.primary),
                      ),
                      Flexible(
                        child: Text(trip.destinationCity,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B))),
                      ),
                    ],
                  ),
                  // Specific addresses (only shown when there's address detail)
                  if (trip.originDetailAddress != null ||
                      trip.destinationDetailAddress != null) ...[
                    const SizedBox(height: 10),
                    if (trip.originDetailAddress != null)
                      _DetailRow(
                          icon: Icons.trip_origin_rounded,
                          text: 'Salida: ${trip.originDetailAddress!}'),
                    if (trip.destinationDetailAddress != null) ...[
                      const SizedBox(height: 6),
                      _DetailRow(
                          icon: Icons.place_rounded,
                          text: 'Llegada: ${trip.destinationDetailAddress!}'),
                    ],
                  ],
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 20),

                  // Driver — tap to see public profile
                  GestureDetector(
                    onTap: () => showPublicProfile(context, trip.driverId),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(trip.driverInitials,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(trip.driverName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Color(0xFF1E293B))),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 15,
                                      color: Color(0xFFFACC15)),
                                  const SizedBox(width: 3),
                                  Text(
                                    trip.driverRating > 0
                                        ? trip.driverRating
                                            .toStringAsFixed(1)
                                        : 'Sin calificación',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.primary, size: 22),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // Details
                  if (trip.formattedTime.isNotEmpty)
                    _DetailRow(
                        icon: Icons.access_time_rounded,
                        text:
                            '${trip.formattedDate}  ·  ${trip.formattedTime}'),
                  if (trip.vehicleDisplay.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailRow(
                        icon: Icons.directions_car_rounded,
                        text: trip.vehicleDisplay),
                  ],
                  if (trip.stops.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailRow(
                        icon: Icons.add_location_alt_outlined,
                        text:
                            '${trip.stops.length} parada${trip.stops.length > 1 ? 's' : ''}: ${trip.stops.join(', ')}'),
                  ],
                  if (trip.via.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailRow(
                        icon: Icons.add_road_rounded,
                        text: 'Rutas: ${trip.via.join(', ')}'),
                  ],

                  // Badges — siempre visibles, grises si inactivos
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Badge(
                          label: 'Mascotas',
                          icon: Icons.pets_rounded,
                          bg: AppColors.greenLight,
                          fg: AppColors.green,
                          active: trip.allowsPets),
                      _Badge(
                          label: 'Pasa a buscarte',
                          icon: Icons.home_rounded,
                          bg: const Color(0xFFEFF6FF),
                          fg: const Color(0xFF1D4ED8),
                          active: trip.picksUpAtDoor),
                      _Badge(
                          label: 'Te deja en destino',
                          icon: Icons.where_to_vote_rounded,
                          bg: const Color(0xFFF5F3FF),
                          fg: const Color(0xFF6D28D9),
                          active: trip.dropsOffAtDoor),
                    ],
                  ),

                  if (trip.description != null &&
                      trip.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Descripción',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    Text(trip.description!,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.5)),
                  ],

                  const SizedBox(height: 16),

                  // Seats visualization
                  const Text('Viajeros',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (int i = 0; i < trip.seatsTaken; i++)
                        Padding(
                          padding:
                              const EdgeInsets.only(right: 6),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary,
                            child: const Icon(Icons.person,
                                size: 15, color: Colors.white),
                          ),
                        ),
                      for (int i = 0; i < trip.freeSeats; i++)
                        Padding(
                          padding:
                              const EdgeInsets.only(right: 6),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                AppColors.inputBackground,
                            child: const Icon(
                                Icons.person_outline,
                                size: 15,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '${trip.seatsTaken}/${trip.availableSeats} ocupados',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price
                  Row(
                    children: [
                      Text(
                        _formatPrice(trip.pricePerSeat),
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      const Text('por asiento',
                          style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Message + send button
          Container(
            padding:
                const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _messageController,
                  maxLines: 2,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Mensaje para el conductor (opcional)',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27)),
                  elevation: 0,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Enviar solicitud',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF475569))),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    this.active = true,
    this.large = false,
  });
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final bool active;
  final bool large;

  static const _inactiveBg = Color(0xFFF1F5F9);
  static const _inactiveFg = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    final bgColor = active ? bg : _inactiveBg;
    final fgColor = active ? fg : _inactiveFg;
    final iconSize = large ? 15.0 : 12.0;
    final fontSize = large ? 13.0 : 11.0;
    final hPad = large ? 11.0 : 8.0;
    final vPad = large ? 6.0 : 4.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: fgColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: fgColor,
              fontWeight: FontWeight.w600,
              decoration: active ? null : TextDecoration.lineThrough,
              decorationColor: _inactiveFg,
            ),
          ),
        ],
      ),
    );
  }
}
