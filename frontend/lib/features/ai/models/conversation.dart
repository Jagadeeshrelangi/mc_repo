import 'chat_message.dart';

/// A chat conversation: a titled thread of messages.
///
/// Conversations are immutable. The provider owns the list and replaces
/// entries with [copyWith] on every mutation, so there is never a second
/// "shadow" copy of the same thread anywhere in the module.
class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final List<ChatMessage> messages;
  final int? messageCountOverride;
  final String? previewOverride;

  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.messages = const [],
    this.messageCountOverride,
    this.previewOverride,
  });

  int get messageCount => messageCountOverride ?? messages.length;

  /// A short one-line summary for list tiles: the server preview if available,
  /// otherwise the last assistant reply or first user message.
  String get preview {
    if (previewOverride != null && previewOverride!.isNotEmpty) {
      return previewOverride!;
    }
    if (messages.isEmpty) return 'No messages yet';
    for (final message in messages.reversed) {
      if (!message.isUser) return message.content;
    }
    return messages.first.content;
  }

  /// The first user question — used as the default thread title.
  String get firstUserQuestion {
    for (final message in messages) {
      if (message.isUser) return message.content;
    }
    return title;
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    List<ChatMessage> parsedMessages = const [];
    if (rawMessages is List) {
      parsedMessages = rawMessages
          .whereType<Map<String, dynamic>>()
          .map((m) => ChatMessage.fromJson(m))
          .toList();
    }

    final createdAtStr = json['created_at'] ?? json['createdAt'];
    final updatedAtStr = json['updated_at'] ?? json['updatedAt'];

    return Conversation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Conversation',
      createdAt: createdAtStr != null
          ? DateTime.tryParse(createdAtStr.toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: updatedAtStr != null
          ? DateTime.tryParse(updatedAtStr.toString()) ?? DateTime.now()
          : DateTime.now(),
      isPinned: json['is_pinned'] == true || json['isPinned'] == true,
      messages: parsedMessages,
      messageCountOverride: (json['message_count'] as num?)?.toInt(),
      previewOverride: json['preview'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_pinned': isPinned,
      'message_count': messageCount,
      if (previewOverride != null) 'preview': previewOverride,
      if (messages.isNotEmpty)
        'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    List<ChatMessage>? messages,
    int? messageCountOverride,
    String? previewOverride,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      messages: messages ?? this.messages,
      messageCountOverride:
          messageCountOverride ?? this.messageCountOverride,
      previewOverride: previewOverride ?? this.previewOverride,
    );
  }
}
