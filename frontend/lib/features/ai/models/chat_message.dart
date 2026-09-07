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

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] ?? '').toString().toLowerCase();
    final role = roleStr == 'user' ? MessageRole.user : MessageRole.assistant;
    final timestampStr = json['timestamp'] ?? json['created_at'];

    AiResponse? parsedResponse;
    if (json['response'] is Map<String, dynamic>) {
      parsedResponse =
          AiResponse.fromJson(json['response'] as Map<String, dynamic>);
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      role: role,
      content: json['content']?.toString() ?? '',
      timestamp: timestampStr != null
          ? DateTime.tryParse(timestampStr.toString()) ?? DateTime.now()
          : DateTime.now(),
      response: parsedResponse,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role == MessageRole.user ? 'user' : 'assistant',
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (response != null) 'response': response!.toJson(),
    };
  }

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
