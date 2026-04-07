import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.contactName,
    required this.lastMessage,
    required this.unreadCount,
    this.contactId,
    this.lastMessageAt,
    this.name,
    this.tripId,
  });

  final String id;
  final String? contactId;
  final String contactName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? name;
  final String? tripId;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isMine;
}

class PendingRequestInfo {
  const PendingRequestInfo({
    required this.requestId,
    required this.tripId,
    required this.originAddress,
    required this.destinationAddress,
    required this.seatsRequested,
    required this.departureDate,
    this.message,
  });

  final String requestId;
  final String tripId;
  final String originAddress;
  final String destinationAddress;
  final int seatsRequested;
  final DateTime departureDate;
  final String? message;
}

class ChatRepository {
  final _client = Supabase.instance.client;

  String get _myId => _client.auth.currentUser!.id;

  Future<List<ConversationSummary>> fetchConversations() async {
    final data = await _client.rpc('get_my_conversations') as List;
    return data.map((row) {
      final lastMsgAt = row['last_message_at'] != null
          ? DateTime.parse(row['last_message_at'] as String)
          : null;
      return ConversationSummary(
        id: row['id'] as String,
        contactId: row['contact_id'] as String?,
        contactName: row['contact_name'] as String? ?? 'Conversación',
        lastMessage: row['last_message'] as String? ?? '',
        lastMessageAt: lastMsgAt,
        unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
        name: row['name'] as String?,
        tripId: row['trip_id'] as String?,
      );
    }).toList();
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final data = await _client
        .from('messages')
        .select('id, conversation_id, sender_id, content, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at') as List;

    final myId = _myId;
    return data
        .map((row) => ChatMessage(
              id: row['id'] as String,
              conversationId: row['conversation_id'] as String,
              senderId: row['sender_id'] as String,
              content: row['content'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              isMine: row['sender_id'] == myId,
            ))
        .toList();
  }

  Future<void> sendMessage(String conversationId, String content) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': _myId,
      'content': content,
    });
  }

  Future<void> markAsRead(String conversationId) async {
    await _client
        .from('conversation_participants')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('conversation_id', conversationId)
        .eq('user_id', _myId);
  }

  Future<PendingRequestInfo?> fetchPendingRequestForContact(
      String contactId) async {
    final data = await _client.rpc(
      'get_pending_request_for_contact',
      params: {'p_contact_id': contactId},
    ) as List;

    if (data.isEmpty) return null;
    final row = data.first;
    return PendingRequestInfo(
      requestId: row['request_id'] as String,
      tripId: row['trip_id'] as String,
      originAddress: row['origin_address'] as String,
      destinationAddress: row['destination_address'] as String,
      seatsRequested: (row['seats_requested'] as int?) ?? 1,
      message: row['message'] as String?,
      departureDate: DateTime.parse(row['departure_date'] as String),
    );
  }

  Future<void> acceptRequest(String requestId) async {
    await _client
        .from('trip_requests')
        .update({'status': 'accepted'})
        .eq('id', requestId);
  }

  Future<void> declineRequest(String requestId) async {
    await _client
        .from('trip_requests')
        .update({'status': 'declined'})
        .eq('id', requestId);
  }

  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(ChatMessage) onNewMessage,
  ) {
    final myId = _myId;
    return _client
        .channel('messages-$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final row = payload.newRecord;
            if (row['conversation_id'] != conversationId) return;
            // Skip own messages — they're added optimistically in the UI
            if (row['sender_id'] == myId) return;
            onNewMessage(ChatMessage(
              id: row['id'] as String,
              conversationId: row['conversation_id'] as String,
              senderId: row['sender_id'] as String,
              content: row['content'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              isMine: false,
            ));
          },
        )
        .subscribe();
  }
}
