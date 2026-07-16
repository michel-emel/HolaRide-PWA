import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/trip.dart';
import '../../models/user.dart';
import '../../services/auth_gate.dart';
import '../../services/notification_service.dart';
import '../../services/session_service.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/profile_icon_button.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/language_switcher.dart';
import '../search/search_form_screen.dart';
import '../trip/trip_detail_screen.dart';
import '../driver/driver_flow_router.dart';
import '../../services/locale_service.dart';
import '../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppUser? _user;
  bool _loggedIn = false;
  bool _driverMode = false;
  List<Trip> _nearbyTrips = [];
  bool _loadingTrips = true;
  String? _error;
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  Timer? _timer;
  static const int _perPage = 2;

  // ── Hero banner state ─────────────────────────────────────────
  final PageController _heroCtrl = PageController();
  int _heroPage = 0;
  bool _heroForward = true; // ping-pong direction
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _load();
    SessionService.instance.authChanged.addListener(_onAuth);
    SessionService.instance.driverModeChanged.addListener(_onDriverMode);
    Future.delayed(const Duration(seconds: 3), _maybeShowPopup);
    // Auto-swipe hero every 3 seconds (ping-pong between first and last)
    _heroTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_heroCtrl.hasClients) return;

      const lastIndex = 3; // 4 slides → index 0 à 3

      if (_heroForward) {
        if (_heroPage >= lastIndex) {
          _heroForward = false; // on inverse la direction
          _heroCtrl.previousPage(
              duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        } else {
          _heroCtrl.nextPage(
              duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      } else {
        if (_heroPage <= 0) {
          _heroForward = true; // on inverse la direction
          _heroCtrl.nextPage(
              duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        } else {
          _heroCtrl.previousPage(
              duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      }
    });
  }

  void _onAuth() async {
    if (!mounted) return;
    final loggedIn = await SessionService.instance.isLoggedIn();
    final user = loggedIn ? await SessionService.instance.getUser() : null;
    final dm = await SessionService.instance.isDriverMode();
    if (!mounted) return;
    setState(() { _loggedIn = loggedIn; _user = user; _driverMode = dm; });
  }

  void _onDriverMode() async {
    if (!mounted) return;
    final dm = await SessionService.instance.isDriverMode();
    if (!mounted) return;
    setState(() => _driverMode = dm);
  }

  @override
  void dispose() {
    SessionService.instance.authChanged.removeListener(_onAuth);
    SessionService.instance.driverModeChanged.removeListener(_onDriverMode);
    _timer?.cancel();
    _heroTimer?.cancel();
    _pageCtrl.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loggedIn = await SessionService.instance.isLoggedIn();
    final user = loggedIn ? await SessionService.instance.getUser() : null;
    final dm = await SessionService.instance.isDriverMode();
    if (mounted) setState(() { _loggedIn = loggedIn; _user = user; _driverMode = dm; });
    try {
      final trips = await TripService.instance.search(limit: 10);
      if (!mounted) return;
      setState(() { _nearbyTrips = trips; _loadingTrips = false; });
      if (trips.isNotEmpty) {
        _timer = Timer.periodic(const Duration(seconds: 3), (_) {
          if (!mounted || !_pageCtrl.hasClients) return;
          final pageCount = (trips.length / _perPage).ceil();
          _pageCtrl.animateToPage((_currentPage + 1) % pageCount,
              duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        });
      }
      if (loggedIn) {
        try {
          await NotificationService.instance.getUnreadCount();
        } catch (_) {}
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Could not load trips.'; _loadingTrips = false; });
    }
  }

  void _maybeShowPopup() async {
    if (!mounted) return;
    final loggedIn = await SessionService.instance.isLoggedIn();
    if (!mounted || loggedIn) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56,
            decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
            child: const Icon(Icons.eco, color: AppColors.primary, size: 28)),
          const SizedBox(height: 14),
          const Text('Join HolaRide', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 6),
          const Text('Sign in to book trips and connect with verified drivers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: () { Navigator.of(context).pop(); requireLogin(context); },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w700)))),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe later', style: TextStyle(color: AppColors.textSecondary))),
        ]),
      ),
    );
  }

  void _openSearch() => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SearchFormScreen()));

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────
        Container(
          color: AppColors.background,
          padding: EdgeInsets.fromLTRB(20, top + 12, 16, 12),
          child: Row(children: [
            // Logo
            RichText(text: const TextSpan(
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.3),
              children: [
                TextSpan(text: 'Hola', style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(text: 'Ride', style: TextStyle(color: AppColors.primary)),
              ],
            )),
            const Spacer(),
            // Language pill — shows flag + "English" + chevron
            ValueListenableBuilder<Locale>(
              valueListenable: localeNotifier,
              builder: (_, locale, __) {
                final isFr = locale.languageCode == 'fr';
                return GestureDetector(
                  onTap: () => LocaleService.setLocale(Locale(isFr ? 'en' : 'fr')),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(isFr ? '🇫🇷' : '🇬🇧', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(isFr ? 'Français' : 'English',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ])));
              }),
            const SizedBox(width: 10),
            if (_loggedIn) ...[
              const NotificationBell(),
              const SizedBox(width: 6),
              const ProfileIconButton(),
            ] else
              Stack(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border)),
                  child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.textSecondary)),
                Positioned(right: 8, top: 8,
                  child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
              ]),
          ]),
        ),

        // ── Scrollable body ──────────────────────────────────────
        Expanded(child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 4, 16, bottom + 90),
            children: [
              // ── Hero banner ─────────────────────────────────────
              _buildHero(),
              const SizedBox(height: 20),

              // ── Available trips ──────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Available trips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                GestureDetector(
                  onTap: _openSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('See all', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.primary),
                    ]))),
              ]),
              const SizedBox(height: 12),
              _buildTripsBody(),
              const SizedBox(height: 16),

              // ── Find & Offer ──────────────────────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _buildFindCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildOfferCard()),
              ]),
              const SizedBox(height: 14),

              // ── Ride together ────────────────────────────────────
              _buildRideTogetherBanner(),
              const SizedBox(height: 14),

              // ── Stats ────────────────────────────────────────────
              _buildStats(),
            ],
          ),
        )),
      ]),
    );
  }

  // ── Hero banner with page swipe + dots ──────────────────────
  Widget _buildHero() {
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 200,
          child: PageView(
            controller: _heroCtrl,
            onPageChanged: (i) => setState(() => _heroPage = i),
            children: [
              _heroSlide('Rides Going\nYour Way',
                  'HolaRide connects you with verified drivers making the same intercity trip.'),
              _heroSlide('Travel Smarter,\nSave More',
                  'Share the cost with fellow travelers going your way.'),
              _heroSlide('Safe &\nReliable',
                  'All drivers are verified. Your safety is our priority.'),
              _heroSlide('Across\nCameroon',
                  'Yaoundé, Douala, Bafoussam and more destinations.'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _heroPage == i ? 20 : 7, height: 7,
          decoration: BoxDecoration(
            color: _heroPage == i ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4))))),
    ]);
  }

  Widget _heroSlide(String title, String sub) {
    return Stack(fit: StackFit.expand, children: [
      Image.asset('assets/images/hero_banner.png', fit: BoxFit.cover),
      Container(decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.centerLeft, end: Alignment.centerRight,
        stops: [0.0, 0.5, 0.85],
        colors: [Color(0xF0E8F5E9), Color(0xCCE8F5E9), Color(0x00E8F5E9)],
      ))),
      Positioned(left: 16, top: 16, bottom: 16, width: 195, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
            color: Color(0xFF1B6B45), height: 1.15)),
          const SizedBox(height: 8),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
          const Spacer(),
          // Smaller "Get Started" button
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: _openSearch,
              icon: const Icon(Icons.arrow_forward, size: 13),
              label: const Text('Get Started'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B6B45),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
          ),
        ],
      )),
    ]);
  }

  // ── Find a Ride card ──────────────────────────────────────────
  // Compact flat card: icon badge + title on the same row, arrow
  // top-right, then a fixed 2-line description zone below. Both
  // cards share the exact same skeleton, so they always come out
  // the same height — no fixed `height:` and no Spacer() reserving
  // empty space.
  Widget _buildFindCard() {
    const green = Color(0xFF1B6B45);
    return _ActionCard(
      color: green,
      icon: Icons.search_rounded,
      title: 'Find a Ride',
      subtitle: 'Search for rides to your destination',
      onTap: _openSearch,
    );
  }

  // ── Offer a Ride card ─────────────────────────────────────────
  Widget _buildOfferCard() {
    // A steady blue reads as trustworthy/professional for an intercity
    // rideshare context, and sits well next to the green Find card.
    const blue = Color(0xFF1F5C8B);
    return _ActionCard(
      color: blue,
      icon: Icons.directions_car,
      title: 'Offer a Ride',
      subtitle: 'Post your trip and fill your empty seats',
      onTap: () => openDriverFlow(context),
    );
  }

  // ── Ride together banner ──────────────────────────────────────
  Widget _buildRideTogetherBanner() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      // learn_more.png now fills the whole banner — no separate
      // left image box.
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/learn_more.png', fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ride together, save more',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFF1B6B45),
                    fontWeight: FontWeight.w800, fontSize: 15, height: 1.15)),
                const SizedBox(height: 6),
                const Text('Share your ride, split\nthe fare and reduce cost.',
                  style: TextStyle(color: AppColors.textSecondary,
                    fontSize: 13, height: 1.3)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => openDriverFlow(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    backgroundColor: AppColors.surface,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Learn More', style: TextStyle(color: Color(0xFF1B6B45),
                      fontWeight: FontWeight.w700, fontSize: 11)),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward, size: 12, color: Color(0xFF1B6B45)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────
  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Expanded(child: Row(children: [
          Container(width: 44, height: 44,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.groups_outlined, color: Colors.white, size: 22)),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('15K+', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary)),
            Text('Happy riders\nusing HolaRide', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, height: 1.3)),
          ]),
        ])),
        Container(height: 44, width: 1, color: AppColors.border),
        Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 44, height: 44,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.route_outlined, color: Colors.white, size: 22)),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('40K+', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary)),
            Text('Trip hours\ncompleted', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, height: 1.3)),
          ]),
        ])),
      ]),
    );
  }

  // ── Trips ─────────────────────────────────────────────────────
  Widget _buildTripsBody() {
    if (_loadingTrips) return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border)),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary)));
    if (_error != null) return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        const Icon(Icons.wifi_off_outlined, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
      ]));
    if (_nearbyTrips.isEmpty) return _buildEmptyTrips();
    // Horizontal scroll — one card per swipe
    return Column(children: [
      SizedBox(
        height: 145,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          itemCount: _nearbyTrips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (ctx, i) => SizedBox(
            width: MediaQuery.of(ctx).size.width - 48,
            child: _TripCard(
              trip: _nearbyTrips[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: _nearbyTrips[i].id))))),
        )),
      const SizedBox(height: 8),
      // Trip count indicator
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
          child: Text('${_nearbyTrips.length} trip${_nearbyTrips.length > 1 ? 's' : ''} available',
            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600))),
      ]),
    ]);
  }

  Widget _buildEmptyTrips() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        child: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/empty_trips_bg.png', fit: BoxFit.cover),
          // Subtle white overlay so text is readable
          Container(color: Colors.white.withOpacity(.55)),
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(.2), width: 1.5)),
              child: const Icon(Icons.directions_car_outlined, color: AppColors.primary, size: 28)),
            const SizedBox(height: 14),
            const Text('No trips available right now',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Try a different route or check again later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _openSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('Explore popular routes',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          ])),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ACTION CARD — compact Find/Offer card
// ══════════════════════════════════════════════
class _ActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge + title on the same line, arrow on the right —
            // title now sits at the same vertical level as the logo.
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14.5)),
              ),
              const SizedBox(width: 8),
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.2))),
                child: Icon(Icons.arrow_forward, size: 13, color: color),
              ),
            ]),
            const SizedBox(height: 10),
            // Fixed 2-line zone so both cards always match in height,
            // even if one description wraps to a single line.
            SizedBox(
              height: 34,
              child: Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// TRIP CARD — Professional horizontal scroll card
// ══════════════════════════════════════════════
class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const _TripCard({required this.trip, required this.onTap});

  String _t(DateTime t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  String _d(DateTime t) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${t.day} ${m[t.month-1]}';
  }
  String _p(num v) {
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return '$b XAF';
  }

  @override
  Widget build(BuildContext context) {
    final initial = trip.driverName.isNotEmpty ? trip.driverName[0].toUpperCase() : '?';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Row 1: Route + Price
          Row(children: [
            Expanded(child: Text('${trip.originCity} → ${trip.destinationCity}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_p(trip.pricePerSeat),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary)),
              const Text('per seat', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
            ]),
          ]),
          const SizedBox(height: 4),
          // Date + time
          Row(children: [
            const Icon(Icons.schedule_outlined, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${_d(trip.departureTime)} · ${_t(trip.departureTime)}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ]),
          const Divider(height: 16),
          // Row 2: Driver + Seats badge
          Row(children: [
            // Avatar
            Stack(children: [
              Container(width: 36, height: 36,
                decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                child: Center(child: Text(initial,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 15)))),
              Positioned(right: 0, bottom: 0, child: Container(width: 11, height: 11,
                decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5)))),
            ]),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(trip.driverName, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                if (trip.driverRatingCount > 0) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                  Text(' ${trip.driverRatingAverage!.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ],
              ]),
              Text(trip.vehicleLabel, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            // Seats badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.event_seat_outlined, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('${trip.seatsAvailable} left',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ])),
          ]),
        ]),
      ),
    );
  }
}