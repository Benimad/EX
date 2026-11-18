import 'package:flutter/foundation.dart';

enum ChatRole { user, assistant }

@immutable
class ChatMessage {
  const ChatMessage({required this.role, required this.content, this.id});

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id']?.toString(),
    role: json['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
    content: json['content'] as String? ?? '',
  );

  final String? id;
  final ChatRole role;
  final String content;
}
