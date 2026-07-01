import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../screens/main_tab_screen.dart';
import '../theme/app_colors.dart';

/// The small circular profile-icon shortcut shown in the header of
/// every screen a logged-in person can reach — tapping it always goes
/// straight to the Profile tab. Self-contained: checks login state
/// itself and renders nothing for a guest, so it's safe to drop into
/// any screen's AppBar actions unconditionally, including ones guests
/// can also reach (Trip Detail, Search Results) without it ever
/// showing for someone who isn't actually logged in.
class ProfileIconButton extends StatelessWidget {
  const ProfileIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SessionService.instance.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainTabScreen(initialIndex: 3)),
              (route) => false,
            ),
            icon: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, size: 19, color: AppColors.primary),
            ),
          ),
        );
      },
    );
  }
}
