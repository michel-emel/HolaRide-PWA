/// A single chat message on a trip. [isSystem] covers the automatic
/// messages your backend posts for workflow events (request sent,
/// accepted, payment completed) — rendered differently from a real
/// message someone typed.
///
/// Confirmed against the real backend source (`app/routers/chat.py`
/// and the `Message` model it constructs): the message body field is
/// `content`, and system messages are distinguished by `message_type
/// == "system"` — earlier guesses of `text`/`message` and
/// `is_system`/`sender_id == null` were both wrong, which is exactly
/// why sent messages never showed up correctly.
///
/// Chat access itself is already correctly scoped per-trip, not
/// per-booking — `app/routers/chat.py`'s `_require_participant` checks
/// the driver or ANY paid passenger on the trip, and every participant
/// shares the same chat row. Multiple passengers booking the same trip
/// already land in one shared conversation; no fix needed there.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final bool isSystem;
  final bool isDeleted;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.isSystem,
    required this.isDeleted,
    required this.createdAt,
  });

  bool isMine(String currentUserId) => senderId == currentUserId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final firstName = json['sender_first_name']?.toString();
    final lastName = json['sender_last_name']?.toString();
    final fullName = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: fullName,
      text: json['content']?.toString() ?? '',
      isSystem: json['message_type'] == 'system',
      isDeleted: json['message_type'] == 'deleted',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}