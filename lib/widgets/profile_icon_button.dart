import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/session_service.dart';
import '../screens/main_tab_screen.dart';
import '../theme/app_colors.dart';

/// Circular profile button showing the user's initials — much more
/// personal than a generic person icon. Falls back to the icon for
/// guests or when no name is available.
class ProfileIconButton extends StatelessWidget {
  const ProfileIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SessionService.instance.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return FutureBuilder<AppUser?>(
          future: SessionService.instance.getUser(),
          builder: (context, userSnap) {
            final user = userSnap.data;
            final initial = (user?.firstName?.isNotEmpty == true)
                ? user!.firstName![0].toUpperCase()
                : (user?.lastName?.isNotEmpty == true)
                    ? user!.lastName![0].toUpperCase()
                    : null;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const MainTabScreen(initialIndex: 3)),
                  (route) => false,
                ),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: initial != null
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : const Icon(Icons.person_outline,
                            size: 18, color: Colors.white),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
