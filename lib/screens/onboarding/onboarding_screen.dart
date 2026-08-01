import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../splash_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _next() {
    if (_page < 2) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else { _finish(); }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SplashScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [

        // ── Swipeable backgrounds ─────────────────────────────
        PageView(
          controller: _ctrl,
          onPageChanged: (i) => setState(() => _page = i),
          children: const [
            _Page1Content(),
            _Page2Content(),
            _Page3Content(),
          ],
        ),

        // ── Fixed: Skip ───────────────────────────────────────
        Positioned(
          top: top + 16, right: 20,
          child: GestureDetector(
            onTap: _finish,
            child: Text(l.onboardingSkip,
                style: const TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
        ),

        // ── Fixed: bottom content (transparent, floats on image) ──
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Feature content — changes per page
                _BottomContent(page: _page),
                const SizedBox(height: 20),
                // Dots
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8, height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4)),
                  ))),
                const SizedBox(height: 20),
                // Button
                SizedBox(width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _page == 2 ? _finish : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B6B45),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _page == 0 ? l.homeGetStarted : (_page == 1 ? l.onboardingNext : l.onboardingLetsGo),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  )),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Bottom content per page — transparent, white text ──────────
class _BottomContent extends StatelessWidget {
  final int page;
  const _BottomContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (page) {
      case 0:
        return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _Feat(Icons.verified_user_outlined, l.onboardingFeatSafeTitle, l.onboardingFeatSafeSub),
          _Feat(Icons.people_outline, l.onboardingFeatShareTitle, l.onboardingFeatShareSub),
          _Feat(Icons.wallet_outlined, l.onboardingFeatAffordableTitle, l.onboardingFeatAffordableSub),
        ]);
      case 1:
        return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _Feat(Icons.map_outlined, l.onboardingFeatRoutesTitle, l.onboardingFeatRoutesSub),
          _Feat(Icons.wallet_outlined, l.onboardingFeatPricesTitle, l.onboardingFeatPricesSub),
          _Feat(Icons.bolt_outlined, l.onboardingFeatBookingTitle, l.onboardingFeatBookingSub),
        ]);
      default:
        return Column(children: [
          _FeatRow(Icons.lock_outline, l.onboardingFeatPaymentsTitle, l.onboardingFeatPaymentsSub),
          const SizedBox(height: 10),
          _FeatRow(Icons.location_on_outlined, l.onboardingFeatTrackingTitle, l.onboardingFeatTrackingSub),
          const SizedBox(height: 10),
          _FeatRow(Icons.headset_mic_outlined, l.onboardingFeatSupportTitle, l.onboardingFeatSupportSub),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.favorite, color: Colors.white70, size: 13),
            const SizedBox(width: 6),
            Text(l.onboardingFooterTagline,
              style: const TextStyle(color: Colors.white70, fontSize: 12,
                  fontWeight: FontWeight.w500)),
          ]),
        ]);
    }
  }
}

// ── Small icon + text feature (pages 1 & 2) ────────────────────
class _Feat extends StatelessWidget {
  final IconData icon; final String title, sub;
  const _Feat(this.icon, this.title, this.sub);

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: 48, height: 48,
      decoration: BoxDecoration(color: Colors.white.withOpacity(.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24)),
      child: Icon(icon, color: Colors.white, size: 22)),
    const SizedBox(height: 8),
    Text(title, textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
    const SizedBox(height: 2),
    Text(sub, textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white60, fontSize: 10, height: 1.3)),
  ]);
}

// ── Horizontal feature row (page 3) ────────────────────────────
class _FeatRow extends StatelessWidget {
  final IconData icon; final String title, sub;
  const _FeatRow(this.icon, this.title, this.sub);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withOpacity(.15), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: 14)),
        Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ]),
    ]),
  );
}

// ══════════════════════════════════════════════
// PAGE BACKGROUNDS
// ══════════════════════════════════════════════
class _Page1Content extends StatelessWidget {
  const _Page1Content();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final top = MediaQuery.of(context).padding.top;
    return Stack(fit: StackFit.expand, children: [
      Image.asset('assets/images/splash_bg.jpg', fit: BoxFit.cover),
      Container(decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        stops: [0.0, 0.3, 0.6, 1.0],
        colors: [Color(0xCC0A1628), Color(0x550A1628), Color(0x110A1628), Color(0xDD0A1628)],
      ))),
      Column(children: [
        SizedBox(height: top + 60),
        // Logo
        Container(width: 68, height: 68,
          decoration: BoxDecoration(color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 16, offset: const Offset(0,6))]),
          child: const Center(child: Text('H',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20))))),
        const SizedBox(height: 10),
        Text(l.onboardingBrandName,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.3)),
        Text(l.onboardingTagline,
          style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 32),
        // Title
        Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Column(children: [
          RichText(textAlign: TextAlign.center, text: TextSpan(
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.2,
              shadows: [Shadow(color: Color(0x880A1628), blurRadius: 8)]),
            children: [
              TextSpan(text: l.onboardingPage1TitleLine1, style: const TextStyle(color: Colors.white)),
              TextSpan(text: l.onboardingPage1TitleAccent, style: const TextStyle(color: Color(0xFFFFCC02))),
              TextSpan(text: l.onboardingPage1TitleSuffix, style: const TextStyle(color: Colors.white)),
            ],
          )),
          const SizedBox(height: 12),
          Text(l.onboardingPage1Body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5,
              shadows: [Shadow(color: Color(0x660A1628), blurRadius: 4)])),
        ])),
      ]),
    ]);
  }
}

class _Page2Content extends StatelessWidget {
  const _Page2Content();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final top = MediaQuery.of(context).padding.top;
    return Stack(fit: StackFit.expand, children: [
      Image.asset('assets/images/onboard_1.png', fit: BoxFit.cover),
      Container(decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        stops: [0.0, 0.4, 0.7, 1.0],
        colors: [Color(0xAA0A1628), Color(0x220A1628), Color(0x110A1628), Color(0xEE0A1628)],
      ))),
      Column(children: [
        SizedBox(height: top + 60),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
          RichText(textAlign: TextAlign.center, text: TextSpan(
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2,
              shadows: [Shadow(color: Color(0x880A1628), blurRadius: 8)]),
            children: [
              TextSpan(text: l.onboardingPage2TitlePrefix, style: const TextStyle(color: Colors.white)),
              TextSpan(text: l.onboardingPage2TitleAccent, style: const TextStyle(color: Color(0xFFFFCC02))),
            ],
          )),
          const SizedBox(height: 10),
          Text(l.onboardingPage2Body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5,
              shadows: [Shadow(color: Color(0x660A1628), blurRadius: 4)])),
        ])),
      ]),
    ]);
  }
}

class _Page3Content extends StatelessWidget {
  const _Page3Content();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final top = MediaQuery.of(context).padding.top;
    return Stack(fit: StackFit.expand, children: [
      Image.asset('assets/images/onboard_2.png', fit: BoxFit.cover),
      Container(decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        stops: [0.0, 0.3, 0.6, 1.0],
        colors: [Color(0xAA0A1628), Color(0x220A1628), Color(0x110A1628), Color(0xEE0A1628)],
      ))),
      Column(children: [
        SizedBox(height: top + 60),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
          RichText(textAlign: TextAlign.center, text: TextSpan(
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
            children: [
              TextSpan(text: l.onboardingPage3TitlePrefix, style: const TextStyle(color: Colors.white)),
              TextSpan(text: l.onboardingPage3TitleAccent, style: const TextStyle(color: Color(0xFFFFCC02))),
              TextSpan(text: l.onboardingPage3TitleSuffix, style: const TextStyle(color: Colors.white)),
            ],
          )),
          const SizedBox(height: 10),
          Text(l.onboardingPage3Body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        ])),
        const SizedBox(height: 200),
      ]),
    ]);
  }
}

class _InlineFeature extends StatelessWidget {
  final IconData icon; final String title, sub;
  const _InlineFeature(this.icon, this.title, this.sub);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(title, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.w700, fontSize: 14,
            shadows: [Shadow(color: Color(0x880A1628), blurRadius: 6)])),
        Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ]),
      const SizedBox(width: 10),
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withOpacity(.15),
            shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
        child: Icon(icon, color: Colors.white, size: 20)),
    ],
  );
}