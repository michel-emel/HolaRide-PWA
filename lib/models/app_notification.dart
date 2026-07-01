/// Matches the real backend `NotificationOut` schema — id, type,
/// title, body, channel, status, reference_id, read_at, created_at.
///
/// `reference_id` is the trip_id or booking_id this notification is
/// about — used to navigate directly to the right screen when the
/// user taps it, rather than just opening a generic list with no
/// clear next action.
///
/// Named `AppNotification` rather than `Notification` to avoid
/// conflicting with Flutter's own built-in `Notification` class.
class AppNotification {
  final String id;
  final String type;
  final String? title;
  final String? body;
  final String? referenceId;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    this.title,
    this.body,
    this.referenceId,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      referenceId: json['reference_id']?.toString(),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
