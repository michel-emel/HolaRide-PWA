import 'package:flutter/material.dart';
import '../../models/trip.dart';
import '../../models/user.dart';
import '../../services/auth_gate.dart';
import '../../services/notification_service.dart';
import '../../services/session_service.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/profile_icon_button.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_form_screen.dart';
import '../trip/trip_detail_screen.dart';
import '../driver/driver_flow_router.dart';

/// Screen 5 — Home.
///
/// Header / greeting / hero / action tile / stat tiles are unchanged
/// from the previous pass — only "Available trips" (now with full
/// trip cards: avatar, driver name + rating, vehicle, route, the real
/// pickup/drop-off points, date, price, seats) and a new "Ride Share"
/// banner were added back in.
///
/// Both illustrations are real assets you're providing, not
/// generated/placeholder art:
/// - Empty-trips state: `assets/images/empty_trips_bg.png` (road +
///   trees), shown at reduced opacity as a soft backdrop behind the
///   message.
/// - Ride Share banner: `assets/images/ride_share_car.png` (car +
///   passengers + skyline), cropped to its right third via
///   `alignment: Alignment.centerRight` since the source image is
///   mostly empty cream space on the left with the actual scene
///   sitting on the right.
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
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    SessionService.instance.authChanged.addListener(_onAuthChanged);
    SessionService.instance.driverModeChanged.addListener(_onDriverModeChanged);
  }

  void _onAuthChanged() async {
    if (!mounted) return;
    final loggedIn = await SessionService.instance.isLoggedIn();
    final user = loggedIn ? await SessionService.instance.getUser() : null;
    final driverMode = await SessionService.instance.isDriverMode();
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _user = user;
      _driverMode = driverMode;
    });
  }

  void _onDriverModeChanged() async {
    if (!mounted) return;
    final driverMode = await SessionService.instance.isDriverMode();
    if (!mounted) return;
    setState(() => _driverMode = driverMode);
  }

  @override
  void dispose() {
    SessionService.instance.authChanged.removeListener(_onAuthChanged);
    SessionService.instance.driverModeChanged.removeListener(_onDriverModeChanged);
    super.dispose();
  }

  Future<void> _load() async {
    final loggedIn = await SessionService.instance.isLoggedIn();
    final user = loggedIn ? await SessionService.instance.getUser() : null;
    final driverMode = await SessionService.instance.isDriverMode();
    if (mounted) {
      setState(() {
        _loggedIn = loggedIn;
        _user = user;
        _driverMode = driverMode;
      });
    }
    try {
      final trips = await TripService.instance.search(limit: 3);
      if (!mounted) return;
      setState(() {
        _nearbyTrips = trips;
        _loadingTrips = false;
      });
      // Load unread count in parallel without blocking the trip list.
      if (loggedIn) {
        try {
          final count = await NotificationService.instance.getUnreadCount();
          if (mounted) setState(() => _unreadCount = count);
        } catch (_) {}
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/home/home_screen.dart: $e');
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load nearby trips.";
        _loadingTrips = false;
      });
    }
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (!_loggedIn) _buildGuestHeader(context),
          Expanded(
            child: SafeArea(
              top: _loggedIn,
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  children: [
                    if (_loggedIn) _buildSignedInGreeting(),
                    if (_loggedIn) const SizedBox(height: 14),
                    _buildHero(),
                    const SizedBox(height: 14),
                    _buildTripsSection(),
                    const SizedBox(height: 14),
                    // Guests haven't chosen a path yet, so both tiles
                    // stay visible — tapping either triggers the login
                    // gate first. Once logged in, only the action that
                    // actually matches the current mode shows: a
                    // passenger publishing a trip (or a driver
                    // searching for one as if they were a rider) isn't
                    // what either mode is for.
                    if (!_loggedIn)
                      Row(
                        children: [
                          Expanded(
                            child: _ActionTile(icon: Icons.search, label: 'Find a Ride', onTap: _openSearch),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionTile(
                              icon: Icons.add_road,
                              label: 'Ride Share',
                              onTap: () => openDriverFlow(context),
                            ),
                          ),
                        ],
                      )
                    else if (_driverMode)
                      _ActionTile(icon: Icons.add_road, label: 'Ride Share', onTap: () => openDriverFlow(context))
                    else
                      _ActionTile(icon: Icons.search, label: 'Find a Ride', onTap: _openSearch),
                    const SizedBox(height: 14),
                    // Hidden once already in driver mode — the action
                    // tile right above already IS "Ride Share" at that
                    // point, so showing this banner too would offer
                    // the same action twice on one screen.
                    if (!_driverMode) _buildRideShareBanner(),
                    if (!_driverMode) const SizedBox(height: 14),
                    // Marketing copy — placeholder numbers. Swap for real
                    // figures once you have usage data; there's no
                    // metrics endpoint backing these yet. They count up
                    // from 0 on open rather than just appearing.
                    const Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.groups_outlined,
                            targetValue: 15000,
                            label: 'Riders using the app',
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.alt_route,
                            targetValue: 40000,
                            label: 'Trip hours completed',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 18),
      decoration: const BoxDecoration(color: AppColors.background),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              children: [
                TextSpan(text: 'Hola', style: TextStyle(color: AppColors.textPrimary)),
                TextSpan(text: 'Ride', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => requireLogin(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            ),
            child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInGreeting() {
    final firstName = _user?.firstName ?? _user?.displayName;
    final greeting = (firstName != null && firstName.isNotEmpty) ? 'Hello $firstName 👋' : 'Hello 👋';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(greeting, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        GestureDetector(
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))
              .then((_) => _load()),
          child: Row(
            children: [
              Stack(
                children: [
                  const Icon(Icons.notifications_none, size: 26, color: AppColors.textPrimary),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: _unreadCount > 9 ? 16 : 14,
                        height: 14,
                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
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
              const SizedBox(width: 4),
              const ProfileIconButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/hero_car.png',
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background.withOpacity(0.97),
                    AppColors.background.withOpacity(0.55),
                    AppColors.background.withOpacity(0.05),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 24,
              top: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rides Going Your Way',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.1),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'HolaRide connects you with verified drivers making the same intercity trip — '
                    'so you travel on time and safely, for a fraction of what a private ride costs.',
                    style: TextStyle(color: AppColors.textPrimary.withOpacity(0.85), fontSize: 10.5, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Available trips ----

  Widget _buildTripsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Available trips', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: _openSearch,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primary,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See all', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTripsBody(),
      ],
    );
  }

  Widget _buildTripsBody() {
    if (_loadingTrips) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    if (_nearbyTrips.isEmpty) {
      return _buildEmptyTrips();
    }
    return Column(
      children: [
        for (final trip in _nearbyTrips) ...[
          _TripCard(
            trip: trip,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// Uses the real road/trees illustration you provided, at reduced
  /// opacity so it reads as a soft decorative backdrop behind the pin
  /// and text — matching how subtle it is in the reference mockup —
  /// rather than a fully saturated photo competing with the message.
  Widget _buildEmptyTrips() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 230,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/empty_trips_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                    child: const Icon(Icons.location_searching, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(height: 12),
                  const Text('No trips available right now',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Try a different route or check again later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _openSearch,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.infoBg,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Explore popular routes',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Ride Share banner — always visible, regardless of trip availability ----
  //
  // Uses the real car+passengers illustration you're placing at
  // assets/images/ride_share_car.png. That source image is mostly
  // empty cream space with the actual scene (car, people, trees,
  // skyline) sitting on its right third — so it's shown here in a
  // fixed-width box with `alignment: Alignment.centerRight`, which
  // crops in on that scene rather than stretching the whole wide
  // image (including its empty left half) into a small corner.
  Widget _buildRideShareBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Share your ride, reduce cost',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.primary)),
                  const SizedBox(height: 3),
                  const Text('Split your fare and travel together.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => openDriverFlow(context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Ride Share', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 110,
                height: 90,
                child: Image.asset(
                  'assets/images/ride_share_car.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.primary),
              ),
            ),
            const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

/// Counts up from 0 to [targetValue] once, the moment this tile first
/// appears on screen — the classic "odometer" effect for a stat like
/// "15K+ riders".
class _StatTile extends StatelessWidget {
  final IconData icon;
  final int targetValue;
  final String label;
  const _StatTile({required this.icon, required this.targetValue, required this.label});

  String _formatValue(int v) {
    if (v >= 1000000) {
      final millions = v / 1000000;
      return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M+';
    }
    if (v >= 1000) {
      return '${(v / 1000).round()}K+';
    }
    return '$v+';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: targetValue.toDouble()),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      _formatValue(value.round()),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                    );
                  },
                ),
                Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One trip card in "Available trips" — avatar (initial, since there's
/// no profile-photo field on the backend) + verified dot, driver name
/// + rating (only shown if the driver actually has reviews), vehicle
/// make/model, route, the actual pickup/drop-off points, date/time,
/// price per seat, and seats left.
class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const _TripCard({required this.trip, required this.onTap});

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime t) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${t.day} ${months[t.month - 1]}';
  }

  String _priceLabel(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf XAF';
  }

  @override
  Widget build(BuildContext context) {
    final initial = trip.driverName.isNotEmpty ? trip.driverName[0].toUpperCase() : '?';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                      child: Center(
                        child: Text(initial,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16)),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(trip.driverName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          ),
                          if (trip.driverRatingCount > 0) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.star, size: 13, color: AppColors.gold),
                            const SizedBox(width: 2),
                            Text(trip.driverRatingAverage!.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ],
                      ),
                      Text(trip.vehicleLabel,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${trip.originCity} → ${trip.destinationCity}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      if (trip.originLocation.isNotEmpty || trip.destinationLocation.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (trip.originLocation.isNotEmpty) ...[
                              const Icon(Icons.fiber_manual_record, size: 9, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(trip.originLocation,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              ),
                            ],
                            if (trip.originLocation.isNotEmpty && trip.destinationLocation.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.arrow_forward, size: 9, color: AppColors.textSecondary),
                              ),
                            if (trip.destinationLocation.isNotEmpty) ...[
                              const Icon(Icons.location_on, size: 10, color: AppColors.gold),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(trip.destinationLocation,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${_dateLabel(trip.departureTime)} · ${_timeLabel(trip.departureTime)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_priceLabel(trip.pricePerSeat),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
                    const Text('per seat', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                      child: Text('${trip.seatsAvailable} seats left',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
