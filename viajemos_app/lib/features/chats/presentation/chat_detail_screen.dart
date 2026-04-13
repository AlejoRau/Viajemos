import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/badge_providers.dart';
import '../data/chat_repository.dart';
import 'chat_trip_detail_sheet.dart';

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.substring(0, min(2, name.length)).toUpperCase();
}

String _formatTime(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String contactName;
  final String? contactId;
  final String? tripId;
  final bool isGroupChat;
  final int participantsCount;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.contactName,
    this.contactId,
    this.tripId,
    this.isGroupChat = false,
    this.participantsCount = 2,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatRepo = ChatRepository();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  PendingRequestInfo? _pendingRequest;
  bool _bannerDismissed = false;
  bool _processingRequest = false;
  AcceptedTripInfo? _tripInfo;

  // Invitation (driver → passenger)
  PendingInvitationInfo? _pendingInvitation;
  bool _invitationBannerDismissed = false;
  bool _processingInvitation = false;

  // Group chat
  List<GroupParticipant> _groupParticipants = [];
  // Maps userId → displayName for quick lookup in message bubbles
  Map<String, String> _participantNames = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribe();
    if (widget.isGroupChat) {
      _loadGroupParticipants();
    } else {
      if (widget.contactId != null) {
        _loadPendingRequest();
        _loadPendingInvitation();
      }
      if (widget.tripId != null) {
        _loadTripInfo();
      }
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await _chatRepo.fetchMessages(widget.chatId);
      if (mounted) {
        setState(() {
          // Store newest-first so index 0 = newest.
          // With reverse:true, index 0 is always at the bottom — no scroll needed.
          _messages = msgs; // DB returns newest-first (descending default)
          _loading = false;
        });
        _chatRepo.markAsRead(widget.chatId);
        ref.read(unreadCountProvider.notifier).refresh();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPendingRequest() async {
    try {
      final req =
          await _chatRepo.fetchPendingRequestForContact(widget.contactId!);
      if (mounted) setState(() => _pendingRequest = req);
    } catch (_) {}
  }

  Future<void> _loadPendingInvitation() async {
    try {
      final inv =
          await _chatRepo.fetchPendingInvitationFromContact(widget.contactId!);
      if (mounted) setState(() => _pendingInvitation = inv);
    } catch (_) {}
  }

  Future<void> _loadTripInfo() async {
    final info = await _chatRepo.fetchTripInfo(widget.tripId!);
    if (mounted && info != null) setState(() => _tripInfo = info);
  }

  Future<void> _loadGroupParticipants() async {
    try {
      final participants = await _chatRepo.fetchGroupParticipants(widget.chatId);
      if (mounted) {
        setState(() {
          _groupParticipants = participants;
          _participantNames = {for (final p in participants) p.userId: p.fullName};
        });
      }
    } catch (_) {}
  }

  void _showGroupMembers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupMembersSheet(
        participants: _groupParticipants,
        onRefresh: _loadGroupParticipants,
      ),
    );
  }

  void _subscribe() {
    _channel = _chatRepo.subscribeToMessages(widget.chatId, (msg) {
      if (mounted) {
        setState(() => _messages.insert(0, msg));
        _chatRepo.markAsRead(widget.chatId);
        ref.read(unreadCountProvider.notifier).refresh();
      }
    });
  }

  void _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    // Optimistic update: show message immediately
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final myId = Supabase.instance.client.auth.currentUser!.id;
    final optimistic = ChatMessage(
      id: tempId,
      conversationId: widget.chatId,
      senderId: myId,
      content: text,
      createdAt: DateTime.now(),
      isMine: true,
    );
    setState(() => _messages.insert(0, optimistic));

    try {
      await _chatRepo.sendMessage(widget.chatId, text);
    } catch (_) {
      // Revert optimistic update on failure
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m.id == tempId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar el mensaje')),
        );
      }
    }
  }

  Future<void> _handleRequest(bool accept) async {
    if (_pendingRequest == null || _processingRequest) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(accept ? 'Aceptar solicitud' : 'Rechazar solicitud'),
        content: Text(accept
            ? '¿Confirmás que querés aceptar esta solicitud?'
            : '¿Confirmás que querés rechazar esta solicitud?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              accept ? 'Aceptar' : 'Rechazar',
              style: TextStyle(
                  color: accept ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processingRequest = true);
    try {
      if (accept) {
        await _chatRepo.acceptRequest(_pendingRequest!.requestId);
      } else {
        await _chatRepo.declineRequest(_pendingRequest!.requestId);
      }
      if (mounted) {
        setState(() {
          _pendingRequest = null;
          _bannerDismissed = true;
          _processingRequest = false;
        });
        ref.read(pendingRequestsCountProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(accept ? 'Solicitud aceptada' : 'Solicitud rechazada'),
          backgroundColor: accept ? Colors.green : Colors.red,
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _processingRequest = false);
    }
  }

  Future<void> _handleInvitation(bool accept) async {
    if (_pendingInvitation == null || _processingInvitation) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(accept ? 'Aceptar oferta' : 'Rechazar oferta'),
        content: Text(accept
            ? '¿Confirmás que querés aceptar esta oferta de viaje?'
            : '¿Confirmás que querés rechazar esta oferta de viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: accept ? Colors.green : Colors.red),
            child: Text(accept ? 'Aceptar' : 'Rechazar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processingInvitation = true);
    try {
      if (accept) {
        await _chatRepo.acceptInvitation(_pendingInvitation!.invitationId);
      } else {
        await _chatRepo.declineInvitation(_pendingInvitation!.invitationId);
      }
      if (mounted) {
        setState(() {
          _pendingInvitation = null;
          _invitationBannerDismissed = true;
          _processingInvitation = false;
        });
        // Refresh the trip info card if accepted
        if (accept && widget.tripId != null) _loadTripInfo();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(accept ? 'Oferta aceptada' : 'Oferta rechazada'),
          backgroundColor: accept ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processingInvitation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBanner =
        _pendingRequest != null && !_bannerDismissed;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.appBarDivider, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.isGroupChat
            ? GestureDetector(
                onTap: _showGroupMembers,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFEDE9FE),
                      child: Icon(Icons.groups_rounded,
                          size: 20, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.contactName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_groupParticipants.isEmpty ? widget.participantsCount : _groupParticipants.length} integrantes · Ver',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      _initials(widget.contactName),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tripInfo != null
                        ? Text(
                            '${widget.contactName} · ${_tripInfo!.originCity}→${_tripInfo!.destinationCity} ${_tripInfo!.shortDate}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            widget.contactName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          if (showBanner) _RequestBanner(
            request: _pendingRequest!,
            processing: _processingRequest,
            onAccept: () => _handleRequest(true),
            onDecline: () => _handleRequest(false),
            onDismiss: () => setState(() => _bannerDismissed = true),
          ),
          if (_pendingInvitation != null && !_invitationBannerDismissed)
            _InvitationBanner(
              invitation: _pendingInvitation!,
              processing: _processingInvitation,
              onAccept: () => _handleInvitation(true),
              onDecline: () => _handleInvitation(false),
              onDismiss: () =>
                  setState(() => _invitationBannerDismissed = true),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay mensajes aún.\n¡Enviá el primero!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _messages.length + (_tripInfo != null ? 1 : 0),
                        itemBuilder: (context, i) {
                          // _messages is newest-first, so _messages[0] = newest.
                          // reverse:true puts i=0 at the bottom of the screen.
                          // Therefore: newest message always sits at the bottom,
                          // no scroll controller logic needed.
                          // TripInfoCard at the last index = visible at the very
                          // top when the user scrolls up through history.
                          if (_tripInfo != null && i == _messages.length) {
                            final myId = Supabase.instance.client.auth.currentUser?.id ?? '';
                            return _TripInfoCard(
                              trip: _tripInfo!,
                              onViewDetails: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => ChatTripDetailSheet(
                                  tripId: _tripInfo!.tripId,
                                  isDriver: myId == _tripInfo!.ownerId,
                                  chatRepo: _chatRepo,
                                ),
                              ),
                            );
                          }
                          final msg = _messages[i];
                          final senderName = widget.isGroupChat && !msg.isMine
                              ? (msg.senderName ?? _participantNames[msg.senderId])
                              : null;
                          return _MessageBubble(
                            message: msg,
                            senderName: senderName,
                          );
                        },
                      ),
          ),
          _InputBar(controller: _textController, onSend: _send),
        ],
      ),
    );
  }
}

// ── Trip Info Card ────────────────────────────────────────────────────────────

class _TripInfoCard extends StatelessWidget {
  const _TripInfoCard({required this.trip, required this.onViewDetails});
  final AcceptedTripInfo trip;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Viaje confirmado',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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
                    trip.originCity,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AppColors.primary),
                ),
                Flexible(
                  child: Text(
                    trip.destinationCity,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Date & time
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  trip.formattedTime.isNotEmpty
                      ? '${trip.formattedDate}  ·  ${trip.formattedTime}'
                      : trip.formattedDate,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onViewDetails,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Ver detalles',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Request Banner ─────────────────────────────────────────────────────────────

class _RequestBanner extends StatelessWidget {
  const _RequestBanner({
    required this.request,
    required this.processing,
    required this.onAccept,
    required this.onDecline,
    required this.onDismiss,
  });

  final PendingRequestInfo request;
  final bool processing;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final date = request.departureDate;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_rounded,
                  size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Solicitud de viaje · $dateStr',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: Color(0xFF92400E)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${request.originAddress} → ${request.destinationAddress}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${request.seatsRequested} asiento${request.seatsRequested > 1 ? 's' : ''} solicitado${request.seatsRequested > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
          ),
          if (request.message != null && request.message!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"${request.message}"',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF92400E),
                  fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          processing
              ? const Center(
                  child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Rechazar',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Aceptar',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

// ── Invitation Banner (driver → passenger offer) ────────────────────────────

class _InvitationBanner extends StatelessWidget {
  const _InvitationBanner({
    required this.invitation,
    required this.processing,
    required this.onAccept,
    required this.onDecline,
    required this.onDismiss,
  });

  final PendingInvitationInfo invitation;
  final bool processing;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEFF6FF),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_rounded,
                  size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Oferta de viaje · ${invitation.formattedDate}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: Color(0xFF1E3A8A)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${invitation.originAddress} → ${invitation.destinationAddress}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '\$${invitation.pricePerSeat} por asiento · ${invitation.freeSeats} lugar${invitation.freeSeats != 1 ? 'es' : ''} disponible${invitation.freeSeats != 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
          ),
          if (invitation.vehicleBrand != null) ...[
            Text(
              '${invitation.vehicleBrand} ${invitation.vehicleModel} · ${invitation.vehicleColor}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
            ),
          ],
          if (invitation.message != null &&
              invitation.message!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"${invitation.message}"',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E40AF),
                  fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          processing
              ? const Center(
                  child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDecline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Rechazar',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Aceptar',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.senderName});
  final ChatMessage message;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(
                senderName!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: isMine ? Colors.white : AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.textSecondary,
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

// ── Group Members Sheet ───────────────────────────────────────────────────────

class _GroupMembersSheet extends StatelessWidget {
  const _GroupMembersSheet({
    required this.participants,
    required this.onRefresh,
  });
  final List<GroupParticipant> participants;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded,
                    size: 20, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Text(
                  'Integrantes (${participants.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Participant list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: participants.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: participants.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72, color: AppColors.border),
                    itemBuilder: (context, i) {
                      final p = participants[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: p.isDriver
                                  ? AppColors.primaryLight
                                  : const Color(0xFFF1F5F9),
                              child: Text(
                                _initials(p.fullName),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: p.isDriver
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                p.fullName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (p.isDriver)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Conductor',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;
  int _charCount = 0;
  static const int _maxChars = 50;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final hasText = text.trim().isNotEmpty;
    final count = text.length;
    if (hasText != _hasText || count != _charCount) {
      setState(() {
        _hasText = hasText;
        _charCount = count;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxChars - _charCount;
    final isNearLimit = remaining <= 10;
    final isOverLimit = remaining < 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      maxLines: null,
                      maxLength: _maxChars,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Escribí un mensaje...',
                        hintStyle: TextStyle(
                            color: AppColors.textSecondary, fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        filled: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: (_hasText && !isOverLimit)
                        ? AppColors.primary
                        : AppColors.border,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: (_hasText && !isOverLimit) ? widget.onSend : null,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '$_charCount/$_maxChars',
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isNearLimit ? FontWeight.w600 : FontWeight.normal,
                color: isOverLimit
                    ? Colors.red
                    : isNearLimit
                        ? Colors.orange.shade700
                        : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

