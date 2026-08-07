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

  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.messages = const [],
  });

  int get messageCount => messages.length;

  /// A short one-line summary for list tiles: the last assistant reply, or the
  /// first user message when the assistant has not answered yet.
  String get preview {
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

  Conversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    List<ChatMessage>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      messages: messages ?? this.messages,
    );
  }
}
