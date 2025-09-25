enum MessageType {
  text,
  image,
  file,
  voice
}

enum MessageStatus {
  sent,
  delivered,
  read,
  failed
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.receiverId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.metadata,
    this.fileUrl,
    this.fileName,
    this.fileSize,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString(),
      content: json['content'] ?? '',
      type: _parseMessageType(json['type']),
      status: _parseMessageStatus(json['status']),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'type': _messageTypeToString(type),
      'status': _messageStatusToString(status),
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'metadata': metadata,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
    };
  }

  static MessageType _parseMessageType(String? type) {
    switch (type?.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'voice':
        return MessageType.voice;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  static String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
      case MessageType.voice:
        return 'voice';
    }
  }

  static String _messageStatusToString(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }

  // Helper getters
  bool get isSent => status == MessageStatus.sent;
  bool get isDelivered => status == MessageStatus.delivered;
  bool get isRead => status == MessageStatus.read;
  bool get isFailed => status == MessageStatus.failed;
  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file;
  bool get isVoice => type == MessageType.voice;

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
    String? fileUrl,
    String? fileName,
    int? fileSize,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}

class Conversation {
  final String id;
  final String title;
  final List<String> participantIds;
  final String? lastMessageId;
  final Message? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isGroup;
  final String? avatarUrl;
  final bool isMuted;
  final bool isPinned;

  Conversation({
    required this.id,
    required this.title,
    required this.participantIds,
    this.lastMessageId,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isGroup = false,
    this.avatarUrl,
    this.isMuted = false,
    this.isPinned = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      participantIds: (json['participant_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      lastMessageId: json['last_message_id']?.toString(),
      lastMessage: json['last_message'] != null ? Message.fromJson(json['last_message']) : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
      isGroup: json['is_group'] ?? false,
      avatarUrl: json['avatar_url'],
      isMuted: json['is_muted'] ?? false,
      isPinned: json['is_pinned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'participant_ids': participantIds,
      'last_message_id': lastMessageId,
      'last_message': lastMessage?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'unread_count': unreadCount,
      'is_group': isGroup,
      'avatar_url': avatarUrl,
      'is_muted': isMuted,
      'is_pinned': isPinned,
    };
  }

  Conversation copyWith({
    String? id,
    String? title,
    List<String>? participantIds,
    String? lastMessageId,
    Message? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    bool? isGroup,
    String? avatarUrl,
    bool? isMuted,
    bool? isPinned,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      participantIds: participantIds ?? this.participantIds,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroup: isGroup ?? this.isGroup,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}