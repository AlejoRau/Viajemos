import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/public_profile_sheet.dart';
import '../data/chat_repository.dart';

class ChatTripDetailSheet extends StatefulWidget {
  const ChatTripDetailSheet({
    super.key,
    required this.tripId,
    required this.isDriver,
    required this.chatRepo,
  });
  final String tripId;
  final bool isDriver;
  final ChatRepository chatRepo;

  @override
  State<ChatTripDetailSheet> createState() => _ChatTripDetailSheetState();
}

class _ChatTripDetailSheetState extends State<ChatTripDetailSheet> {
  ChatTripDetail? _detail;
  bool _loading = true;
  final Set<String> _expelling = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final detail = await widget.chatRepo.fetchChatTripDetail(widget.tripId);
    if (mounted) setState(() { _detail = detail; _loading = false; });
  }

  String _formatPrice(int p) => '\$${p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  Future<void> _expel(ChatTripPassenger passenger) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar pasajero?'),
        content: Text('¿Querés eliminar a ${passenger.name} del viaje?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _expelling.add(passenger.requestId));
    try {
      await widget.chatRepo.expelPassenger(passenger.requestId);
      if (!mounted) return;
      final d = _detail!;
      setState(() {
        _detail = ChatTripDetail(
          tripId: d.tripId,
          ownerId: d.ownerId,
          originAddress: d.originAddress,
          destinationAddress: d.destinationAddress,
          departureDate: d.departureDate,
          departureTime: d.departureTime,
          pricePerSeat: d.pricePerSeat,
          availableSeats: d.availableSeats,
          seatsTaken: d.seatsTaken - 1,
          allowsPets: d.allowsPets,
          picksUpAtDoor: d.picksUpAtDoor,
          dropsOffAtDoor: d.dropsOffAtDoor,
          via: d.via,
          stops: d.stops,
          vehicleBrand: d.vehicleBrand,
          vehicleModel: d.vehicleModel,
          vehicleColor: d.vehicleColor,
          description: d.description,
          passengers: d.passengers
              .where((p) => p.requestId != passenger.requestId)
              .toList(),
        );
        _expelling.remove(passenger.requestId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${passenger.name} fue eliminado/a del viaje')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _expelling.remove(passenger.requestId));
    }
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_detail == null)
            const Expanded(
              child: Center(
                child: Text('No se pudo cargar el viaje',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            Expanded(child: _buildContent(_detail!)),
        ],
      ),
    );
  }

  Widget _buildContent(ChatTripDetail trip) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Text(trip.formattedDate,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 4),

          // Route
          Row(children: [
            Flexible(
              child: Text(trip.originAddress,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B))),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, size: 15, color: AppColors.primary),
            ),
            Flexible(
              child: Text(trip.destinationAddress,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B))),
            ),
          ]),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Time
          _SheetRow(
            icon: Icons.access_time_rounded,
            text: trip.formattedTime.isNotEmpty
                ? '${trip.formattedDate}  ·  ${trip.formattedTime}'
                : trip.formattedDate,
          ),

          // Vehicle
          if (trip.vehicleDisplay.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SheetRow(
                icon: Icons.directions_car_rounded, text: trip.vehicleDisplay),
          ],

          // Stops
          if (trip.stops.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SheetRow(
              icon: Icons.add_location_alt_outlined,
              text:
                  '${trip.stops.length} parada${trip.stops.length > 1 ? 's' : ''}: ${trip.stops.join(', ')}',
            ),
          ],

          // Via
          if (trip.via.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SheetRow(
                icon: Icons.add_road_rounded,
                text: 'Rutas: ${trip.via.join(', ')}'),
          ],

          // Badges
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SheetBadge(
                  label: 'Mascotas',
                  icon: Icons.pets_rounded,
                  bg: const Color(0xFFDCFCE7),
                  fg: const Color(0xFF16A34A),
                  active: trip.allowsPets),
              _SheetBadge(
                  label: 'Pasa a buscar',
                  icon: Icons.home_rounded,
                  bg: const Color(0xFFEFF6FF),
                  fg: const Color(0xFF1D4ED8),
                  active: trip.picksUpAtDoor),
              _SheetBadge(
                  label: 'Deja en destino',
                  icon: Icons.where_to_vote_rounded,
                  bg: const Color(0xFFF5F3FF),
                  fg: const Color(0xFF6D28D9),
                  active: trip.dropsOffAtDoor),
            ],
          ),

          // Description
          if (trip.description != null && trip.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Descripción',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 6),
            Text(trip.description!,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF64748B), height: 1.5)),
          ],

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Passengers
          Row(children: [
            const Text('Viajeros',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
            const Spacer(),
            Text('${trip.seatsTaken}/${trip.availableSeats} ocupados',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 10),

          if (trip.passengers.isNotEmpty)
            Column(
              children: [
                for (int i = 0; i < trip.passengers.length; i++)
                  _buildPassengerRow(trip.passengers[i], i),
              ],
            )
          else
            const Text('Sin pasajeros aún',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary)),

          const SizedBox(height: 16),

          // Price
          Row(children: [
            Text(_formatPrice(trip.pricePerSeat),
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(width: 6),
            const Text('por asiento',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPassengerRow(ChatTripPassenger p, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        // Avatar — only driver can tap profile
        widget.isDriver
            ? GestureDetector(
                onTap: () => showPublicProfile(context, p.id),
                child: _avatarCircle(p, index))
            : _avatarCircle(p, index),
        const SizedBox(width: 12),
        Expanded(
          child: widget.isDriver
              ? GestureDetector(
                  onTap: () => showPublicProfile(context, p.id),
                  child: Row(children: [
                    Flexible(
                      child: Text(p.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B))),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.primary),
                  ]))
              : Text(p.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
        ),
        // Expel — only driver
        if (widget.isDriver)
          _expelling.contains(p.requestId)
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: const Icon(Icons.person_remove_rounded,
                      color: Colors.red, size: 20),
                  tooltip: 'Eliminar del viaje',
                  onPressed: () => _expel(p)),
      ]),
    );
  }

  Widget _avatarCircle(ChatTripPassenger p, int index) {
    const colors = [
      AppColors.primary,
      Color(0xFF10B981),
      Color(0xFFF59E0B),
    ];
    final color = colors[index % colors.length];
    if (p.avatarUrl != null && p.avatarUrl!.isNotEmpty) {
      return SizedBox(
        width: 42,
        height: 42,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: p.avatarUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initialsBox(p.name, color, 42),
            errorWidget: (_, __, ___) => _initialsBox(p.name, color, 42),
          ),
        ),
      );
    }
    return _initialsBox(p.name, color, 42);
  }

  Widget _initialsBox(String name, Color color, double size) {
    String ini(String n) {
      final parts = n.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return n.isNotEmpty ? n[0].toUpperCase() : '?';
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(ini(name),
          style: TextStyle(
              fontSize: size * 0.33,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
    ]);
  }
}

class _SheetBadge extends StatelessWidget {
  const _SheetBadge({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    this.active = true,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: fgColor),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              color: fgColor,
              fontWeight: FontWeight.w600,
              decoration: active ? null : TextDecoration.lineThrough,
              decorationColor: _inactiveFg,
            )),
      ]),
    );
  }
}
