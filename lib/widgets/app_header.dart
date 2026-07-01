import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'notification_bell.dart';
import 'profile_icon_button.dart';

/// Bouton retour personnalisé — cercle vert semi-transparent avec
/// une flèche blanche, cohérent avec l'identité visuelle HolaRide.
/// Utilisé automatiquement dans [buildAppHeader] quand l'écran peut
/// être fermé (i.e. quand il y a un écran derrière dans la pile de
/// navigation). Ne s'affiche pas sur les onglets principaux (Home,
/// My Trips, Chat, Profile) puisqu'ils n'ont pas d'écran "derrière".
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primary,
            size: 16,
          ),
        ),
      ),
    );
  }
}

/// Standard header used across the app's main/tab screens — cream
/// background matching the rest of the redesign (no more white/blue
/// AppBars), no shadow, the notification bell + profile icon included
/// by default. Centralizing this here means future header tweaks only
/// need to change one place, same idea as `AppColors` itself.
///
/// The [NotificationBell] widget is self-contained — it loads its own
/// unread count, handles login state, and navigates to
/// [NotificationsScreen] on tap. Adding it here means every screen
/// that calls [buildAppHeader] automatically gets it without any
/// extra wiring.
AppBar buildAppHeader(
  String title, {
  bool showProfileIcon = true,
  bool showNotificationBell = true,
  bool showBackButton = false,
  List<Widget>? extraActions,
  bool centerTitle = false,
  PreferredSizeWidget? bottom,
}) {
  return AppBar(
    title: Text(title),
    centerTitle: centerTitle,
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    automaticallyImplyLeading: false,
    leading: showBackButton ? const AppBackButton() : null,
    actions: [
      ...?extraActions,
      if (showNotificationBell) const NotificationBell(),
      if (showProfileIcon) const ProfileIconButton(),
    ],
    bottom: bottom,
  );
}
