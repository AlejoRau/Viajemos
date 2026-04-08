import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/role_provider.dart';
import '../../../shared/widgets/public_profile_sheet.dart';
import '../data/history_repository.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.substring(0, min(2, name.length)).toUpperCase();
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _formatNum(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ── Screen ─────────────────────────────────────────────────────────────────

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = ref.watch(roleProvider) == '/driver';

    if (!isDriver) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi historial de viajes')),
        body: const _PassengerHistoryBody(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi historial de viajes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Mis viajes'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ActiveTripsBody(),
          _DriverHistoryBody(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ACTIVE TRIPS TAB
// ══════════════════════════════════════════════════════════════════════════

class _ActiveTripsBody extends ConsumerWidget {
  const _ActiveTripsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeDriverTripsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(
        child: Text('Error al cargar viajes',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
      data: (trips) {
        final atLimit = trips.length >= 3;

        return RefreshIndicator(
          onRefresh: () async =>
              ref.refresh(activeDriverTripsProvider),
          child: trips.isEmpty
              ? const _EmptyHistory(
                  icon: Icons.directions_car_outlined,
                  message: 'No tenés viajes publicados actualmente.\n'
                      'Podés publicar hasta 3 viajes a la vez.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  children: [
                    if (atLimit)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFACC15)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Color(0xFF713F12)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Alcanzaste el límite de 3 viajes publicados.',
                                style: TextStyle(
                                    fontSize: 13, color: Color(0xFF713F12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...trips.map((t) => _ActiveTripCard(trip: t)),
                  ],
                ),
        );
      },
    );
  }
}

// ── Active trip card ───────────────────────────────────────────────────────

class _ActiveTripCard extends ConsumerStatefulWidget {
  const _ActiveTripCard({required this.trip});
  final ActiveDriverTrip trip;

  @override
  ConsumerState<_ActiveTripCard> createState() => _ActiveTripCardState();
}

class _ActiveTripCardState extends ConsumerState<_ActiveTripCard> {
  bool _deleting = false;

  void _showPassengerList(
      BuildContext context, List<String> names, List<String> ids) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PassengerListSheet(names: names, ids: ids),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar viaje'),
        content: Text(
          '¿Seguro que querés borrar el viaje '
          '${widget.trip.originAddress} → ${widget.trip.destinationAddress}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(historyRepositoryProvider).deleteTrip(widget.trip.id);
      ref.refresh(activeDriverTripsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viaje eliminado con éxito')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al borrar el viaje')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final hasPending = trip.pendingRequestsCount > 0;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DriverTripDetailsSheet(trip: trip, pageContext: context),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasPending
                    ? Colors.orange.shade300
                    : AppColors.border,
                width: hasPending ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasPending
                      ? Colors.orange.withValues(alpha: 0.12)
                      : const Color(0x0A000000),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: ACTIVO badge + status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: trip.isFull
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: trip.isFull
                                    ? Colors.orange
                                    : Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              trip.isFull ? 'COMPLETO' : 'ACTIVO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: trip.isFull
                                    ? Colors.orange.shade800
                                    : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Accepted passenger avatars (clickable)
                      if (trip.acceptedPassengerNames.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showPassengerList(
                            context,
                            trip.acceptedPassengerNames,
                            trip.acceptedPassengerIds,
                          ),
                          child: _OverlappingAvatars(
                              names: trip.acceptedPassengerNames),
                        ),
                      const SizedBox(width: 4),
                      // Delete button
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: _deleting
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red),
                              )
                            : IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 20, color: Colors.red),
                                onPressed: _confirmDelete,
                                tooltip: 'Borrar viaje',
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Route
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          trip.originAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('→',
                            style: TextStyle(
                                fontSize: 15,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                      Flexible(
                        child: Text(
                          trip.destinationAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Date · time · seats
                  Wrap(
                    spacing: 12,
                    children: [
                      _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: _formatDate(trip.departureDate)),
                      if (trip.departureTime != null)
                        _InfoChip(
                            icon: Icons.access_time_rounded,
                            label: trip.departureTime!),
                      _InfoChip(
                          icon: Icons.event_seat_rounded,
                          label: '${trip.freeSeats}/${trip.availableSeats} libres'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Price
                  Text(
                    '\$${_formatNum(trip.pricePerSeat)} por asiento',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  // CTA row
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Ver detalles',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: hasPending
                              ? Colors.orange.shade700
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: hasPending
                            ? Colors.orange.shade700
                            : AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Pending requests badge (bottom-left inside card, above card margin)
          if (hasPending)
            Positioned(
              bottom: 22,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Text(
                  '${trip.pendingRequestsCount} solicitud${trip.pendingRequestsCount > 1 ? 'es' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Driver Trip Details Sheet ──────────────────────────────────────────────

class _DriverTripDetailsSheet extends StatelessWidget {
  const _DriverTripDetailsSheet({required this.trip, required this.pageContext});
  final ActiveDriverTrip trip;
  final BuildContext pageContext;

  String _formatPrice(int p) => '\$${p.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  void _openRequests(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: pageContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TripRequestsSheet(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    _formatDate(trip.departureDate),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),

                  // Route cities
                  Row(
                    children: [
                      Flexible(
                        child: Text(trip.originAddress,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B))),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward,
                            size: 15, color: AppColors.primary),
                      ),
                      Flexible(
                        child: Text(trip.destinationAddress,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // Date & time
                  _SheetDetailRow(
                    icon: Icons.access_time_rounded,
                    text: trip.departureTime != null
                        ? '${_formatDate(trip.departureDate)}  ·  ${trip.departureTime}'
                        : _formatDate(trip.departureDate),
                  ),

                  // Vehicle
                  if (trip.vehicleDisplay.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _SheetDetailRow(
                        icon: Icons.directions_car_rounded,
                        text: trip.vehicleDisplay),
                  ],

                  // Stops
                  if (trip.stops.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _SheetDetailRow(
                      icon: Icons.add_location_alt_outlined,
                      text:
                          '${trip.stops.length} parada${trip.stops.length > 1 ? 's' : ''}: ${trip.stops.join(', ')}',
                    ),
                  ],

                  // Routes (via)
                  if (trip.via.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _SheetDetailRow(
                        icon: Icons.add_road_rounded,
                        text: 'Rutas: ${trip.via.join(', ')}'),
                  ],

                  // Badges
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _DetailBadge(
                          label: 'Mascotas',
                          icon: Icons.pets_rounded,
                          bg: AppColors.greenLight,
                          fg: AppColors.green,
                          active: trip.allowsPets),
                      _DetailBadge(
                          label: 'Pasa a buscar',
                          icon: Icons.home_rounded,
                          bg: const Color(0xFFEFF6FF),
                          fg: const Color(0xFF1D4ED8),
                          active: trip.picksUpAtDoor),
                      _DetailBadge(
                          label: 'Deja en destino',
                          icon: Icons.where_to_vote_rounded,
                          bg: const Color(0xFFF5F3FF),
                          fg: const Color(0xFF6D28D9),
                          active: trip.dropsOffAtDoor),
                    ],
                  ),

                  // Description
                  if (trip.description != null &&
                      trip.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Descripción',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    Text(trip.description!,
                        style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF64748B),
                            height: 1.5)),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // Seats / Passengers
                  Row(
                    children: [
                      const Text('Viajeros',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B))),
                      const Spacer(),
                      Text(
                        '${trip.seatsTaken}/${trip.availableSeats} ocupados',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (trip.acceptedPassengerNames.isNotEmpty)
                    Column(
                      children: [
                        for (int i = 0; i < trip.acceptedPassengerNames.length; i++)
                          InkWell(
                            onTap: () => showPublicProfile(
                                context, trip.acceptedPassengerIds[i]),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 2),
                              child: Row(
                                children: [
                                  _MiniAvatar(
                                    name: trip.acceptedPassengerNames[i],
                                    index: i,
                                    size: 42,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      trip.acceptedPassengerNames[i],
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B)),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary, size: 22),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        for (int i = 0; i < trip.freeSeats; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.inputBackground,
                              child: const Icon(Icons.person_outline,
                                  size: 18,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Text('Sin pasajeros aún',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  const SizedBox(height: 16),

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
                              fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _openRequests(context),
                icon: trip.pendingRequestsCount > 0
                    ? Badge(
                        label: Text('${trip.pendingRequestsCount}'),
                        child: const Icon(Icons.people_rounded,
                            color: Colors.white),
                      )
                    : const Icon(Icons.people_rounded, color: Colors.white),
                label: const Text('Ver solicitudes',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: trip.pendingRequestsCount > 0
                      ? Colors.orange.shade600
                      : AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetDetailRow extends StatelessWidget {
  const _SheetDetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF475569))),
        ),
      ],
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.active,
  });
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final bool active;

  static const _inactiveBg = Color(0xFFF1F5F9);
  static const _inactiveFg = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    final bgColor = active ? bg : _inactiveBg;
    final fgColor = active ? fg : _inactiveFg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fgColor),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: fgColor,
                fontWeight: FontWeight.w600,
                decoration: active ? null : TextDecoration.lineThrough,
                decorationColor: _inactiveFg,
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _OverlappingAvatars extends StatelessWidget {
  const _OverlappingAvatars({required this.names});
  final List<String> names;

  static const double _size = 28;
  static const double _overlap = 10;

  @override
  Widget build(BuildContext context) {
    final visible = names.take(3).toList();
    final extra = names.length - 3;
    final count = visible.length + (extra > 0 ? 1 : 0);
    final totalWidth = _size + (count - 1) * (_size - _overlap);

    return SizedBox(
      height: _size,
      width: totalWidth,
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * (_size - _overlap),
              child: _MiniAvatar(name: visible[i], index: i),
            ),
          if (extra > 0)
            Positioned(
              left: visible.length * (_size - _overlap),
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.name, required this.index, this.size = 28});
  final String name;
  final int index;
  final double size;

  static const _colors = [
    AppColors.primary,
    Color(0xFF10B981),
    Color(0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Passenger list bottom sheet ───────────────────────────────────────────

class _PassengerListSheet extends StatelessWidget {
  const _PassengerListSheet({required this.names, required this.ids});
  final List<String> names;
  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pasajeros aceptados',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < names.length; i++)
            InkWell(
              onTap: () {
                Navigator.pop(context);
                showPublicProfile(context, ids[i]);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    _MiniAvatar(name: names[i], index: i, size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        names[i],
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B)),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary, size: 22),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Trip requests bottom sheet ─────────────────────────────────────────────

class _TripRequestsSheet extends ConsumerStatefulWidget {
  const _TripRequestsSheet({required this.trip});
  final ActiveDriverTrip trip;

  @override
  ConsumerState<_TripRequestsSheet> createState() =>
      _TripRequestsSheetState();
}

class _TripRequestsSheetState extends ConsumerState<_TripRequestsSheet> {
  List<TripRequestEntry> _requests = [];
  bool _loading = true;
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final data = await ref
          .read(historyRepositoryProvider)
          .fetchPendingRequests(widget.trip.id);
      if (mounted) setState(() { _requests = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleAction(TripRequestEntry entry, bool accept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(accept ? '¿Aceptar solicitud?' : '¿Rechazar solicitud?'),
        content: Text(
          accept
              ? '¿Querés aceptar a ${entry.passengerName} en tu viaje?'
              : '¿Querés rechazar la solicitud de ${entry.passengerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: accept ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(accept ? 'Aceptar' : 'Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processing.add(entry.requestId));

    try {
      final repo = ref.read(historyRepositoryProvider);
      if (accept) {
        await repo.acceptRequest(entry.requestId);
      } else {
        await repo.declineRequest(entry.requestId);
      }

      setState(() {
        _requests.removeWhere((r) => r.requestId == entry.requestId);
        _processing.remove(entry.requestId);
      });

      // Refresh the active trips list to update badges/avatars
      ref.refresh(activeDriverTripsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept
                ? '${entry.passengerName} aceptado/a ✓'
                : 'Solicitud rechazada'),
            backgroundColor: accept ? Colors.green : Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      setState(() => _processing.remove(entry.requestId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),

            // Trip header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.originAddress} → ${trip.destinationAddress}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatDate(trip.departureDate) +
                              (trip.departureTime != null
                                  ? '  ·  ${trip.departureTime}'
                                  : ''),
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${trip.freeSeats}/${trip.availableSeats} libres',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),

            // Requests list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline_rounded,
                                  size: 52, color: AppColors.border),
                              SizedBox(height: 12),
                              Text('No hay solicitudes pendientes',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _RequestEntry(
                            entry: _requests[i],
                            isProcessing:
                                _processing.contains(_requests[i].requestId),
                            onAccept: () =>
                                _handleAction(_requests[i], true),
                            onDecline: () =>
                                _handleAction(_requests[i], false),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestEntry extends StatelessWidget {
  const _RequestEntry({
    required this.entry,
    required this.isProcessing,
    required this.onAccept,
    required this.onDecline,
  });

  final TripRequestEntry entry;
  final bool isProcessing;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passenger info row — tap avatar/name to see public profile
          Row(
            children: [
              GestureDetector(
                onTap: () => showPublicProfile(context, entry.passengerId),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    _initials(entry.passengerName),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => showPublicProfile(context, entry.passengerId),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.passengerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: AppColors.primary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFACC15)),
                        const SizedBox(width: 3),
                        Text(
                          entry.passengerRating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.passengerTrips} viaje${entry.passengerTrips != 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Seats requested badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${entry.seatsRequested} asiento${entry.seatsRequested > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          // Message
          if (entry.message != null && entry.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.message!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Buttons
          const SizedBox(height: 12),
          if (isProcessing)
            const Center(
                child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Rechazar',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Aceptar',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// DRIVER HISTORY TAB
// ══════════════════════════════════════════════════════════════════════════

class _DriverHistoryBody extends ConsumerWidget {
  const _DriverHistoryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(driverHistoryProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(
        child: Text('Error al cargar historial',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
      data: (trips) {
        if (trips.isEmpty) {
          return const _EmptyHistory(
            icon: Icons.history_rounded,
            message: 'Aún no tenés viajes completados.',
          );
        }

        final totalEarnings = trips.fold(0, (sum, t) => sum + t.earnings);
        final ratedTrips =
            trips.where((t) => t.avgTripRating != null).toList();
        final avgRating = ratedTrips.isEmpty
            ? 0.0
            : ratedTrips.fold(0.0, (s, t) => s + t.avgTripRating!) /
                ratedTrips.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: _StatCard(
                        icon: Icons.directions_car_rounded,
                        value: '${trips.length}',
                        label: 'Viajes')),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                        icon: Icons.star_rounded,
                        value: avgRating.toStringAsFixed(1),
                        label: 'Rating',
                        iconColor: const Color(0xFFFACC15))),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                        icon: Icons.emoji_events_rounded,
                        value:
                            '\$${(totalEarnings / 1000).toStringAsFixed(0)}k',
                        label: 'Ganado',
                        valueFontSize: 20)),
              ]),
              const SizedBox(height: 28),
              const Text('Viajes realizados',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ...trips.map((t) => _DriverTripCard(trip: t)),
            ],
          ),
        );
      },
    );
  }
}

class _DriverTripCard extends StatelessWidget {
  const _DriverTripCard({required this.trip});
  final DriverTripHistory trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(trip.originAddress,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('→',
                        style: TextStyle(
                            fontSize: 15,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600))),
                Flexible(
                    child: Text(trip.destinationAddress,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(_formatDate(trip.departureDate),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (trip.avgTripRating != null) ...[
              Row(children: [
                const Icon(Icons.star_rounded,
                    size: 16, color: Color(0xFFFACC15)),
                const SizedBox(width: 3),
                Text(trip.avgTripRating!.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 4),
            ],
            Text('+\$${_formatNum(trip.earnings)}',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
          ]),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.people_rounded,
              size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
              '${trip.passengers.length} pasajero${trip.passengers.length != 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _DriverTripDetailSheet(trip: trip),
            ),
            child: const Text('Ver detalles',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// PASSENGER HISTORY
// ══════════════════════════════════════════════════════════════════════════

class _PassengerHistoryBody extends ConsumerWidget {
  const _PassengerHistoryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(passengerHistoryProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(
        child: Text('Error al cargar historial',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
      data: (trips) {
        final pending = trips.where((t) => t.isPending).toList();
        final done = trips.where((t) => !t.isPending).toList();

        if (trips.isEmpty) {
          return const _EmptyHistory(
            icon: Icons.location_on_outlined,
            message: 'Aún no realizaste viajes como pasajero.',
          );
        }

        final totalSpent = done.fold(0, (s, t) => s + t.pricePerSeat);
        final avgRating = done.isEmpty
            ? 0.0
            : done.fold(0.0, (s, t) => s + t.driverRating) / done.length;

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(passengerHistoryProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Stats (solo viajes completados/aceptados)
              Row(children: [
                Expanded(
                    child: _StatCard(
                        icon: Icons.location_on_rounded,
                        value: '${done.length}',
                        label: 'Viajes')),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                        icon: Icons.star_rounded,
                        value: avgRating.toStringAsFixed(1),
                        label: 'Rating',
                        iconColor: const Color(0xFFFACC15))),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                        icon: Icons.attach_money_rounded,
                        value: '\$${(totalSpent / 1000).toStringAsFixed(0)}k',
                        label: 'Gastado',
                        valueFontSize: 20)),
              ]),

              // Solicitudes pendientes
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 28),
                Row(children: [
                  const Text('Esperando aprobación',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${pending.length}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E))),
                  ),
                ]),
                const SizedBox(height: 12),
                ...pending.map((t) => _PassengerTripCard(trip: t)),
              ],

              // Viajes realizados
              if (done.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text('Viajes realizados',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ...done.map((t) => _PassengerTripCard(trip: t)),
              ],

              if (done.isEmpty && pending.isEmpty)
                const _EmptyHistory(
                  icon: Icons.location_on_outlined,
                  message: 'Aún no realizaste viajes como pasajero.',
                ),
            ]),
          ),
        );
      },
    );
  }
}

class _PassengerTripCard extends StatelessWidget {
  const _PassengerTripCard({required this.trip});
  final PassengerTripHistory trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: trip.isPending ? const Color(0xFFFFFBEB) : AppColors.background,
        border: Border.all(
          color: trip.isPending ? const Color(0xFFFCD34D) : AppColors.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(trip.originAddress,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('→',
                        style: TextStyle(
                            fontSize: 15,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600))),
                Flexible(
                    child: Text(trip.destinationAddress,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 5),
              Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(_formatDate(trip.departureDate),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 4),
              Text('Conductor: ${trip.driverName}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              const Icon(Icons.star_rounded,
                  size: 16, color: Color(0xFFFACC15)),
              const SizedBox(width: 3),
              Text(trip.driverRating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ]),
            const SizedBox(height: 4),
            Text('\$${_formatNum(trip.pricePerSeat)}',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ]),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (trip.isPending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_top_rounded,
                        size: 13, color: Color(0xFF92400E)),
                    SizedBox(width: 4),
                    Text('Esperando aprobación',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E))),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 13, color: Color(0xFF166534)),
                    SizedBox(width: 4),
                    Text('Aceptado',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF166534))),
                  ],
                ),
              ),
          ],
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// DRIVER TRIP DETAIL SHEET (past trips)
// ══════════════════════════════════════════════════════════════════════════

class _DriverTripDetailSheet extends StatelessWidget {
  const _DriverTripDetailSheet({required this.trip});
  final DriverTripHistory trip;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${trip.originAddress} → ${trip.destinationAddress}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(_formatDate(trip.departureDate),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    if (trip.departureTime != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(trip.departureTime!,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ]),
                ]),
              ),
              if (trip.avgTripRating != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.star_rounded,
                        size: 18, color: Color(0xFFEAB308)),
                    const SizedBox(width: 4),
                    Text(trip.avgTripRating!.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF713F12))),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                _DetailSection(
                  icon: Icons.attach_money_rounded,
                  title: 'Resumen económico',
                  child: Row(children: [
                    Expanded(
                        child: _InfoTile(
                            label: 'Total ganado',
                            value: '+\$${_formatNum(trip.earnings)}',
                            valueColor: AppColors.primary,
                            valueFontSize: 20,
                            bold: true)),
                    Expanded(
                        child: _InfoTile(
                            label: 'Precio por asiento',
                            value: '\$${_formatNum(trip.pricePerSeat)}')),
                  ]),
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  icon: Icons.place_rounded,
                  title: 'Ruta',
                  child: _StopsTimeline(
                    origin: trip.originAddress,
                    destination: trip.destinationAddress,
                    stops: trip.via.isEmpty ? null : trip.via,
                  ),
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  icon: Icons.people_rounded,
                  title: 'Pasajeros (${trip.passengers.length})',
                  child: trip.passengers.isEmpty
                      ? const Text('Sin pasajeros registrados',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary))
                      : Column(
                          children: trip.passengers.map((p) {
                            final ini = p.name
                                .split(' ')
                                .take(2)
                                .map((w) => w[0])
                                .join();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(children: [
                                CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(ini,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary))),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(p.name,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary))),
                                Row(children: [
                                  const Icon(Icons.star_rounded,
                                      size: 14,
                                      color: Color(0xFFFACC15)),
                                  const SizedBox(width: 3),
                                  Text(p.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                ]),
                              ]),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: AppColors.border),
        const SizedBox(height: 16),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection(
      {required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3)),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _StopsTimeline extends StatefulWidget {
  const _StopsTimeline(
      {required this.origin, required this.destination, this.stops});
  final String origin;
  final String destination;
  final List<String>? stops;

  @override
  State<_StopsTimeline> createState() => _StopsTimelineState();
}

class _StopsTimelineState extends State<_StopsTimeline> {
  static const int _collapseThreshold = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final stops = widget.stops ?? <String>[];
    final shouldCollapse = stops.length > _collapseThreshold;
    final visibleStops =
        shouldCollapse && !_expanded ? stops.take(2).toList() : stops;
    final pts = [widget.origin, ...visibleStops, widget.destination];
    final hiddenCount = stops.length - 2;

    return Column(children: [
      for (int i = 0; i < pts.length; i++)
        _TimelineRow(
          label: pts[i],
          isFirst: i == 0,
          isLast: i == pts.length - 1,
          showLine: i < pts.length - 1,
          insertCollapsed:
              shouldCollapse && !_expanded && i == pts.length - 2,
          hiddenCount: hiddenCount,
          onExpand: () => setState(() => _expanded = true),
        ),
      if (shouldCollapse && _expanded)
        GestureDetector(
          onTap: () => setState(() => _expanded = false),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 6),
            child: Text('Ver menos',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500)),
          ),
        ),
    ]);
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.isFirst,
    required this.isLast,
    required this.showLine,
    this.insertCollapsed = false,
    this.hiddenCount = 0,
    this.onExpand,
  });
  final String label;
  final bool isFirst;
  final bool isLast;
  final bool showLine;
  final bool insertCollapsed;
  final int hiddenCount;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 20,
          child: Column(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: isFirst || isLast
                    ? AppColors.primary
                    : const Color(0xFFCBD5E1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: isFirst || isLast
                        ? AppColors.primary
                        : const Color(0xFF94A3B8),
                    width: 1.5),
              ),
            ),
            if (showLine)
              Expanded(
                  child: Container(
                      width: 2, color: const Color(0xFFE2E8F0))),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: isFirst || isLast
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: AppColors.textPrimary)),
              if (insertCollapsed) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onExpand,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('+ $hiddenCount paradas más',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontSize = 15,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final double valueFontSize;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
    this.valueFontSize = 24,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Icon(icon, size: 26, color: iconColor ?? AppColors.primary),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}
