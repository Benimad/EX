import 'package:supabase_flutter/supabase_flutter.dart';

import '../../monetization/domain/limits.dart';
import '../domain/chat_message.dart';
import '../domain/chat_origin.dart';

/// Mira chat over the `mira-chat` Edge Function. The server looks up the
/// conversation's origin itself and enforces the free limit (HTTP 402).
class CoachRepository {
  CoachRepository(this._db);
  final SupabaseClient _db;

  /// Creates a conversation; origin is stored server-side at creation.
  Future<String> createConversation(ChatOrigin origin) async {
    final id = await _db.rpc<String>(
      'create_conversation',
      params: {'p_origin': origin.wire},
    );
    return id;
  }

  Future<List<ChatMessage>> loadMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final rows = await _db
        .from('messages')
        .select('id,role,content,created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(ChatMessage.fromJson).toList().reversed.toList();
  }

  /// Sends [text]; returns Mira's reply.
  /// Throws [MessageLimitReached] on HTTP 402 (free limit, normal chats only).
  Future<ChatMessage> send({
    required String conversationId,
    required String text,
  }) async {
    try {
      final res = await _db.functions.invoke(
        'mira-chat',
        body: {'conversation_id': conversationId, 'message': text},
      );
      final data = res.data;
      final reply = data is Map ? data['reply'] : null;
      if (reply is! String) throw const FormatException('bad mira-chat reply');
      return ChatMessage(role: ChatRole.assistant, content: reply);
    } on FunctionException catch (e) {
      if (e.status == 402) {
        final details = e.details;
        final raw = details is Map ? details['resets_at'] : null;
        throw MessageLimitReached(
          resetsAt: raw is String ? DateTime.tryParse(raw)?.toLocal() : null,
        );
      }
      rethrow;
    }
  }
}
