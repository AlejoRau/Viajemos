import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/public_profile_sheet.dart';
import '../data/chat_repository.dart';

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
}

String _formatTimestamp(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final msgDay = DateTime(local.year, local.month, local.day);

  if (msgDay == today) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  } else if (msgDay == yesterday) {
    return 'Ayer';
  } else {
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }
}

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _searchController = TextEditingController();
  final _chatRepo = ChatRepository();
  String _query = '';
  List<ConversationSummary> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final convs = await _chatRepo.fetchConversations();
      if (mounted) setState(() { _conversations = convs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _conversations
        .where((c) =>
            c.contactName.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar conversaciones...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: filtered.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, i) => _ChatTile(
                        conv: filtered[i],
                        onTap: () async {
                          await context.push(
                            '/chats/${filtered[i].id}',
                            extra: {
                              'contactName': filtered[i].contactName,
                              'contactId': filtered[i].contactId,
                              'tripId': filtered[i].tripId,
                              'isGroupChat': filtered[i].isGroupChat,
                              'participantsCount': filtered[i].participantsCount,
                            },
                          );
                          if (mounted) _load();
                        },
                      ),
                    ),
            ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.conv, required this.onTap});
  final ConversationSummary conv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isGroup = conv.isGroupChat;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: !isGroup && conv.contactId != null
                  ? () => showPublicProfile(context, conv.contactId!)
                  : null,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: isGroup
                    ? const Color(0xFFEDE9FE)
                    : AppColors.primaryLight,
                child: isGroup
                    ? const Icon(Icons.groups_rounded,
                        size: 26, color: Color(0xFF7C3AED))
                    : Text(
                        _initials(conv.contactName),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.contactName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(conv.lastMessageAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (isGroup)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${conv.participantsCount} integrante${conv.participantsCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  const SizedBox(height: 1),
                  Text(
                    conv.lastMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: conv.unreadCount > 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: conv.unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (conv.unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${conv.unreadCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 64, color: AppColors.border),
              SizedBox(height: 16),
              Text(
                'No se encontraron conversaciones',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
