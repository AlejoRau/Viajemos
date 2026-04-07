import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/badge_providers.dart';
import '../data/chat_repository.dart';

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

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.contactName,
    this.contactId,
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

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribe();
    if (widget.contactId != null) {
      _loadPendingRequest();
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
          _messages = msgs;
          _loading = false;
        });
        _scrollToBottom();
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

  void _subscribe() {
    _channel = _chatRepo.subscribeToMessages(widget.chatId, (msg) {
      if (mounted) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
        _chatRepo.markAsRead(widget.chatId);
        ref.read(unreadCountProvider.notifier).refresh();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _chatRepo.sendMessage(widget.chatId, text);
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
        title: Row(
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
            Text(
              widget.contactName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) =>
                            _MessageBubble(message: _messages[i]),
                      ),
          ),
          _InputBar(controller: _textController, onSend: _send),
        ],
      ),
    );
  }
}

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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
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

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: widget.controller,
                  maxLines: null,
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    filled: false,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: _hasText ? AppColors.primary : AppColors.border,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _hasText ? widget.onSend : null,
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
      ),
    );
  }
}
