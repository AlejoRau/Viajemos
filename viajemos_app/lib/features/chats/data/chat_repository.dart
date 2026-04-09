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

class AcceptedTripInfo {
  const AcceptedTripInfo({
    required this.tripId,
    required this.ownerId,
    required this.originAddress,
    required this.destinationAddress,
    required this.departureDate,
    this.departureTime,
  });

  final String tripId;
  final String ownerId;
  final String originAddress;
  final String destinationAddress;
  final String departureDate;
  final String? departureTime;

  static String _city(String address) {
    final parts = address
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length <= 1) return address.trim();
    if (RegExp(r'^\d').hasMatch(parts.first)) return parts.last;
    return parts.first;
  }

  String get originCity => _city(originAddress);
  String get destinationCity => _city(destinationAddress);

  String get formattedDate {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    try {
      final d = DateTime.parse(departureDate);
      return '${d.day} de ${months[d.month - 1]}';
    } catch (_) {
      return departureDate;
    }
  }

  String get formattedTime {
    if (departureTime == null || departureTime!.length < 5) return '';
    return departureTime!.substring(0, 5);
  }

  /// Short date format "DD/MM"
  String get shortDate {
    try {
      final d = DateTime.parse(departureDate);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return departureDate;
    }
  }
}

// ── Chat Trip Detail (full info for the in-chat sheet) ────────────────────────

class ChatTripPassenger {
  const ChatTripPassenger({
    required this.id,
    required this.requestId,
    required this.name,
    this.avatarUrl,
  });
  final String id;
  final String requestId;
  final String name;
  final String? avatarUrl;
}

class ChatTripDetail {
  const ChatTripDetail({
    required this.tripId,
    required this.ownerId,
    required this.originAddress,
    required this.destinationAddress,
    required this.departureDate,
    required this.pricePerSeat,
    required this.availableSeats,
    required this.seatsTaken,
    required this.allowsPets,
    required this.picksUpAtDoor,
    required this.dropsOffAtDoor,
    required this.via,
    required this.stops,
    required this.passengers,
    this.departureTime,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleColor,
    this.description,
  });

  final String tripId;
  final String ownerId;
  final String originAddress;
  final String destinationAddress;
  final String departureDate;
  final int pricePerSeat;
  final int availableSeats;
  final int seatsTaken;
  final bool allowsPets;
  final bool picksUpAtDoor;
  final bool dropsOffAtDoor;
  final List<String> via;
  final List<String> stops;
  final List<ChatTripPassenger> passengers;
  final String? departureTime;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? description;

  int get freeSeats => availableSeats - seatsTaken;

  String get vehicleDisplay {
    if (vehicleBrand == null) return '';
    return '$vehicleBrand $vehicleModel · $vehicleColor';
  }

  String get formattedDate {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    try {
      final d = DateTime.parse(departureDate);
      return '${d.day} de ${months[d.month - 1]}';
    } catch (_) {
      return departureDate;
    }
  }

  String get formattedTime {
    if (departureTime == null || departureTime!.length < 5) return '';
    return departureTime!.substring(0, 5);
  }
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

  Future<AcceptedTripInfo?> fetchTripInfo(String tripId) async {
    try {
      final data = await _client
          .from('trips')
          .select(
              'id, owner_id, origin_address, destination_address, departure_date, departure_time')
          .eq('id', tripId)
          .maybeSingle();
      if (data == null) return null;
      return AcceptedTripInfo(
        tripId: data['id'] as String,
        ownerId: data['owner_id'] as String,
        originAddress: data['origin_address'] as String,
        destinationAddress: data['destination_address'] as String,
        departureDate: data['departure_date'] as String,
        departureTime: data['departure_time'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ChatTripDetail?> fetchChatTripDetail(String tripId) async {
    try {
      final data = await _client.from('trips').select('''
        id, owner_id, origin_address, destination_address,
        departure_date, departure_time, price_per_seat,
        available_seats, seats_taken, allows_pets, picks_up_at_door,
        drops_off_at_door, description, via, stops,
        vehicles!vehicle_id(brand, model, color),
        trip_requests!trip_id(
          id, passenger_id, status,
          profiles!passenger_id(full_name, avatar_url)
        )
      ''').eq('id', tripId).maybeSingle();
      if (data == null) return null;

      final vehicle = data['vehicles'] as Map<String, dynamic>?;
      final requests = (data['trip_requests'] as List? ?? [])
          .where((r) => r['status'] == 'accepted')
          .map((r) {
            final p = r['profiles'] as Map<String, dynamic>? ?? {};
            return ChatTripPassenger(
              id: r['passenger_id'] as String,
              requestId: r['id'] as String,
              name: p['full_name'] as String? ?? 'Pasajero',
              avatarUrl: p['avatar_url'] as String?,
            );
          })
          .toList();

      return ChatTripDetail(
        tripId: data['id'] as String,
        ownerId: data['owner_id'] as String,
        originAddress: data['origin_address'] as String,
        destinationAddress: data['destination_address'] as String,
        departureDate: data['departure_date'] as String,
        departureTime: data['departure_time'] as String?,
        pricePerSeat: (data['price_per_seat'] as num).toInt(),
        availableSeats: data['available_seats'] as int,
        seatsTaken: data['seats_taken'] as int,
        allowsPets: data['allows_pets'] as bool? ?? false,
        picksUpAtDoor: data['picks_up_at_door'] as bool? ?? false,
        dropsOffAtDoor: data['drops_off_at_door'] as bool? ?? false,
        via: (data['via'] as List?)?.cast<String>() ?? [],
        stops: (data['stops'] as List?)?.cast<String>() ?? [],
        vehicleBrand: vehicle?['brand'] as String?,
        vehicleModel: vehicle?['model'] as String?,
        vehicleColor: vehicle?['color'] as String?,
        description: data['description'] as String?,
        passengers: requests,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> declineRequest(String requestId) async {
    await _client
        .from('trip_requests')
        .update({'status': 'declined'})
        .eq('id', requestId);
  }

  Future<void> expelPassenger(String requestId) async {
    await _client
        .from('trip_requests')
        .update({'status': 'expelled'})
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
