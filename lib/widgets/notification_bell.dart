import 'package:flutter/material.dart';
import '../screens/notifications/notifications_screen.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';

/// Cloche de notification réutilisable — affiche un badge rouge avec
/// le nombre de notifications non lues, et ouvre [NotificationsScreen]
/// au tap. Peut être placée dans n'importe quel AppBar/header.
///
/// Usage dans un AppBar :
///   actions: [const NotificationBell(), const ProfileIconButton()]
///
/// Se charge automatiquement au montage et se rafraîchit quand on
/// revient de [NotificationsScreen] (les notifications qu'on vient
/// de lire disparaissent du badge).
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _load();
    SessionService.instance.authChanged.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    SessionService.instance.authChanged.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final loggedIn = await SessionService.instance.isLoggedIn();
    if (!mounted) return;
    setState(() => _loggedIn = loggedIn);
    if (!loggedIn) return;
    try {
      final count = await NotificationService.instance.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    // Refresh badge once we come back — some may have been read.
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _openNotifications,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none, size: 26, color: AppColors.textPrimary),
            if (_unreadCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
