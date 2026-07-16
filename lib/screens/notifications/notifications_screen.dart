import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../bookings/my_bookings_screen.dart';
import '../driver/my_trips_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final notifs = await NotificationService.instance.getNotifications();
      if (!mounted) return;
      setState(() { _notifications = notifs; _loading = false; });
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/notifications/notifications_screen.dart: $e');
      if (!mounted) return;
      setState(() { _error = "Couldn't load notifications."; _loading = false; });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationService.instance.markAllAsRead();
      await _load();
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/notifications/notifications_screen.dart: $e');
    }
  }

  Future<void> _onTap(AppNotification notif) async {
    if (!notif.isRead) {
      NotificationService.instance.markAsRead(notif.id).catchError((_) {});
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notif.id);
        if (idx != -1) {
          _notifications[idx] = AppNotification(
            id: notif.id, type: notif.type, title: notif.title, body: notif.body,
            referenceId: notif.referenceId, readAt: DateTime.now(), createdAt: notif.createdAt,
          );
        }
      });
    }
    if (!mounted) return;
    switch (notif.type) {
      case 'booking_request':
      case 'passenger_paid':
      case 'passenger_checkin':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyTripsScreen()));
        break;
      case 'booking_accepted':
      case 'booking_rejected':
      case 'booking_cancelled':
      case 'rebooked':
      case 'marked_no_show':
      case 'trip_cancelled':
      case 'payment_confirmed':
      case 'payment_success':
      case 'payment_failed':
      case 'driver_location_shared':
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
        break;
      case 'sos_alert':
        if (notif.referenceId != null) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyTripsScreen()));
        }
        break;
      default:
        break;
    }
  }

  String _timeAgo(DateTime t, AppLocalizations l) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return l.notificationsJustNow;
    if (diff.inMinutes < 60) return l.notificationsMinsAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.notificationsHoursAgo(diff.inHours);
    if (diff.inDays == 1) return l.notificationsYesterday;
    return l.notificationsDaysAgo(diff.inDays);
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'booking_request': return Icons.person_add_outlined;
      case 'booking_accepted': return Icons.check_circle_outline;
      case 'booking_rejected': return Icons.cancel_outlined;
      case 'booking_cancelled':
      case 'trip_cancelled': return Icons.event_busy_outlined;
      case 'rebooked': return Icons.refresh_outlined;
      case 'marked_no_show': return Icons.warning_amber_outlined;
      case 'payment_confirmed':
      case 'payment_success': return Icons.payment_outlined;
      case 'payment_failed': return Icons.money_off_outlined;
      case 'passenger_paid': return Icons.paid_outlined;
      case 'passenger_checkin': return Icons.where_to_vote_outlined;
      case 'driver_location_shared': return Icons.location_on_outlined;
      case 'sos_alert': return Icons.sos_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'booking_rejected':
      case 'booking_cancelled':
      case 'trip_cancelled':
      case 'marked_no_show':
      case 'payment_failed':
      case 'sos_alert':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppHeader(
        l.notificationsTitle,
        extraActions: unreadCount > 0
            ? [
                TextButton(
                  onPressed: _markAllRead,
                  child: Text(l.notificationsMarkRead,
                      style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
              : _notifications.isEmpty
                  ? _buildEmpty(l)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _buildItem(_notifications[i], l),
                      ),
                    ),
    );
  }

  Widget _buildItem(AppNotification n, AppLocalizations l) {
    final color = _colorFor(n.type);
    final isUnread = !n.isRead;
    return InkWell(
      onTap: () => _onTap(n),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.infoBg : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUnread ? AppColors.primary.withOpacity(0.2) : AppColors.border),
          boxShadow: [BoxShadow(color: AppColors.textPrimary.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(_iconFor(n.type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(n.title ?? n.type,
                        style: TextStyle(fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600, fontSize: 14))),
                    if (isUnread)
                      Container(width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                  ]),
                  if (n.body != null && n.body!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(n.body!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.3)),
                  ],
                  const SizedBox(height: 6),
                  Text(_timeAgo(n.createdAt, l),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(l.notificationsEmpty,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(l.notificationsEmptyHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
