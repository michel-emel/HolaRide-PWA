import 'package:flutter/material.dart';
import '../screens/notifications/notifications_screen.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';

/// Redesigned notification bell — circular background, properly spaced,
/// with an animated badge that only appears when there are unread items.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  int _unreadCount = 0;
  bool _loggedIn = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _load();
    SessionService.instance.authChanged.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _bounceController.dispose();
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
      final prev = _unreadCount;
      final count = await NotificationService.instance.getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadCount = count);
      // Bounce the badge if new notifications arrived
      if (count > prev) {
        _bounceController.forward(from: 0);
      }
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: _openNotifications,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: ScaleTransition(
                    scale: _bounceAnim,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}