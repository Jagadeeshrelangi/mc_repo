import 'ai_response.dart';

/// Who authored a chat message.
enum MessageRole { user, assistant }

/// A single message inside a conversation.
///
/// [response] carries the structured, premium reply payload for assistant
/// messages (blocks + action buttons). The [content] field always holds the
/// plain-text body so a conversation can render even without a rich payload.
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final AiResponse? response;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.response,
  });

  bool get isUser => role == MessageRole.user;

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    AiResponse? response,
    bool clearResponse = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      response: clearResponse ? null : response ?? this.response,
    );
  }
}
