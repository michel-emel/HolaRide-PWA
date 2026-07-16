import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
            child: const Text('Skip',
                style: TextStyle(color: Colors.white, fontSize: 15,
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
                      _page == 0 ? 'Get Started' : (_page == 1 ? 'Next' : "Let's Go!"),
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
    switch (page) {
      case 0:
        return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: const [
          _Feat(Icons.verified_user_outlined, 'Safe & Trusted', 'Verified drivers\n& secure payments'),
          _Feat(Icons.people_outline, 'Find or Share', 'Choose your trip\nor offer seats'),
          _Feat(Icons.wallet_outlined, 'Affordable', 'Better prices\nfor every journey'),
        ]);
      case 1:
        return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: const [
          _Feat(Icons.map_outlined, 'Many routes', 'Across Cameroon'),
          _Feat(Icons.wallet_outlined, 'Great prices', 'No hidden fees'),
          _Feat(Icons.bolt_outlined, 'Quick booking', 'In a few taps'),
        ]);
      default:
        return Column(children: const [
          _FeatRow(Icons.lock_outline, 'Secure Payments', 'Your money is protected'),
          SizedBox(height: 10),
          _FeatRow(Icons.location_on_outlined, 'Live Trip Tracking', 'Follow your trip in real time'),
          SizedBox(height: 10),
          _FeatRow(Icons.headset_mic_outlined, '24/7 Support', 'We\'re here to help anytime'),
          SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.favorite, color: Colors.white70, size: 13),
            SizedBox(width: 6),
            Text('Building a connected Cameroon, one ride at a time.',
              style: TextStyle(color: Colors.white70, fontSize: 12,
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
        const Text('HolaRide',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.3)),
        const Text('Share the ride. Go further.',
          style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 32),
        // Title
        Padding(padding: const EdgeInsets.symmetric(horizontal: 28), child: Column(children: [
          RichText(textAlign: TextAlign.center, text: const TextSpan(
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.2,
              shadows: [Shadow(color: Color(0x880A1628), blurRadius: 8)]),
            children: [
              TextSpan(text: 'Intercity travel,\n', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'smarter ', style: TextStyle(color: Color(0xFFFFCC02))),
              TextSpan(text: 'together', style: TextStyle(color: Colors.white)),
            ],
          )),
          const SizedBox(height: 12),
          const Text('Book a seat or offer a ride to your\nfavorite cities in Cameroon.\nSafe, affordable and reliable.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5,
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
          RichText(textAlign: TextAlign.center, text: const TextSpan(
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2,
              shadows: [Shadow(color: Color(0x880A1628), blurRadius: 8)]),
            children: [
              TextSpan(text: 'Find the right ride\nfor ', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'your journey', style: TextStyle(color: Color(0xFFFFCC02))),
            ],
          )),
          const SizedBox(height: 10),
          const Text('Search trips between cities, compare options,\ncheck driver profiles and book your seat\nin just a few taps.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5,
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
          RichText(textAlign: TextAlign.center, text: const TextSpan(
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
            children: [
              TextSpan(text: 'Travel with ', style: TextStyle(color: Colors.white)),
              TextSpan(text: 'peace\n', style: TextStyle(color: Color(0xFFFFCC02))),
              TextSpan(text: 'of mind', style: TextStyle(color: Colors.white)),
            ],
          )),
          const SizedBox(height: 10),
          const Text('Live trip tracking, secure payments and\n24/7 support — we\'ve got you covered\nevery step of the way.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
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