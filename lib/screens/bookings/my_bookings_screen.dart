import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/review.dart';
import '../../services/auth_gate.dart';
import '../../services/booking_service.dart';
import '../../services/review_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/profile_icon_button.dart';
import '../../widgets/status_badge.dart';
import '../payment/payment_screen.dart';
import '../payment/pay_remaining_screen.dart';
import '../trip/waiting_for_driver_screen.dart';
import '../trip/chat_screen.dart';
import '../trip/live_tracking_screen.dart';
import '../trip/rate_trip_screen.dart';
import 'cancel_withdraw_screen.dart';
import 'rebook_screen.dart';

/// Screen 14 — My Bookings.
///
/// Guests (no account yet) see a login prompt here instead of an
/// empty/erroring list — there's nothing to fetch without an account.
class MyBookingsScreen extends StatefulWidget {
  /// Bumped by MainTabScreen every time this tab is tapped, since this
  /// screen lives inside an IndexedStack and otherwise only ever loads
  /// once, regardless of what changed elsewhere (e.g. a driver marking
  /// a trip "Completed") while this tab sat in the background.
  final ValueListenable<int>? refreshSignal;
  const MyBookingsScreen({super.key, this.refreshSignal});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Booking> _bookings = [];
  bool _loading = true;
  bool _loggedIn = false;
  String? _error;

  /// Who's still left to rate, per completed trip — checked once
  /// after loading the booking list, so the "Rate" badge shows up
  /// permanently on the booking card itself, not only as a one-time
  /// popup that's easy to miss if you tap away from it.
  final Map<String, List<PendingReview>> _pendingByTrip = {};

  static const _upcomingStatuses = {
    BookingStatus.pendingDriverAcceptance,
    BookingStatus.pendingPayment,
    BookingStatus.paid,
  };

  @override
  void initState() {
    super.initState();
    _load();
    SessionService.instance.authChanged.addListener(_onAuthChanged);
    widget.refreshSignal?.addListener(_onRefreshSignal);
  }

  void _onAuthChanged() {
    if (mounted) _load();
  }

  void _onRefreshSignal() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    SessionService.instance.authChanged.removeListener(_onAuthChanged);
    widget.refreshSignal?.removeListener(_onRefreshSignal);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final loggedIn = await SessionService.instance.isLoggedIn();
    if (!mounted) return;
    if (!loggedIn) {
      setState(() {
        _loggedIn = false;
        _bookings = [];
        _loading = false;
      });
      return;
    }
    try {
      final bookings = await BookingService.instance.myBookings();
      if (!mounted) return;
      // Most recent first.
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _loggedIn = true;
        _bookings = bookings;
        _loading = false;
      });
      _loadPendingReviews(bookings);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/bookings/my_bookings_screen.dart: $e');
      if (!mounted) return;
      setState(() {
        _loggedIn = true;
        _error = "Couldn't load your bookings.";
        _loading = false;
      });
    }
  }

  Future<void> _login() async {
    final success = await requireLogin(context);
    if (success) _load();
  }

  /// Only checked for completed bookings with a real trip id — no
  /// point asking the backend about anything still in progress. Runs
  /// in parallel rather than one request at a time.
  Future<void> _loadPendingReviews(List<Booking> bookings) async {
    final completed = bookings
        .where((b) => b.status == BookingStatus.completed && b.tripId != null && b.tripId!.isNotEmpty)
        .toList();
    if (completed.isEmpty) return;
    final results = await Future.wait(
      completed.map((b) async {
        try {
          final pending = await ReviewService.instance.getPendingReviews(b.tripId!);
          return MapEntry(b.tripId!, pending);
        } catch (e) {
          // ignore: avoid_print
          print('Error in lib/screens/bookings/my_bookings_screen.dart (pending): $e');
          return MapEntry(b.tripId!, <PendingReview>[]);
        }
      }),
    );
    if (!mounted) return;
    setState(() {
      _pendingByTrip
        ..clear()
        ..addEntries(results);
    });
  }

  void _openRating(Booking booking) {
    final pending = _pendingByTrip[booking.tripId] ?? const [];
    if (pending.isEmpty) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => RateTripScreen(
              tripId: booking.tripId!,
              targets: pending.map((p) => RateTarget(id: p.userId, name: p.name, role: p.role)).toList(),
            ),
          ),
        )
        .then((_) => _load());
  }

  Future<void> _openBooking(Booking booking) async {
    if (booking.status == BookingStatus.pendingDriverAcceptance && booking.trip != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WaitingForDriverScreen(trip: booking.trip!, booking: booking),
        ),
      );
    } else if (booking.status == BookingStatus.pendingPayment && booking.trip != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PaymentScreen(trip: booking.trip!, booking: booking)),
      );
    } else if (booking.status == BookingStatus.paid && booking.amountDue > 0) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => PayRemainingScreen(booking: booking)),
      );
      if (result == true) _load();
    } else if (booking.status == BookingStatus.cancelled && booking.trip != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RebookScreen(trip: booking.trip!)),
      );
    } else if (booking.status == BookingStatus.completed && booking.tripId != null) {
      final pending = _pendingByTrip[booking.tripId];
      if (pending != null && pending.isNotEmpty) {
        _openRating(booking);
        return;
      }
      _showSummary(booking);
    } else {
      _showSummary(booking);
    }
  }

  void _showSummary(Booking booking) {
    final trip = booking.trip;
    final canChat = booking.status == BookingStatus.paid || booking.status == BookingStatus.completed;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trip != null ? '${trip.originCity} → ${trip.destinationCity}' : 'Trip',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                StatusBadge(status: booking.status),
              ],
            ),
            if (trip != null && trip.originLocation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.fiber_manual_record, size: 10, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(trip.originLocation,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            if (trip != null && trip.destinationLocation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 11, color: AppColors.gold),
                  const SizedBox(width: 5),
                  Text(trip.destinationLocation,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            if (trip != null) ...[
              const SizedBox(height: 4),
              Text(
                '${_dateLabel(trip.departureTime)} · ${_timeLabel(trip.departureTime)}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 10),
            Text('${booking.seats} seat${booking.seats > 1 ? 's' : ''}',
                style: const TextStyle(color: AppColors.textSecondary)),
            if (canChat && trip != null) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(tripId: booking.tripId ?? trip.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => LiveTrackingScreen(trip: trip)),
                        );
                      },
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Track'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrWithdraw(Booking booking) async {
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CancelWithdrawScreen(trip: booking.trip, booking: booking),
      ),
    );
    if (confirmed == true) _load();
  }

  bool _canCancel(Booking b) => _upcomingStatuses.contains(b.status);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: buildAppHeader('My Trips'),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (!_loggedIn) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: buildAppHeader('My Trips', showProfileIcon: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.list_alt_outlined, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 14),
                const Text('Log in to see your bookings',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                const Text(
                  'Your trip requests and booking history will show up here once you log in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 18),
                PrimaryButton(label: 'Log in / Sign up', onPressed: _login),
              ],
            ),
          ),
        ),
      );
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: buildAppHeader(
          'My Trips',
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'All'), Tab(text: 'Upcoming'), Tab(text: 'Past')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(_bookings),
            _buildList(_bookings.where((b) => _upcomingStatuses.contains(b.status)).toList()),
            _buildList(_bookings.where((b) => !_upcomingStatuses.contains(b.status)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Booking> bookings) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary))),
          ],
        ),
      );
    }
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            Center(
              child: Text('No bookings here yet.', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final b = bookings[i];
          final trip = b.trip;
          final pending = _pendingByTrip[b.tripId] ?? const [];
          return InkWell(
            onTap: () => _openBooking(b),
            onLongPress: _canCancel(b) ? () => _cancelOrWithdraw(b) : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip != null ? '${trip.originCity} → ${trip.destinationCity}' : 'Trip',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            if (trip != null && trip.originLocation.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.fiber_manual_record, size: 9, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      trip.originLocation,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (trip != null && trip.destinationLocation.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 10, color: AppColors.gold),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      trip.destinationLocation,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            if (trip != null)
                              Text(
                                '${_dateLabel(trip.departureTime)} · ${_timeLabel(trip.departureTime)}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                              ),
                            const SizedBox(height: 2),
                            Text('${b.seats} seat${b.seats > 1 ? 's' : ''}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      StatusBadge(status: b.status),
                    ],
                  ),
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _openRating(b),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.star_outline, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Rate ${pending.first.name}',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime t) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${t.day} ${months[t.month - 1]}';
  }
}
