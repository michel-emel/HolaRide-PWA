import 'package:flutter/material.dart';
import '../../models/trip.dart';
import '../../models/user.dart';
import '../../services/auth_gate.dart';
import '../../services/session_service.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../search/search_form_screen.dart';
import '../trip/trip_detail_screen.dart';
import '../driver/driver_flow_router.dart';

/// Screen 5 — Home.
///
/// The guest header (green bar, wordmark, "Get Started", profile icon)
/// matches the agreed design and is what guests specifically see —
/// logged-in users keep the existing greeting-row header for now,
/// since a dedicated passenger/driver header treatment is a separate,
/// later piece of work, not part of this pass.
///
/// The "Available Rides" cards intentionally don't show a driver
/// photo, name, or rating, even though the reference design includes
/// them — your backend's real trip-search response has no driver
/// field at all, and per-trip ratings aren't returned by search
/// either (ratings live on a person's profile, fetched separately).
/// Showing them here would mean making them up. What's shown instead
/// — route, date/time, vehicle category, price, seats left — is every
/// field that's actually real.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppUser? _user;
  bool _loggedIn = false;
  List<Trip> _nearbyTrips = [];
  bool _loadingTrips = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    SessionService.instance.authChanged.addListener(_onAuthChanged);
  }

  void _onAuthChanged() async {
    if (!mounted) return;
    final loggedIn = await SessionService.instance.isLoggedIn();
    final user = loggedIn ? await SessionService.instance.getUser() : null;
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _user = user;
    });
  }

  @override
  void dispose() {
    SessionService.instance.authChanged.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _load() async {
    final loggedIn = await SessionService.instance.isLoggedIn();
    final user = loggedIn ? await SessionService.instance.getUser() : null;
    if (mounted) {
      setState(() {
        _loggedIn = loggedIn;
        _user = user;
      });
    }
    try {
      final trips = await TripService.instance.search(limit: 3);
      if (!mounted) return;
      setState(() {
        _nearbyTrips = trips;
        _loadingTrips = false;
      });
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
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_loggedIn) _buildSignedInGreeting(),
                    if (_loggedIn) const SizedBox(height: 20),
                    _buildHero(),
                    const SizedBox(height: 26),
                    _buildAvailableRidesHeader(),
                    const SizedBox(height: 12),
                    _buildRidesList(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.search,
                            label: 'Find a Ride',
                            onTap: _openSearch,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.add_road,
                            label: 'Publish Trip',
                            onTap: () => openDriverFlow(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Marketing copy — placeholder numbers. Swap for real
                    // figures once you have usage data; there's no
                    // metrics endpoint backing these yet.
                    const Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.groups_outlined,
                            value: '15K+',
                            label: 'Riders using the app',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.alt_route,
                            value: '40K+',
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
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'HolaRide',
              style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
          ElevatedButton(
            onPressed: () => requireLogin(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.primary,
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => requireLogin(context),
            customBorder: const CircleBorder(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.6)),
              ),
              child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
            ),
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
        Stack(
          children: [
            const Icon(Icons.notifications_none, size: 26, color: AppColors.textPrimary),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHero() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rides Going\nYour Way',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.15),
        ),
        SizedBox(height: 10),
        Text(
          'HolaRide connects you with verified drivers making the same intercity trip — so you travel on time and safely, for a fraction of what a private ride costs.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildAvailableRidesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Available Rides',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
        TextButton(
          onPressed: _openSearch,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('See all'),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRidesList() {
    if (_loadingTrips) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Be among our first riders — no trips published near you yet.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Column(
      children: _nearbyTrips
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RideCard(
                trip: t,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: t.id)),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const _RideCard({required this.trip, required this.onTap});

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
              child: const Icon(Icons.directions_car, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trip.originCity} → ${trip.destinationCity}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${_dateLabel(trip.departureTime)} · ${_timeLabel(trip.departureTime)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (trip.vehicleCategory.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.directions_car_outlined, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(trip.vehicleCategory,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _priceLabel(trip.pricePerSeat),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary),
                ),
                const Text('per seat', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${trip.seatsAvailable} left',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ],
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

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatTile({required this.icon, required this.value, required this.label});

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
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
                Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}