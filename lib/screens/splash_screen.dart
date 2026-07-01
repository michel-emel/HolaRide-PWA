import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import 'main_tab_screen.dart';

/// Screen 1 — Splash.
///
/// Uses the real marketing photo as a full-bleed background, with a
/// navy gradient overlay on top so the logo, headline, and button stay
/// legible against the bright sky. Stays on screen until the person
/// taps "Get Started" rather than auto-advancing on a timer.
///
/// "Get Started" always opens Home now, logged in or not — browsing
/// trips doesn't need an account. Logging in only happens when someone
/// taps something that actually requires one (see `auth_gate.dart`).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _getStarted(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainTabScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The real marketing photo.
          Image.asset(
            'assets/images/splash_bg.jpg',
            fit: BoxFit.cover,
          ),
          // Navy gradient overlay — strongest at top and bottom where
          // the logo/headline and the CTA button sit, lighter through
          // the middle where the photo itself should read clearly.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.navyDark.withOpacity(0.88),
                  AppColors.navyDark.withOpacity(0.45),
                  AppColors.navyDark.withOpacity(0.25),
                  AppColors.navyDark.withOpacity(0.92),
                ],
                stops: const [0.0, 0.32, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 46),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
                      children: [
                        TextSpan(text: 'Hola', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'Ride', style: TextStyle(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Travel together.\nSave more.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 17, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text('Safe', style: TextStyle(color: Colors.white, fontSize: 14)),
                      Icon(Icons.circle, size: 5, color: AppColors.gold),
                      Text('Affordable', style: TextStyle(color: Colors.white, fontSize: 14)),
                      Icon(Icons.circle, size: 5, color: AppColors.gold),
                      Text('Reliable', style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                  const Spacer(flex: 5),
                  GoldButton(label: 'Get Started', onPressed: () => _getStarted(context)),
                  const SizedBox(height: 16),
                  const Text(
                    'Connecting cities across Cameroon 🇨🇲',
                    style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}