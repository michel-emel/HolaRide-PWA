import '../models/chat_message.dart';
import 'api_client.dart';

/// Trip chat — unlocked once a booking is paid, per your backend's
/// design. Polling-based for now, same pattern as the waiting-for-driver
/// screen; swap for a websocket later without touching the screen that
/// uses this.
///
/// Confirmed: `GET`/`POST /trips/{trip_id}/chat/messages`.
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final _api = ApiClient.instance;

  Future<List<ChatMessage>> getMessages(String tripId) async {
    final res = await _api.get('/trips/$tripId/chat/messages');
    final list = (res as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map((e) => ChatMessage.fromJson(e)).toList();
  }

  /// Confirmed against the real backend source: the field is `content`,
  /// not `text` — your earlier guess was wrong, which is exactly why
  /// sending never worked.
  Future<void> sendMessage(String tripId, String text) async {
    await _api.post('/trips/$tripId/chat/messages', body: {'content': text});
  }

  /// Soft delete — only works on your own message. The backend keeps
  /// the row but clears its content and flips message_type to
  /// "deleted"; the next getMessages() call will show it as such via
  /// ChatMessage.isDeleted.
  Future<void> deleteMessage(String tripId, String messageId) async {
    await _api.delete('/trips/$tripId/chat/messages/$messageId');
  }

  /// Removes this trip's chat from YOUR OWN chat list only — like
  /// WhatsApp's "Delete Chat". Doesn't affect what anyone else sees,
  /// and reappears automatically if a new message comes in afterward.
  Future<void> hideChat(String tripId) async {
    await _api.post('/trips/$tripId/chat/hide');
  }

  /// trip_ids whose chat you've hidden from your own list — the Chat
  /// inbox uses this to filter its (client-side-built) list.
  Future<List<String>> getHiddenChatIds() async {
    final res = await _api.get('/trips/hidden-chats');
    final ids = (res as Map<String, dynamic>?)?['trip_ids'] as List?;
    return ids?.map((e) => e.toString()).toList() ?? const [];
  }
}