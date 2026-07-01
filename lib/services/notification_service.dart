import '../models/app_notification.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _api = ApiClient.instance;

  /// `GET /me/notifications` — last 50, most recent first.
  Future<List<AppNotification>> getNotifications() async {
    final res = await _api.get('/me/notifications');
    final list = (res as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => AppNotification.fromJson(e))
        .toList();
  }

  /// `GET /me/notifications/unread-count` — just the badge number,
  /// without fetching the full list. Called by the bell on Home.
  Future<int> getUnreadCount() async {
    final res = await _api.get('/me/notifications/unread-count');
    return (res as Map<String, dynamic>?)?['count'] as int? ?? 0;
  }

  /// `PATCH /me/notifications/{id}/read` — marks one as read.
  Future<void> markAsRead(String notificationId) async {
    await _api.patch('/me/notifications/$notificationId/read');
  }

  /// `PATCH /me/notifications/read-all` — marks all as read at once.
  Future<void> markAllAsRead() async {
    await _api.patch('/me/notifications/read-all');
  }
}
