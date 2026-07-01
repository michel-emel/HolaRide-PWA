import 'package:flutter/material.dart';
import '../services/auth_gate.dart';
import '../services/session_service.dart';
import 'home/home_screen.dart';
import 'bookings/my_bookings_screen.dart';
import 'chat/chat_inbox_screen.dart';
import 'driver/my_trips_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_form_screen.dart';

/// Hosts the bottom-nav tabs.
///
/// The tab set is auth-aware — guests get a 3-tab bar (Home, Route,
/// Login) since "My Trips"/"Chat"/"Profile" don't mean anything yet
/// without an account. Logged-in users get the full 4-tab set (Home,
/// My Trips, Chat, Profile). Tapping "Login" doesn't navigate anywhere
/// — there's nothing to show on that tab — it just triggers the same
/// login flow as everywhere else; once it succeeds, the bar swaps to
/// the logged-in set automatically.
///
/// On top of that, logged-in users also have a "driver mode" — see
/// `SessionService.isDriverMode`. It only changes which screen "My
/// Trips" actually shows: your own published trips (driver mode) or
/// your bookings (passenger mode, the default). Home, Chat, and
/// Profile stay the same either way — Chat already combines both
/// passenger and driver trips into one inbox, so it never needed to
/// change, and a dedicated driver Home wasn't asked for.
class MainTabScreen extends StatefulWidget {
  final int initialIndex;
  const MainTabScreen({super.key, this.initialIndex = 0});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  late int _index = widget.initialIndex;
  bool _loggedIn = false;
  bool _driverMode = false;

  /// Bumped every time the "My Trips" tab is tapped — both
  /// MyBookingsScreen and MyTripsScreen listen to this and reload
  /// when it changes. Needed because the tab bodies live inside an
  /// IndexedStack (kept alive for speed, not recreated on every tap),
  /// so their own initState() only ever runs once. Without this,
  /// something that changes the trip's state from elsewhere — most
  /// importantly the driver marking a trip "Completed" while the
  /// passenger already has My Trips open in the background — would
  /// never be reflected until the whole app restarts, which is
  /// exactly why the "Rate the driver" prompt could go missing.
  final ValueNotifier<int> _myTripsRefreshSignal = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _checkState();
    SessionService.instance.authChanged.addListener(_onAuthChanged);
    SessionService.instance.driverModeChanged.addListener(_onDriverModeChanged);
  }

  Future<void> _checkState() async {
    final loggedIn = await SessionService.instance.isLoggedIn();
    final driverMode = await SessionService.instance.isDriverMode();
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _driverMode = driverMode;
    });
  }

  void _onAuthChanged() async {
    if (!mounted) return;
    final loggedIn = await SessionService.instance.isLoggedIn();
    final driverMode = await SessionService.instance.isDriverMode();
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _driverMode = driverMode;
      // The guest and logged-in tab sets mean different things at the
      // same index (guest index 1 is "Route", logged-in index 1 is
      // "My Trips") — reset to Home whenever the set itself changes,
      // rather than leave whatever was selected pointing at something
      // unrelated.
      _index = 0;
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
    _myTripsRefreshSignal.dispose();
    super.dispose();
  }

  List<Widget> get _tabs => !_loggedIn
      ? const [
          HomeScreen(),
          SearchFormScreen(),
        ]
      : _driverMode
          ? [
              const HomeScreen(),
              MyTripsScreen(refreshSignal: _myTripsRefreshSignal),
              const ChatInboxScreen(),
              const ProfileScreen(),
            ]
          : [
              const HomeScreen(),
              MyBookingsScreen(refreshSignal: _myTripsRefreshSignal),
              const ChatInboxScreen(),
              const ProfileScreen(),
            ];

  List<BottomNavigationBarItem> get _items => !_loggedIn
      ? const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.route_outlined), activeIcon: Icon(Icons.route), label: 'Route'),
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
        ]
      : [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(_driverMode ? Icons.directions_car_outlined : Icons.list_alt_outlined),
            activeIcon: Icon(_driverMode ? Icons.directions_car : Icons.list_alt),
            label: 'My Trips',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];

  void _onTap(int i) {
    if (!_loggedIn && i == 2) {
      // "Login" — nothing to navigate to, just trigger the same gate
      // used everywhere else. currentIndex deliberately doesn't change,
      // so this tab never looks "selected."
      requireLogin(context);
      return;
    }
    if (i == 1) {
      _myTripsRefreshSignal.value++;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final safeIndex = _index < tabs.length ? _index : 0;
    return Scaffold(
      body: IndexedStack(index: safeIndex, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: _onTap,
        items: _items,
      ),
    );
  }
}
