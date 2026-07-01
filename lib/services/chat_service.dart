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
}