import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../services/locale_service.dart';
import '../../theme/app_colors.dart';
import 'phone_entry_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final bool isGate;
  final String? gateReason;
  const WelcomeScreen({super.key, this.isGate = false, this.gateReason});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [

        // ── Full background image ─────────────────────────────
        Image.asset('assets/images/welcome_bg.png', fit: BoxFit.cover),

        // ── Light overlay top (for readability) ──────────────
        Container(decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          stops: [0.0, 0.35, 0.60, 1.0],
          colors: [
            Color(0xEEF5F5F0), // cream top
            Color(0xAAF5F5F0),
            Color(0x00F5F5F0), // transparent middle
            Color(0xFFF5F5F0), // solid bottom
          ],
        ))),

        // ── Content ───────────────────────────────────────────
        Column(children: [
          SizedBox(height: top + 12),

          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back / Home button
                if (Navigator.canPop(context))
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.home_outlined, size: 16, color: AppColors.textPrimary),
                        SizedBox(width: 6),
                        Text('Home', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                      ])))
                else
                  const SizedBox.shrink(),

            // Language toggle — same style as home page
            ValueListenableBuilder<Locale>(
              valueListenable: localeNotifier,
              builder: (_, locale, __) {
                final isFr = locale.languageCode == 'fr';
                return GestureDetector(
                  onTap: () => LocaleService.setLocale(Locale(isFr ? 'en' : 'fr')),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(isFr ? '🇫🇷' : '🇬🇧', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(isFr ? 'Français' : 'English',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ]),
                  ),
                );
              },
            ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Logo + Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Pin icon circle
              Container(
                width: 60, height: 60,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.location_on, color: Colors.white, size: 30)),
              const SizedBox(height: 16),

              // HolaRide
              RichText(text: const TextSpan(
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, height: 1.1),
                children: [
                  TextSpan(text: 'Hola', style: TextStyle(color: AppColors.textPrimary)),
                  TextSpan(text: 'Ride', style: TextStyle(color: AppColors.primary)),
                ],
              )),
              const SizedBox(height: 10),

              // Tagline
              RichText(text: TextSpan(
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
                children: [
                  TextSpan(text: l.welcomeTaglinePrefix ?? 'Travel between cities,\n',
                    style: const TextStyle(color: AppColors.textPrimary)),
                  TextSpan(text: l.welcomeTaglineAccent ?? 'together.',
                    style: const TextStyle(color: AppColors.primary)),
                ],
              )),
              const SizedBox(height: 8),

              // Subtitle
              Text(l.welcomeSubtitle ?? 'Comfortable, affordable and safe\nrides across Cameroon.',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            ]),
          ),

          const Spacer(),

          // Bottom buttons — on solid background
          Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, bottom + 20),
            decoration: const BoxDecoration(color: Color(0xFFF5F5F0)),
            child: Column(children: [

              if (gateReason != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(gateReason!,
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600))),
                  ])),
                const SizedBox(height: 16),
              ],

          // Create account button
        SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => PhoneEntryScreen(isGate: isGate)));
                if (isGate && result == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.person_add_outlined, size: 18),
                const SizedBox(width: 10),
                Text(l.welcomeCreateAccount,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                const Icon(Icons.arrow_forward, size: 18),
              ]))),

        const SizedBox(height: 12),

        // Sign in button
        SizedBox(width: double.infinity, height: 54,
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => LoginScreen(isGate: isGate)));
                if (isGate && result == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.login_outlined, size: 18),
                const SizedBox(width: 10),
                Text(l.welcomeSignIn,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                const Icon(Icons.arrow_forward, size: 18),
              ]))),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_outline, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(l.yourDataSafe,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }
}