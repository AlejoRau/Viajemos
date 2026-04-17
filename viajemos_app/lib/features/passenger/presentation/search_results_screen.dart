import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/public_profile_sheet.dart';
import '../../../shared/widgets/app_toast.dart';
import '../data/trip_search_repository.dart';
import '../domain/trip_search_result.dart';

String _mapRequestError(Object e) {
  final msg = e.toString().toLowerCase();
  if (e is SocketException || msg.contains('socketexception') || msg.contains('network') || msg.contains('connection')) {
    return 'Sin conexión a internet. Revisá tu red e intentá de nuevo.';
  }
  if (msg.contains('own_trip') || msg.contains('no podés unirte a tu propio viaje')) {
    return 'No podés enviarte una solicitud a tu propio viaje.';
  }
  if (msg.contains('already_requested') || msg.contains('duplicate') || msg.contains('unique') || msg.contains('ya tenés')) {
    return 'Ya tenés una solicitud pendiente para este viaje.';
  }
  if (msg.contains('trip_full') || msg.contains('no hay lugares') || msg.contains('seats')) {
    return 'El viaje ya no tiene lugares disponibles.';
  }
  if (msg.contains('not authenticated') || msg.contains('jwt') || msg.contains('auth')) {
    return 'Tu sesión expiró. Por favor, volvé a iniciar sesión.';
  }
  if (e is TimeoutException || msg.contains('timeout')) {
    return 'La solicitud tardó demasiado. Revisá tu conexión e intentá de nuevo.';
  }
  return 'No se pudo enviar la solicitud. Intentá de nuevo.';
}

// ── Passenger avatar helper ───────────────────────────────────────────────────

Widget _passengerAvatar({
  required String name,
  String? avatarUrl,
  required double radius,
  required Color color,
}) {
  String initials(String n) {
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  Widget fallback() => CircleAvatar(
        radius: radius,
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(
          initials(name),
          style: TextStyle(
            fontSize: radius * 0.62,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );

  if (avatarUrl == null || avatarUrl.isEmpty) return fallback();

  return SizedBox(
    width: radius * 2,
    height: radius * 2,
    child: ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback(),
        errorWidget: (_, __, ___) => fallback(),
      ),
    ),
  );
}

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

enum _SortMode { date, price }

class _SearchResultsScreenState
    extends ConsumerState<SearchResultsScreen> {
  late Future<List<TripSearchResult>> _future;

  // ── Active filters ────────────────────────────────────────────────────────
  bool _onlyAvailable = false;
  bool _onlyPets = false;
  _SortMode _sort = _SortMode.date;

  List<TripSearchResult> _applyFilters(List<TripSearchResult> all) {
    var list = all.where((t) {
      if (_onlyAvailable && t.freeSeats == 0) return false;
      if (_onlyPets && !t.allowsPets) return false;
      return true;
    }).toList();
    list.sort((a, b) {
      // Always put full trips last
      final aFull = a.freeSeats == 0 ? 1 : 0;
      final bFull = b.freeSeats == 0 ? 1 : 0;
      if (aFull != bFull) return aFull.compareTo(bFull);
      if (_sort == _SortMode.price) return a.pricePerSeat.compareTo(b.pricePerSeat);
      return a.departureDate.compareTo(b.departureDate);
    });
    return list;
  }

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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            return const Center(child: CircularProgressIndicator());
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
          final all = snap.data ?? [];
          final trips = _applyFilters(all);

          if (all.isEmpty) {
            return _EmptyState(
              origin: widget.origin,
              destination: widget.destination,
              dateFrom: _parseDate(widget.dateFromStr),
              dateTo: _parseDate(widget.dateToStr),
            );
          }

          return Column(
            children: [
              // ── Filter bar ──────────────────────────────────────────────
              _FilterBar(
                onlyAvailable: _onlyAvailable,
                onlyPets: _onlyPets,
                sort: _sort,
                total: all.length,
                filtered: trips.length,
                onAvailableChanged: (v) => setState(() => _onlyAvailable = v),
                onPetsChanged: (v) => setState(() => _onlyPets = v),
                onSortChanged: (v) => setState(() => _sort = v),
              ),
              // ── Results ─────────────────────────────────────────────────
              Expanded(
                child: trips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.filter_list_off_rounded,
                                size: 48, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 12),
                            const Text(
                              'Ningún viaje coincide\ncon los filtros activos',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => setState(() {
                                _onlyAvailable = false;
                                _onlyPets = false;
                                _sort = _SortMode.date;
                              }),
                              child: const Text('Limpiar filtros'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: trips.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => _TripCard(trip: trips[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.origin,
    required this.destination,
    this.dateFrom,
    this.dateTo,
  });
  final String origin;
  final String? destination;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 40, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay viajes disponibles',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              'Todavía nadie publicó este trayecto.\nCreá una alerta y te avisamos cuando haya uno.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => context.push(
                  '/passenger/create-request',
                  extra: {
                    'origin': origin,
                    if (destination != null && destination!.isNotEmpty)
                      'destination': destination,
                    if (dateFrom != null) 'dateFrom': dateFrom,
                    if (dateTo != null) 'dateTo': dateTo,
                  },
                ),
                icon: const Icon(Icons.notifications_active_rounded,
                    size: 18, color: Colors.white),
                label: const Text(
                  'Crear alerta para este viaje',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Modificar búsqueda',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.onlyAvailable,
    required this.onlyPets,
    required this.sort,
    required this.total,
    required this.filtered,
    required this.onAvailableChanged,
    required this.onPetsChanged,
    required this.onSortChanged,
  });

  final bool onlyAvailable;
  final bool onlyPets;
  final _SortMode sort;
  final int total;
  final int filtered;
  final ValueChanged<bool> onAvailableChanged;
  final ValueChanged<bool> onPetsChanged;
  final ValueChanged<_SortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Disponibles',
                    icon: Icons.event_seat_rounded,
                    active: onlyAvailable,
                    onTap: () => onAvailableChanged(!onlyAvailable),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Mascotas',
                    icon: Icons.pets_rounded,
                    active: onlyPets,
                    onTap: () => onPetsChanged(!onlyPets),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: sort == _SortMode.date ? 'Fecha ↑' : 'Precio ↑',
                    icon: Icons.sort_rounded,
                    active: sort == _SortMode.price,
                    onTap: () => onSortChanged(
                        sort == _SortMode.date ? _SortMode.price : _SortMode.date),
                  ),
                ],
              ),
            ),
          ),
          if (filtered < total) ...[
            const SizedBox(width: 8),
            Text(
              '$filtered/$total',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Driver Avatar ─────────────────────────────────────────────────────────────

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({
    required this.initials,
    required this.avatarUrl,
    required this.radius,
  });
  final String initials;
  final String? avatarUrl;
  final double radius;

  Widget _initialsAvatar() => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.62,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) return _initialsAvatar();

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialsAvatar(),
          errorWidget: (_, __, ___) => _initialsAvatar(),
        ),
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
    final isFull = trip.freeSeats == 0;
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFull ? const Color(0xFFF8FAFC) : AppColors.background,
          border: Border.all(
            color: isFull ? const Color(0xFFCBD5E1) : AppColors.border,
            width: 2,
          ),
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
                GestureDetector(
                  onTap: () => showPublicProfile(context, trip.driverId),
                  behavior: HitTestBehavior.opaque,
                  child: _DriverAvatar(
                    initials: trip.driverInitials,
                    avatarUrl: trip.driverAvatarUrl,
                    radius: 24,
                  ),
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
                if (isFull)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFCA5A5), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 13, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text('Lleno',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626))),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (trip.splitCosts)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFBFDBFE), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_alt_outlined,
                                  size: 13, color: Color(0xFF1D4ED8)),
                              SizedBox(width: 4),
                              Text(
                                'Gastos\ndivididos',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF1D4ED8),
                                    fontWeight: FontWeight.w600,
                                    height: 1.2),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          _formatPrice(trip.pricePerSeat),
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Route — show effective origin/destination for the passenger
            _RouteRow(trip: trip),
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
                    child: i < trip.passengers.length
                        ? GestureDetector(
                            onTap: () => showPublicProfile(context, trip.passengers[i].userId),
                            child: _passengerAvatar(
                              name: trip.passengers[i].name,
                              avatarUrl: trip.passengers[i].avatarUrl,
                              radius: 13,
                              color: AppColors.primary,
                            ),
                          )
                        : const CircleAvatar(
                            radius: 13,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person,
                                size: 14, color: Colors.white),
                          ),
                  ),
                for (int i = 0; i < trip.freeSeats; i++)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.inputBackground,
                      child: Icon(Icons.person_outline,
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
        ],
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
  bool _sent = false;
  final _messageController = TextEditingController();
  List<Map<String, String?>> _passengers = [];

  @override
  void initState() {
    super.initState();
    _loadPassengers();
  }

  Future<void> _loadPassengers() async {
    // Use data already loaded in the model if available
    if (widget.trip.passengers.isNotEmpty) {
      setState(() => _passengers = widget.trip.passengers
          .map((p) => {'name': p.name, 'avatarUrl': p.avatarUrl, 'userId': p.userId})
          .toList());
      return;
    }
    try {
      final list =
          await TripSearchRepository().fetchTripPassengers(widget.trip.id);
      if (mounted) setState(() => _passengers = list);
    } catch (_) {}
  }

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

  Future<void> _confirmAndSend() async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Confirmás la solicitud?',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                'Estás por pedirle un lugar a ${trip.driverName}.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _ConfirmRow(
                      icon: Icons.route_rounded,
                      text: '${trip.originCity} → ${trip.destinationCity}',
                    ),
                    const SizedBox(height: 10),
                    _ConfirmRow(
                      icon: Icons.calendar_today_rounded,
                      text: trip.formattedTime.isNotEmpty
                          ? '${trip.formattedDate}  ·  ${trip.formattedTime}'
                          : trip.formattedDate,
                    ),
                    const SizedBox(height: 10),
                    _ConfirmRow(
                      icon: Icons.person_rounded,
                      text: trip.driverName,
                    ),
                    if (trip.vehicleDisplay.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _ConfirmRow(
                        icon: Icons.directions_car_rounded,
                        text: trip.vehicleDisplay,
                      ),
                    ],
                    const SizedBox(height: 10),
                    _ConfirmRow(
                      icon: Icons.attach_money_rounded,
                      text: trip.splitCosts
                          ? 'Gastos divididos'
                          : '${_formatPrice(trip.pricePerSeat)} por asiento',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Confirmar',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    await _sendRequest();
  }

  Future<void> _sendRequest() async {
    setState(() => _sending = true);
    try {
      // Prepend stop info so the driver knows where to pick up / drop off.
      String? stopNote;
      if (trip.alightingStop != null) {
        stopNote = 'Me bajo en ${trip.alightingStop}';
      } else if (trip.boardingStop != null) {
        stopNote = 'Me subo en ${trip.boardingStop}';
      }
      final userMsg = _messageController.text.trim();
      final parts = [if (stopNote != null) stopNote, if (userMsg.isNotEmpty) userMsg];
      final fullMessage = parts.isEmpty ? null : parts.join(' · ');

      await TripSearchRepository().createTripRequest(
        tripId: trip.id,
        seatsRequested: 1,
        message: fullMessage,
      );
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('duplicate')
            ? 'Ya enviaste una solicitud para este viaje'
            : e.toString().contains('own')
                ? 'No podés unirte a tu propio viaje'
                : 'Error: $e';
        AppToast.show(context, message: msg);
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

                  // Route — effective passenger route
                  _RouteRow(trip: trip, detailed: true),
                  // Specific pickup/dropoff addresses (when driver set them)
                  if (trip.pickupAddress != null ||
                      trip.dropoffAddress != null) ...[
                    const SizedBox(height: 10),
                    if (trip.pickupAddress != null)
                      _DetailRow(
                          icon: Icons.trip_origin_rounded,
                          text: 'Dirección de partida: ${trip.pickupAddress!}'),
                    if (trip.dropoffAddress != null) ...[
                      const SizedBox(height: 6),
                      _DetailRow(
                          icon: Icons.place_rounded,
                          text: 'Dirección de destino: ${trip.dropoffAddress!}'),
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
                        _DriverAvatar(
                          initials: trip.driverInitials,
                          avatarUrl: trip.driverAvatarUrl,
                          radius: 28,
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
                      // Accepted passengers with real photo/initials
                      for (int i = 0; i < trip.seatsTaken; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: i < _passengers.length
                              ? GestureDetector(
                                  onTap: _passengers[i]['userId'] != null
                                      ? () => showPublicProfile(context, _passengers[i]['userId']!)
                                      : null,
                                  child: _passengerAvatar(
                                    name: _passengers[i]['name'] ?? 'Pasajero',
                                    avatarUrl: _passengers[i]['avatarUrl'],
                                    radius: 14,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.primary,
                                  child: Icon(Icons.person,
                                      size: 15, color: Colors.white),
                                ),
                        ),
                      // Free seats
                      for (int i = 0; i < trip.freeSeats; i++)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.inputBackground,
                            child: Icon(Icons.person_outline,
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
                  if (trip.splitCosts)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFBFDBFE), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_alt_outlined,
                              size: 18, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'El precio se dividirá entre los gastos totales del viaje',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1D4ED8),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatPrice(trip.pricePerSeat),
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 6),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text('por asiento',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B))),
                        ),
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
                if (trip.freeSeats > 0) ...[
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
                ],
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: _sent
                      ? _SentConfirmation(
                          driverName: trip.driverName,
                          onClose: () => Navigator.of(context).pop(),
                        )
                      : trip.driverId ==
                          Supabase.instance.client.auth.currentUser?.id
                      ? Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(27),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 18, color: Color(0xFFF59E0B)),
                              SizedBox(width: 8),
                              Text(
                                'Este es tu viaje',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF59E0B)),
                              ),
                            ],
                          ),
                        )
                      : trip.freeSeats == 0
                          ? Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(27),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_rounded,
                                      size: 18, color: Color(0xFF94A3B8)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sin lugares disponibles',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                          onPressed: _sending ? null : _confirmAndSend,
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
                                      strokeWidth: 2.5,
                                      color: Colors.white),
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

// ── Sent Confirmation ─────────────────────────────────────────────────────────

class _SentConfirmation extends StatelessWidget {
  const _SentConfirmation({required this.driverName, required this.onClose});
  final String driverName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 20, color: Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Solicitud enviada a $driverName',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
        ),
      ],
    );
  }
}

// ── Route Row ─────────────────────────────────────────────────────────────────
class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.trip, this.detailed = false});
  final TripSearchResult trip;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    if (trip.alightingStop != null || trip.boardingStop != null) {
      return _StopMatchRoute(trip: trip, detailed: detailed);
    }
    return _DirectRoute(trip: trip, detailed: detailed);
  }
}

// Ruta directa — comportamiento original
class _DirectRoute extends StatelessWidget {
  const _DirectRoute({required this.trip, required this.detailed});
  final TripSearchResult trip;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      color: detailed ? const Color(0xFF64748B) : const Color(0xFF1E293B),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(trip.originCity,
                  style: labelStyle, overflow: TextOverflow.ellipsis),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, size: 15, color: AppColors.primary),
            ),
            Flexible(
              child: Text(trip.destinationCity,
                  style: labelStyle, overflow: TextOverflow.ellipsis),
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
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// Ruta con parada — diseño limpio
class _StopMatchRoute extends StatelessWidget {
  const _StopMatchRoute({required this.trip, required this.detailed});
  final TripSearchResult trip;
  final bool detailed;

  static const _orange = Color(0xFF16A34A);
  static const _orangeLight = Color(0xFFF0FDF4);
  static const _orangeBorder = Color(0xFFBBF7D0);

  @override
  Widget build(BuildContext context) {
    final isBoarding = trip.boardingStop != null;
    final stopName = trip.boardingStop ?? trip.alightingStop!;
    final labelColor = detailed ? const Color(0xFF64748B) : const Color(0xFF1E293B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ruta real del viaje
        Row(
          children: [
            Flexible(
              child: Text(
                trip.originCity,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: labelColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, size: 15, color: AppColors.primary),
            ),
            Flexible(
              child: Text(
                trip.destinationCity,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: labelColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Barra visual de ruta
        _StopBar(
          origin: trip.originCity,
          stop: stopName,
          destination: trip.destinationCity,
          isBoarding: isBoarding,
        ),
        const SizedBox(height: 8),
        // Pill de parada
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _orangeLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _orangeBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place_rounded, size: 13, color: _orange),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isBoarding
                      ? 'Subís en $stopName'
                      : 'Bajás en $stopName',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _orange,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StopBar extends StatelessWidget {
  const _StopBar({
    required this.origin,
    required this.stop,
    required this.destination,
    required this.isBoarding,
  });
  final String origin;
  final String stop;
  final String destination;
  final bool isBoarding;

  static const _green = Color(0xFF16A34A);
  static const _active = Color(0xFF1E293B);
  static const _faded = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    final leftActive = !isBoarding;
    final rightActive = isBoarding;

    return Row(
      children: [
        _Dot(color: leftActive ? _active : _faded),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            origin,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: leftActive ? _active : _faded),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(height: 2, color: leftActive ? _active : _faded),
        ),
        const SizedBox(width: 4),
        _Dot(color: _green, size: 9),
        const SizedBox(width: 3),
        Text(
          stop,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _green),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(height: 2, color: rightActive ? _active : _faded),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            destination,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: rightActive ? _active : _faded),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 3),
        _Dot(color: rightActive ? _active : _faded),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.size = 7});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
