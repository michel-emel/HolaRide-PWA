import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_gate.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import 'home/home_screen.dart';
import 'bookings/my_bookings_screen.dart';
import 'chat/chat_inbox_screen.dart';
import 'driver/my_trips_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_form_screen.dart';
import 'dart:async';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'trip/chat_screen.dart';

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

  final ValueNotifier<int> _myTripsRefreshSignal = ValueNotifier<int>(0);

  // Active trip chat FAB
  String? _activeTripId;
  String? _activeTripLabel;
  int _unreadCount = 0;
  Timer? _chatCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkState();
    SessionService.instance.authChanged.addListener(_onAuthChanged);
    SessionService.instance.driverModeChanged.addListener(_onDriverModeChanged);
  }

  Future<void> _startChatCheck() async {
    _chatCheckTimer?.cancel();
    _chatCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkActiveTrip());
    _checkActiveTrip();
  }

  Future<void> _checkActiveTrip() async {
    if (!_loggedIn || !mounted) return;
    try {
      final bookings = await BookingService.instance.myBookings();
      final active = bookings.where((b) => b.status == BookingStatus.paid).toList();
      if (!mounted) return;
      if (active.isEmpty) {
        setState(() { _activeTripId = null; _activeTripLabel = null; _unreadCount = 0; });
        return;
      }
      final b = active.first;
      final trip = b.trip;
      setState(() {
        _activeTripId = b.tripId ?? b.id;
        _activeTripLabel = trip != null
          ? '${trip.originCity} → ${trip.destinationCity}'
          : 'Active trip';
      });
    } catch (_) {}
  }

  Future<void> _checkState() async {
    final loggedIn = await SessionService.instance.isLoggedIn();
    final driverMode = await SessionService.instance.isDriverMode();
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _driverMode = driverMode;
    });
    if (loggedIn) _startChatCheck();
  }

  void _onAuthChanged() async {
    if (!mounted) return;
    final loggedIn = await SessionService.instance.isLoggedIn();
    final driverMode = await SessionService.instance.isDriverMode();
    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _driverMode = driverMode;
      _index = 0;
    });
    if (loggedIn) _startChatCheck();
    else { _chatCheckTimer?.cancel(); setState(() { _activeTripId = null; _activeTripLabel = null; }); }
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
    _chatCheckTimer?.cancel();
    super.dispose();
  }

  List<Widget> get _tabs => !_loggedIn
      ? const [HomeScreen(), SearchFormScreen()]
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

  List<BottomNavigationBarItem> _buildItems(AppLocalizations l) => !_loggedIn
      ? [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: l.tabHome),
          BottomNavigationBarItem(icon: const Icon(Icons.route_outlined), activeIcon: const Icon(Icons.route), label: l.tabRoute),
          BottomNavigationBarItem(icon: const Icon(Icons.login), label: l.tabLogin),
        ]
      : [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: l.tabHome),
          BottomNavigationBarItem(
            icon: Icon(_driverMode ? Icons.directions_car_outlined : Icons.list_alt_outlined),
            activeIcon: Icon(_driverMode ? Icons.directions_car : Icons.list_alt),
            label: l.tabMyTrips,
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline), label: l.tabChat),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: l.tabProfile),
        ];

  void _onTap(int i) {
    if (!_loggedIn && i == 2) {
      requireLogin(context);
      return;
    }
    if (i == 1) _myTripsRefreshSignal.value++;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tabs = _tabs;
    final safeIndex = _index < tabs.length ? _index : 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: safeIndex, children: tabs),
      floatingActionButton: (_activeTripId != null && safeIndex != 0)
          ? _TripChatFab(
              label: _activeTripLabel ?? 'Trip chat',
              unreadCount: _unreadCount,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChatScreen(tripId: _activeTripId!))),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: AppColors.textPrimary.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: safeIndex,
              onTap: _onTap,
              items: _buildItems(l),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripChatFab extends StatelessWidget {
  final String label;
  final int unreadCount;
  final VoidCallback onTap;
  const _TripChatFab({
    required this.label,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Aligned just above the floating pill nav bar, never over card content.
      padding: const EdgeInsets.only(bottom: 76),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline,
                          color: Colors.white, size: 17),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -2, top: -2,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}