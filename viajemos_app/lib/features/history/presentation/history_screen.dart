import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/role_provider.dart';
import '../../../shared/widgets/public_profile_sheet.dart';
import '../data/history_repository.dart';
import '../../driver/presentation/create_trip_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi historial de viajes'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: isDriver
              ? const [Tab(text: 'Mis viajes'), Tab(text: 'Historial')]
              : const [Tab(text: 'Mis solicitudes'), Tab(text: 'Historial')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: isDriver
            ? const [_ActiveTripsBody(), _DriverHistoryBody()]
            : const [_PassengerActiveRequestsBody(), _PassengerHistoryBody()],
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
  bool _togglingPrivacy = false;
  late bool _isPrivate;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.trip.isPrivate;
  }

  @override
  void didUpdateWidget(_ActiveTripCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trip.isPrivate != widget.trip.isPrivate) {
      _isPrivate = widget.trip.isPrivate;
    }
  }

  Future<void> _togglePrivacy() async {
    if (_togglingPrivacy) return;
    final newValue = !_isPrivate;

    // Confirm before making the trip private
    if (newValue) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '¿Hacer viaje privado?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            '¿Estás seguro que querés hacer privado tu viaje? Ya no lo mostraremos en la búsqueda de los usuarios.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Sí, hacer privado'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() {
      _isPrivate = newValue;
      _togglingPrivacy = true;
    });
    try {
      await ref.read(historyRepositoryProvider).toggleTripPrivacy(widget.trip.id, newValue);
      ref.refresh(activeDriverTripsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newValue ? 'Viaje marcado como privado' : 'Viaje marcado como público'),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPrivate = !newValue);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cambiar privacidad')),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingPrivacy = false);
    }
  }

  void _shareTrip() {
    final trip = widget.trip;
    final date = _formatDate(trip.departureDate);
    final time = trip.departureTime != null ? '  ·  ${trip.departureTime}' : '';
    final seats = trip.freeSeats;
    final text = '🚗 Viajemos: ${trip.originAddress} → ${trip.destinationAddress}\n'
        '📅 $date$time\n'
        '💺 $seats lugar${seats != 1 ? 'es' : ''} disponible${seats != 1 ? 's' : ''}\n'
        '💰 \$${_formatNum(trip.pricePerSeat)} por asiento\n\n'
        '¡Sumate al viaje!';
    Share.share(text);
  }

  void _showPassengerList(BuildContext context, List<String> names,
      List<String> ids, List<String> requestIds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PassengerListSheet(
        names: names,
        ids: ids,
        requestIds: requestIds,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final hasPassengers = widget.trip.acceptedPassengerNames.isNotEmpty;
    final msgController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasPassengers
                  ? '¿Seguro que querés cancelar el viaje '
                    '${widget.trip.originAddress} → ${widget.trip.destinationAddress}?\n\n'
                    'Tenés ${widget.trip.acceptedPassengerNames.length} pasajero(s) aceptado(s). '
                    'Esta cancelación quedará registrada en tu perfil.'
                  : '¿Seguro que querés cancelar el viaje '
                    '${widget.trip.originAddress} → ${widget.trip.destinationAddress}?',
            ),
            if (hasPassengers) ...[
              const SizedBox(height: 16),
              TextField(
                controller: msgController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText:
                      'Mensaje para los pasajeros (opcional)\nEj: Por motivos personales debo cancelar.',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar viaje'),
          ),
        ],
      ),
    );

    final message = msgController.text.trim();
    msgController.dispose();

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(historyRepositoryProvider).cancelTrip(
            widget.trip.id,
            message: message.isEmpty ? null : message,
          );
      ref.refresh(activeDriverTripsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viaje cancelado')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cancelar el viaje')),
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
                    ? Colors.green.shade400
                    : AppColors.border,
                width: hasPending ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: hasPending
                      ? Colors.green.withValues(alpha: 0.12)
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
                  // Header: ACTIVO badge + privacy badge + actions
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: trip.isFull
                              ? const Color(0xFFDBEAFE)
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
                                    ? const Color(0xFF2563EB)
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
                                    ? const Color(0xFF2563EB)
                                    : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isPrivate) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded,
                                  size: 10, color: Colors.orange.shade800),
                              const SizedBox(width: 3),
                              Text('PRIVADO',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange.shade800)),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Accepted passenger avatars (clickable)
                      if (trip.acceptedPassengerNames.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showPassengerList(
                            context,
                            trip.acceptedPassengerNames,
                            trip.acceptedPassengerIds,
                            trip.acceptedPassengerRequestIds,
                          ),
                          child: _OverlappingAvatars(
                            names: trip.acceptedPassengerNames,
                            avatarUrls: trip.acceptedPassengerAvatarUrls,
                          ),
                        ),
                      const SizedBox(width: 2),
                      // Privacy toggle button
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: _togglingPrivacy
                            ? Padding(
                                padding: const EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.orange.shade600),
                              )
                            : IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  _isPrivate
                                      ? Icons.lock_rounded
                                      : Icons.lock_open_rounded,
                                  size: 20,
                                  color: _isPrivate
                                      ? Colors.orange.shade700
                                      : AppColors.textSecondary,
                                ),
                                onPressed: _togglePrivacy,
                                tooltip: _isPrivate
                                    ? 'Privado – toca para abrir'
                                    : 'Público – toca para privatizar',
                              ),
                      ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: _RoutePlace(
                          city: trip.originAddress,
                          address: trip.originExactAddress,
                          dotColor: AppColors.primary,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 2, left: 6, right: 6),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 16, color: AppColors.primary),
                      ),
                      Flexible(
                        child: _RoutePlace(
                          city: trip.destinationAddress,
                          address: trip.destinationExactAddress,
                          dotColor: const Color(0xFF16A34A),
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

                  // CTA buttons
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _DriverTripDetailsSheet(
                                trip: trip, pageContext: context),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: hasPending
                                ? Colors.green.shade700
                                : AppColors.primary,
                            side: BorderSide(
                                color: hasPending
                                    ? Colors.green.shade400
                                    : AppColors.primary),
                            minimumSize: const Size(0, 42),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Ver detalles',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _shareTrip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 42),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.share_rounded, size: 15),
                              SizedBox(width: 6),
                              Text('Compartir',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
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

class _DriverTripDetailsSheet extends ConsumerStatefulWidget {
  const _DriverTripDetailsSheet({required this.trip, required this.pageContext});
  final ActiveDriverTrip trip;
  final BuildContext pageContext;

  @override
  ConsumerState<_DriverTripDetailsSheet> createState() =>
      _DriverTripDetailsSheetState();
}

class _DriverTripDetailsSheetState
    extends ConsumerState<_DriverTripDetailsSheet> {
  late List<String> _passengerNames;
  late List<String> _passengerIds;
  late List<String> _passengerRequestIds;
  final Set<String> _expelling = {};

  @override
  void initState() {
    super.initState();
    _passengerNames = List.from(widget.trip.acceptedPassengerNames);
    _passengerIds = List.from(widget.trip.acceptedPassengerIds);
    _passengerRequestIds = List.from(widget.trip.acceptedPassengerRequestIds);
  }

  ActiveDriverTrip get trip => widget.trip;
  BuildContext get pageContext => widget.pageContext;

  String _formatPrice(int p) => '\$${p.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  Future<void> _expelPassenger(BuildContext context, int index) async {
    final name = _passengerNames[index];
    final requestId = _passengerRequestIds[index];
    final msgController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar pasajero?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Querés eliminar a $name del viaje? '
                'Esto quedará registrado en tu historial.'),
            const SizedBox(height: 16),
            TextField(
              controller: msgController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Mensaje para el pasajero (opcional)\n'
                    'Ej: Hubo un cambio de planes.',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    final message = msgController.text.trim();
    msgController.dispose();

    if (confirmed != true || !mounted) return;

    setState(() => _expelling.add(requestId));
    try {
      await ref.read(historyRepositoryProvider).expelPassenger(
            requestId,
            message: message.isEmpty ? null : message,
          );
      if (!mounted) return;
      setState(() {
        _passengerNames.removeAt(index);
        _passengerIds.removeAt(index);
        _passengerRequestIds.removeAt(index);
        _expelling.remove(requestId);
      });
      ref.refresh(activeDriverTripsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name fue eliminado/a del viaje')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _expelling.remove(requestId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: _RoutePlace(
                          city: trip.originAddress,
                          address: trip.originExactAddress,
                          dotColor: AppColors.primary,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 2, left: 6, right: 6),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 16, color: AppColors.primary),
                      ),
                      Flexible(
                        child: _RoutePlace(
                          city: trip.destinationAddress,
                          address: trip.destinationExactAddress,
                          dotColor: const Color(0xFF16A34A),
                        ),
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
                  if (_passengerNames.isNotEmpty)
                    Column(
                      children: [
                        for (int i = 0; i < _passengerNames.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => showPublicProfile(
                                      context, _passengerIds[i]),
                                  borderRadius: BorderRadius.circular(21),
                                  child: _MiniAvatar(
                                    name: _passengerNames[i],
                                    index: i,
                                    size: 42,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => showPublicProfile(
                                        context, _passengerIds[i]),
                                    child: Text(
                                      _passengerNames[i],
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B)),
                                    ),
                                  ),
                                ),
                                if (_expelling.contains(_passengerRequestIds[i]))
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(
                                        Icons.person_remove_rounded,
                                        color: Colors.red,
                                        size: 20),
                                    tooltip: 'Eliminar del viaje',
                                    onPressed: () =>
                                        _expelPassenger(context, i),
                                  ),
                              ],
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
                      ? Colors.green.shade600
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
  const _OverlappingAvatars({required this.names, this.avatarUrls});
  final List<String> names;
  final List<String?> ? avatarUrls;

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
              child: _MiniAvatar(
                name: visible[i],
                avatarUrl: avatarUrls != null && i < avatarUrls!.length
                    ? avatarUrls![i]
                    : null,
                index: i,
              ),
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
  const _MiniAvatar({
    required this.name,
    required this.index,
    this.avatarUrl,
    this.size = 28,
  });
  final String name;
  final String? avatarUrl;
  final int index;
  final double size;

  static const _colors = [
    AppColors.primary,
    Color(0xFF10B981),
    Color(0xFFF59E0B),
  ];

  Widget _initialsWidget(Color color) => Container(
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

  @override
  Widget build(BuildContext context) {
    final color = _colors[index % _colors.length];
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initialsWidget(color),
            errorWidget: (_, __, ___) => _initialsWidget(color),
          ),
        ),
      );
    }
    return _initialsWidget(color);
  }
}

// ── Passenger list bottom sheet ───────────────────────────────────────────

class _PassengerListSheet extends ConsumerStatefulWidget {
  const _PassengerListSheet({
    required this.names,
    required this.ids,
    required this.requestIds,
  });
  final List<String> names;
  final List<String> ids;
  final List<String> requestIds;

  @override
  ConsumerState<_PassengerListSheet> createState() =>
      _PassengerListSheetState();
}

class _PassengerListSheetState extends ConsumerState<_PassengerListSheet> {
  late List<String> _names;
  late List<String> _ids;
  late List<String> _requestIds;
  final Set<String> _expelling = {};

  @override
  void initState() {
    super.initState();
    _names = List.from(widget.names);
    _ids = List.from(widget.ids);
    _requestIds = List.from(widget.requestIds);
  }

  Future<void> _expel(int index) async {
    final requestId = _requestIds[index];
    final name = _names[index];
    final msgController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar pasajero?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Querés eliminar a $name del viaje? '
                'Esto quedará registrado en tu historial.'),
            const SizedBox(height: 16),
            TextField(
              controller: msgController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Mensaje para el pasajero (opcional)\n'
                    'Ej: Hubo un cambio de planes.',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    final message = msgController.text.trim();
    msgController.dispose();

    if (confirmed != true || !mounted) return;

    setState(() => _expelling.add(requestId));
    try {
      await ref.read(historyRepositoryProvider).expelPassenger(
            requestId,
            message: message.isEmpty ? null : message,
          );
      if (!mounted) return;
      setState(() {
        _names.removeAt(index);
        _ids.removeAt(index);
        _requestIds.removeAt(index);
        _expelling.remove(requestId);
      });
      ref.refresh(activeDriverTripsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name fue eliminado/a del viaje')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _expelling.remove(requestId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _names.isEmpty
                    ? 'Sin pasajeros'
                    : 'Pasajeros aceptados (${_names.length})',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_names.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No quedan pasajeros en este viaje.',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            for (int i = 0; i < _names.length; i++) ...[
              const Divider(height: 1, indent: 20, endIndent: 20),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => showPublicProfile(context, _ids[i]),
                      borderRadius: BorderRadius.circular(22),
                      child: _MiniAvatar(name: _names[i], index: i, size: 44),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => showPublicProfile(context, _ids[i]),
                        child: Text(
                          _names[i],
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B)),
                        ),
                      ),
                    ),
                    if (_expelling.contains(_requestIds[i]))
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.person_remove_rounded,
                            color: Colors.red, size: 22),
                        tooltip: 'Eliminar del viaje',
                        onPressed: () => _expel(i),
                      ),
                  ],
                ),
              ),
            ],
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
      builder: (ctx) => AlertDialog(
        title: Text(accept ? '¿Aceptar solicitud?' : '¿Rechazar solicitud?'),
        content: Text(
          accept
              ? '¿Querés aceptar a ${entry.passengerName} en tu viaje?'
              : '¿Querés rechazar la solicitud de ${entry.passengerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: accept ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
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
                child: _MiniAvatar(
                  name: entry.passengerName,
                  avatarUrl: entry.passengerAvatarUrl,
                  index: 0,
                  size: 44,
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
// PASSENGER ACTIVE REQUESTS TAB
// ══════════════════════════════════════════════════════════════════════════

class _PassengerActiveRequestsBody extends ConsumerWidget {
  const _PassengerActiveRequestsBody();

  Widget _limitWarning(String text) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF9C3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFACC15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                size: 16, color: Color(0xFF713F12)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF713F12))),
            ),
          ],
        ),
      );

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.4),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRequests = ref.watch(passengerActiveRequestsProvider);
    final asyncAlerts = ref.watch(myTripAlertsProvider);

    final isLoading = asyncRequests.isLoading || asyncAlerts.isLoading;
    final hasError = asyncRequests.hasError || asyncAlerts.hasError;

    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (hasError) {
      return const Center(
        child: Text('Error al cargar datos',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final requests = asyncRequests.value ?? [];
    final alerts = asyncAlerts.value ?? [];
    final bothEmpty = requests.isEmpty && alerts.isEmpty;

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(passengerActiveRequestsProvider);
        ref.refresh(myTripAlertsProvider);
      },
      child: bothEmpty
          ? const _EmptyHistory(
              icon: Icons.send_rounded,
              message: 'No tenés solicitudes ni pedidos activos.\n'
                  'Podés tener hasta 3 solicitudes y 2 pedidos a la vez.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // ── Pedidos de viaje section ──
                if (alerts.isNotEmpty) ...[
                  _sectionHeader('MIS PEDIDOS DE VIAJE'),
                  if (alerts.length >= 2)
                    _limitWarning(
                        'Alcanzaste el límite de 2 pedidos activos.'),
                  ...alerts.map((a) => _MyTripAlertCard(alert: a)),
                  const SizedBox(height: 8),
                ],

                // ── Solicitudes section ──
                if (requests.isNotEmpty) ...[
                  _sectionHeader('MIS SOLICITUDES'),
                  if (requests.length >= 3)
                    _limitWarning(
                        'Alcanzaste el límite de 3 solicitudes activas.'),
                  ...requests.map(
                      (r) => _ActivePassengerRequestCard(request: r)),
                ],
              ],
            ),
    );
  }
}

// ── My trip alert card (pedido de viaje) ─────────────────────────────────────

class _MyTripAlertCard extends ConsumerStatefulWidget {
  const _MyTripAlertCard({required this.alert});
  final MyTripAlert alert;

  @override
  ConsumerState<_MyTripAlertCard> createState() => _MyTripAlertCardState();
}

class _MyTripAlertCardState extends ConsumerState<_MyTripAlertCard> {
  bool _deleting = false;

  Future<void> _confirmDeactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar pedido'),
        content: Text(
          '¿Querés desactivar el pedido '
          '${widget.alert.originAddress} → ${widget.alert.destinationAddress}?\n\n'
          'Las ofertas pendientes serán rechazadas automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(historyRepositoryProvider)
          .deactivateAlert(widget.alert.id);
      if (mounted) {
        ref.refresh(myTripAlertsProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final hasOffers = alert.hasInvitations;

    String formatDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasOffers
              ? const Color(0xFFF97316).withValues(alpha: 0.5)
              : AppColors.border,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasOffers
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasOffers) ...[
                      const Icon(Icons.local_offer_rounded,
                          size: 11, color: Color(0xFFF97316)),
                      const SizedBox(width: 4),
                      Text(
                        '${alert.pendingInvitations} OFERTA${alert.pendingInvitations > 1 ? 'S' : ''}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF97316)),
                      ),
                    ] else ...[
                      const Text(
                        'ACTIVO',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              // Delete button
              if (_deleting)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                GestureDetector(
                  onTap: _confirmDeactivate,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: Colors.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Route
          Row(
            children: [
              const Icon(Icons.trip_origin_rounded,
                  size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  alert.originAddress,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 2, bottom: 2),
            child: Container(
                width: 1, height: 10, color: AppColors.textSecondary),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  alert.destinationAddress,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Chips row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.calendar_today_rounded,
                label:
                    '${formatDate(alert.dateFrom)} – ${formatDate(alert.dateTo)}',
              ),
              _InfoChip(
                icon: Icons.people_rounded,
                label:
                    '${alert.seatsNeeded} asiento${alert.seatsNeeded > 1 ? 's' : ''}',
              ),
              if (alert.maxPrice != null)
                _InfoChip(
                  icon: Icons.attach_money_rounded,
                  label: 'Hasta \$${_formatNum(alert.maxPrice!)}',
                ),
              if (!alert.timeFlexible &&
                  alert.departureTime != null)
                _InfoChip(
                  icon: Icons.access_time_rounded,
                  label: alert.departureTimeTo != null
                      ? '${alert.departureTime} – ${alert.departureTimeTo}'
                      : alert.departureTime!,
                ),
            ],
          ),

          // Description
          if (alert.description != null &&
              alert.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              alert.description!,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Offers hint
          if (hasOffers) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFF97316).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      size: 14, color: Color(0xFFF97316)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tenés ${alert.pendingInvitations} oferta${alert.pendingInvitations > 1 ? 's' : ''} de conductores esperando tu respuesta en el chat.',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Active passenger request card ─────────────────────────────────────────

class _ActivePassengerRequestCard extends ConsumerStatefulWidget {
  const _ActivePassengerRequestCard({required this.request});
  final ActivePassengerRequest request;

  @override
  ConsumerState<_ActivePassengerRequestCard> createState() =>
      _ActivePassengerRequestCardState();
}

class _ActivePassengerRequestCardState
    extends ConsumerState<_ActivePassengerRequestCard> {
  bool _cancelling = false;

  void _shareRequest() {
    final req = widget.request;
    final date = _formatDate(req.departureDate);
    final time = req.departureTime != null ? '  ·  ${req.departureTime}' : '';
    final text = '🚗 Viajemos: ${req.originAddress} → ${req.destinationAddress}\n'
        '📅 $date$time\n'
        '💰 \$${_formatNum(req.pricePerSeat)} por asiento\n'
        '🚘 ${req.driverName}\n\n'
        '¡Encontré este viaje en Viajemos!';
    Share.share(text);
  }

  Future<void> _confirmCancel() async {
    final req = widget.request;
    final isAccepted = req.isAccepted;
    final msgController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            isAccepted ? 'Cancelar viaje aceptado' : 'Cancelar solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAccepted
                  ? '¿Seguro que querés cancelar el viaje '
                      '${req.originAddress} → ${req.destinationAddress}?\n\n'
                      'Esta cancelación quedará registrada en tu perfil.'
                  : '¿Querés retirar tu solicitud para el viaje '
                      '${req.originAddress} → ${req.destinationAddress}?',
            ),
            if (isAccepted) ...[
              const SizedBox(height: 16),
              TextField(
                controller: msgController,
                maxLines: 2,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Motivo (opcional)',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isAccepted ? 'Cancelar viaje' : 'Retirar solicitud'),
          ),
        ],
      ),
    );

    msgController.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ref
          .read(historyRepositoryProvider)
          .cancelPassengerRequest(req.id);
      ref.refresh(passengerActiveRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isAccepted
                  ? 'Viaje cancelado'
                  : 'Solicitud retirada')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cancelar')),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PassengerRequestDetailSheet(request: req),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: status badge + driver avatar + delete button
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: req.isPending
                          ? const Color(0xFFF1F5F9)
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
                            color: req.isPending
                                ? const Color(0xFF94A3B8)
                                : Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          req.isPending ? 'PENDIENTE' : 'ACEPTADO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: req.isPending
                                ? const Color(0xFF64748B)
                                : Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Driver mini avatar
                  _MiniAvatar(
                      name: req.driverName,
                      avatarUrl: req.driverAvatarUrl,
                      index: 0),
                  const SizedBox(width: 4),
                  // Delete / cancel button
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: _cancelling
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.red),
                          )
                        : IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.red),
                            onPressed: _confirmCancel,
                            tooltip: req.isPending
                                ? 'Retirar solicitud'
                                : 'Cancelar viaje',
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
                      req.originAddress,
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
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 15, color: AppColors.primary),
                  ),
                  Flexible(
                    child: Text(
                      req.destinationAddress,
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
                      label: _formatDate(req.departureDate)),
                  if (req.departureTime != null)
                    _InfoChip(
                        icon: Icons.access_time_rounded,
                        label: req.departureTime!),
                  _InfoChip(
                      icon: Icons.event_seat_rounded,
                      label: '${req.seatsRequested} asiento${req.seatsRequested > 1 ? 's' : ''}'),
                ],
              ),
              const SizedBox(height: 10),

              // Price + driver name
              Row(
                children: [
                  Text(
                    '\$${_formatNum(req.pricePerSeat)} por asiento',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.person_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      req.driverName,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // CTA buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            _PassengerRequestDetailSheet(request: req),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade400),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ver detalles',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareRequest,
                      icon: const Icon(Icons.share_rounded, size: 15),
                      label: const Text('Compartir',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Passenger request detail sheet (active requests) ──────────────────────

class _PassengerRequestDetailSheet extends StatelessWidget {
  const _PassengerRequestDetailSheet({required this.request});
  final ActivePassengerRequest request;

  @override
  Widget build(BuildContext context) {
    final req = request;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${req.originAddress} → ${req.destinationAddress}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(_formatDate(req.departureDate),
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                        if (req.departureTime != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.access_time_rounded,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(req.departureTime!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ]),
                    ]),
              ),
              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: req.isPending
                      ? const Color(0xFFF1F5F9)
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  req.isPending ? 'PENDIENTE' : 'ACEPTADO',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: req.isPending
                          ? const Color(0xFF64748B)
                          : Colors.green.shade800),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                _DetailSection(
                  icon: Icons.person_rounded,
                  title: 'Conductor',
                  child: Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: req.driverAvatarUrl != null
                          ? NetworkImage(req.driverAvatarUrl!)
                          : null,
                      child: req.driverAvatarUrl == null
                          ? Text(_initials(req.driverName),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(req.driverName,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: Color(0xFFFACC15)),
                              const SizedBox(width: 3),
                              Text(req.driverRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                            ]),
                          ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  icon: Icons.attach_money_rounded,
                  title: 'Precio',
                  child: Row(children: [
                    Expanded(
                        child: _InfoTile(
                            label: 'Por asiento',
                            value: '\$${_formatNum(req.pricePerSeat)}')),
                    Expanded(
                        child: _InfoTile(
                            label: 'Asientos solicitados',
                            value: '${req.seatsRequested}')),
                    Expanded(
                        child: _InfoTile(
                            label: 'Total',
                            value:
                                '\$${_formatNum(req.pricePerSeat * req.seatsRequested)}',
                            valueColor: AppColors.primary,
                            bold: true)),
                  ]),
                ),
                if (req.vehicleDisplay.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    icon: Icons.directions_car_rounded,
                    title: 'Vehículo',
                    child: Text(req.vehicleDisplay,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary)),
                  ),
                ],
              ],
            ),
          ),
        ]),
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
    final activeAsync = ref.watch(activeDriverTripsProvider);
    final historyAsync = ref.watch(driverHistoryProvider);

    final isLoading = activeAsync.isLoading || historyAsync.isLoading;
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final activeTrips = activeAsync.valueOrNull ?? [];
    final completedTrips = historyAsync.valueOrNull ?? [];

    if (activeTrips.isEmpty && completedTrips.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          ref.refresh(activeDriverTripsProvider);
          ref.refresh(driverHistoryProvider);
        },
        child: const _EmptyHistory(
          icon: Icons.history_rounded,
          message: 'Aún no tenés viajes creados.',
        ),
      );
    }

    final totalEarnings =
        completedTrips.fold(0, (sum, t) => sum + t.earnings);
    final ratedTrips =
        completedTrips.where((t) => t.avgTripRating != null).toList();
    final avgRating = ratedTrips.isEmpty
        ? 0.0
        : ratedTrips.fold(0.0, (s, t) => s + t.avgTripRating!) /
            ratedTrips.length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(activeDriverTripsProvider);
        ref.refresh(driverHistoryProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats (only when there are completed trips) ──────────────
            if (completedTrips.isNotEmpty) ...[
              Row(children: [
                Expanded(
                    child: _StatCard(
                        icon: Icons.directions_car_rounded,
                        value: '${completedTrips.length}',
                        label: 'Completados')),
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
            ],

            // ── Upcoming / active trips ───────────────────────────────────
            if (activeTrips.isNotEmpty) ...[
              const Text('Próximos',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ...activeTrips.map((t) => _ActiveTripHistoryCard(trip: t)),
              const SizedBox(height: 24),
            ],

            // ── Completed trips ───────────────────────────────────────────
            if (completedTrips.isNotEmpty) ...[
              const Text('Realizados',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ...completedTrips.map((t) => _DriverTripCard(trip: t)),
            ],
          ],
        ),
      ),
    );
  }
}

// Lightweight read-only card for an upcoming (active) trip shown in history tab
class _ActiveTripHistoryCard extends StatelessWidget {
  const _ActiveTripHistoryCard({required this.trip});
  final ActiveDriverTrip trip;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${trip.departureDate.day.toString().padLeft(2, '0')}/${trip.departureDate.month.toString().padLeft(2, '0')}/${trip.departureDate.year}';
    final timeStr = trip.departureTime ?? '';
    final statusColor =
        trip.isFull ? const Color(0xFFDC2626) : AppColors.primary;
    final statusLabel = trip.isFull ? 'Completo' : 'Activo';
    final statusBg =
        trip.isFull ? const Color(0xFFFEE2E2) : AppColors.primaryLight;

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
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Flexible(
                  child: Text(trip.originAddress,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 15, color: AppColors.primary)),
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
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                if (timeStr.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(timeStr,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8)),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor)),
          ),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.people_rounded,
              size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
              '${trip.seatsTaken}/${trip.availableSeats} asientos ocupados',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text('+\$${_formatNum(trip.pricePerSeat * trip.seatsTaken)}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
        ]),
      ]),
    );
  }
}

class _DriverTripCard extends StatefulWidget {
  const _DriverTripCard({required this.trip});
  final DriverTripHistory trip;

  @override
  State<_DriverTripCard> createState() => _DriverTripCardState();
}

class _DriverTripCardState extends State<_DriverTripCard> {
  bool _repeating = false;

  Future<void> _repeatTrip() async {
    setState(() => _repeating = true);
    try {
      final raw =
          await HistoryRepository().fetchTripForRepeat(widget.trip.id);
      if (!mounted) return;
      final prefill = raw == null
          ? null
          : CreateTripPrefill(
              originAddress: raw['origin_address'] as String,
              destinationAddress: raw['destination_address'] as String,
              via: (raw['via'] as List?)?.cast<String>() ?? [],
              stops: (raw['stops'] as List?)?.cast<String>() ?? [],
              allowsPets: raw['allows_pets'] as bool? ?? false,
              picksUpAtDoor: raw['picks_up_at_door'] as bool? ?? false,
              dropsOffAtDoor: raw['drops_off_at_door'] as bool? ?? false,
              departureTime: _trimTime(raw['departure_time']),
              description: raw['description'] as String?,
              vehicleId: raw['vehicle_id'] as String?,
            );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CreateTripScreen(prefill: prefill)),
      );
    } finally {
      if (mounted) setState(() => _repeating = false);
    }
  }

  String? _trimTime(dynamic v) {
    final s = v as String?;
    if (s == null || s.length < 5) return null;
    return s.substring(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
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
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Flexible(
                    child: Text(trip.originAddress,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis)),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 15, color: AppColors.primary)),
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
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _DriverTripDetailSheet(trip: trip),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ver detalles',
                  style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _repeating ? null : _repeatTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _repeating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Repetir viaje',
                      style: TextStyle(fontSize: 13)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// PASSENGER HISTORY TAB (completed trips only)
// ══════════════════════════════════════════════════════════════════════════

class _PassengerHistoryBody extends ConsumerWidget {
  const _PassengerHistoryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(passengerCompletedTripsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(
        child: Text('Error al cargar historial',
            style: TextStyle(color: AppColors.textSecondary)),
      ),
      data: (trips) {
        if (trips.isEmpty) {
          return const _EmptyHistory(
            icon: Icons.location_on_outlined,
            message: 'Aún no realizaste viajes como pasajero.',
          );
        }

        final totalSpent = trips.fold(0, (s, t) => s + t.pricePerSeat);
        final ratedDrivers =
            trips.where((t) => t.driverRating > 0).toList();
        final avgRating = ratedDrivers.isEmpty
            ? 0.0
            : ratedDrivers.fold(0.0, (s, t) => s + t.driverRating) /
                ratedDrivers.length;

        return RefreshIndicator(
          onRefresh: () async =>
              ref.refresh(passengerCompletedTripsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  Row(children: [
                    Expanded(
                        child: _StatCard(
                            icon: Icons.location_on_rounded,
                            value: '${trips.length}',
                            label: 'Viajes')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _StatCard(
                            icon: Icons.star_rounded,
                            value: avgRating.toStringAsFixed(1),
                            label: 'Rating cond.',
                            iconColor: const Color(0xFFFACC15))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _StatCard(
                            icon: Icons.attach_money_rounded,
                            value:
                                '\$${(totalSpent / 1000).toStringAsFixed(0)}k',
                            label: 'Gastado',
                            valueFontSize: 20)),
                  ]),
                  const SizedBox(height: 28),
                  const Text('Viajes realizados',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ...trips.map((t) => _PassengerCompletedTripCard(trip: t)),
                ]),
          ),
        );
      },
    );
  }
}

// ── Passenger completed trip card (mirrors _DriverTripCard) ───────────────

class _PassengerCompletedTripCard extends ConsumerWidget {
  const _PassengerCompletedTripCard({required this.trip});
  final PassengerCompletedTrip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                    child: Text(trip.originAddress,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis)),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 15, color: AppColors.primary)),
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
            Text('-\$${_formatNum(trip.pricePerSeat)}',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ]),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 10),
        Row(children: [
          // Driver name + rating already-done badge
          const Icon(Icons.person_rounded,
              size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(
              child: Text(trip.driverName,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis)),
          if (trip.hasRated)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded,
                    size: 12, color: Color(0xFFEAB308)),
                const SizedBox(width: 3),
                Text('${trip.myRating}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF713F12))),
              ]),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _PassengerCompletedTripDetailSheet(
                  trip: trip,
                  onRated: () =>
                      ref.refresh(passengerCompletedTripsProvider)),
            ),
            child: const Text('Ver detalles',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          if (!trip.hasRated) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _PassengerCompletedTripDetailSheet(
                      trip: trip,
                      onRated: () =>
                          ref.refresh(passengerCompletedTripsProvider)),
                ),
                icon: const Icon(Icons.star_rounded, size: 15),
                label: const Text('Mi opinión',
                    style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF9C3),
                  foregroundColor: const Color(0xFF92400E),
                  minimumSize: const Size(0, 40),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.push(
                '/passenger/search-results',
                extra: {
                  'origin': trip.originAddress,
                  'destination': trip.destinationAddress,
                },
              ),
              icon: const Icon(Icons.search_rounded, size: 15),
              label: const Text('Buscar viaje',
                  style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Passenger completed trip detail sheet ────────────────────────────────

class _PassengerCompletedTripDetailSheet extends StatelessWidget {
  const _PassengerCompletedTripDetailSheet(
      {required this.trip, required this.onRated});
  final PassengerCompletedTrip trip;
  final VoidCallback onRated;

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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${trip.originAddress} → ${trip.destinationAddress}',
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
                                fontSize: 13,
                                color: AppColors.textSecondary)),
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
              if (trip.hasRated)
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
                    Text('${trip.myRating}',
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
                            label: 'Total pagado',
                            value: '-\$${_formatNum(trip.pricePerSeat)}',
                            valueColor: AppColors.textPrimary,
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
                  icon: Icons.person_rounded,
                  title: 'Conductor',
                  child: Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: trip.driverAvatarUrl != null
                          ? NetworkImage(trip.driverAvatarUrl!)
                          : null,
                      child: trip.driverAvatarUrl == null
                          ? Text(_initials(trip.driverName),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(trip.driverName,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: Color(0xFFFACC15)),
                              const SizedBox(width: 3),
                              Text(trip.driverRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                            ]),
                          ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                // Rate driver button
                if (!trip.hasRated)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final rated = await showDialog<bool>(
                        context: context,
                        builder: (_) => _RateDriverDialog(trip: trip),
                      );
                      if (rated == true) {
                        onRated();
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: const Text('Calificar conductor'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Text(
                          'Calificaste este viaje con ${trip.myRating} estrella${trip.myRating == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF15803D)),
                        ),
                      ],
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

// ── Rate driver dialog ─────────────────────────────────────────────────────

class _RateDriverDialog extends ConsumerStatefulWidget {
  const _RateDriverDialog({required this.trip});
  final PassengerCompletedTrip trip;

  @override
  ConsumerState<_RateDriverDialog> createState() => _RateDriverDialogState();
}

class _RateDriverDialogState extends ConsumerState<_RateDriverDialog> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) return;
    setState(() => _submitting = true);
    try {
      await ref.read(historyRepositoryProvider).submitDriverReview(
            tripId: widget.trip.tripId,
            driverId: widget.trip.driverId,
            rating: _selectedRating,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar la calificación')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calificar conductor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calificá a ${widget.trip.driverName} por el viaje del '
            '${_formatDate(widget.trip.departureDate)}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          // Star selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    _selectedRating >= star
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 36,
                    color: _selectedRating >= star
                        ? const Color(0xFFEAB308)
                        : AppColors.border,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText: 'Dejá un comentario (opcional)',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: (_selectedRating == 0 || _submitting) ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Enviar'),
        ),
      ],
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

class _RoutePlace extends StatelessWidget {
  const _RoutePlace({
    required this.city,
    required this.dotColor,
    this.address,
  });

  final String city;
  final String? address;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          city,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (address != null && address!.isNotEmpty && address != city)
          Text(
            address!,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
