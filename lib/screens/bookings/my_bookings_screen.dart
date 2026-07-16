import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
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
import '../trip/trip_detail_screen.dart';
import '../payment/payment_screen.dart';
import '../payment/pay_remaining_screen.dart';
import '../trip/waiting_for_driver_screen.dart';
import '../trip/chat_screen.dart';
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
  final Set<String> _hiddenBookingIds = {};

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
        _error = AppLocalizations.of(context).bookingsLoadError;
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
    final l = AppLocalizations.of(context);
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
                  trip != null ? '${trip.originCity} → ${trip.destinationCity}' : l.bookingsTripFallback,
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
            Text(
                booking.seats > 1
                    ? l.bookingsSeatPlural(booking.seats)
                    : l.bookingsSeatSingular(booking.seats),
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
                      label: Text(l.bookingsChat),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
                        );
                      },
                      icon: const Icon(Icons.my_location, size: 18),
                      label: Text(l.bookingsTrack),
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
    final l = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: buildAppHeader(l.bookingsTitle),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (!_loggedIn) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: buildAppHeader(l.bookingsTitle, showProfileIcon: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.list_alt_outlined, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 14),
                Text(l.bookingsLoginPrompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  l.bookingsLoginHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 18),
                PrimaryButton(label: l.bookingsLoginSignup, onPressed: _login),
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
          l.bookingsTitle,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: l.bookingsAll),
              Tab(text: l.bookingsUpcoming),
              Tab(text: l.bookingsPast),
            ],
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
    final l = AppLocalizations.of(context);
    final visible = bookings.where((b) => !_hiddenBookingIds.contains(b.id)).toList();

    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    if (_error != null) return RefreshIndicator(
      onRefresh: _load,
      child: ListView(children: [
        const SizedBox(height: 80),
        Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary))),
      ]));
    if (visible.isEmpty) return RefreshIndicator(
      onRefresh: _load,
      child: ListView(children: [
        const SizedBox(height: 80),
        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.border),
          const SizedBox(height: 12),
          Text(l.bookingsEmpty,
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ])),
      ]));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final b = visible[i];
          final trip = b.trip;
          final pending = _pendingByTrip[b.tripId] ?? const [];
          final isPast = !_upcomingStatuses.contains(b.status) 
          || b.status == BookingStatus.pendingPayment
          || b.status == BookingStatus.cancelled;
          
          return Dismissible(
            key: Key(b.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.delete_outline, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text('Remove', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ])),
            confirmDismiss: (_) async {
            if (isPast) {
              return true; // remove immediately
            }
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('Cancel booking?', style: TextStyle(fontWeight: FontWeight.w800)),
                content: const Text('This will cancel your booking. This action cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep', style: TextStyle(color: AppColors.textSecondary))),
                  FilledButton(onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                    child: const Text('Cancel booking')),
                ]));
            if (confirm == true) {
              try {
                await BookingService.instance.cancel(b.id);
                return true; // remove from UI
              } catch (_) {
                return false;
              }
            }
            return false;
          },
            child: InkWell(
              onTap: () => _openBooking(b),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04),
                    blurRadius: 8, offset: const Offset(0, 2))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header row: route + status badge
                  Row(children: [
                    Expanded(child: Text(
                      trip != null ? '${trip.originCity} → ${trip.destinationCity}' : l.bookingsTripFallback,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    StatusBadge(status: b.status),
                  ]),
                  // Pickup/dropoff
                  if (trip != null && trip.originLocation.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.fiber_manual_record, size: 9, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Expanded(child: Text(trip.originLocation, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
                    ]),
                  ],
                  if (trip != null && trip.destinationLocation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on, size: 10, color: AppColors.gold),
                      const SizedBox(width: 5),
                      Expanded(child: Text(trip.destinationLocation, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
                    ]),
                  ],
                  const SizedBox(height: 8),
                  // Date + price row
                  Row(children: [
                    if (trip != null) ...[
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('${_dateLabel(trip.departureTime)} · ${_timeLabel(trip.departureTime)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.event_seat_outlined, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(b.seats > 1 ? l.bookingsSeatPlural(b.seats) : l.bookingsSeatSingular(b.seats),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const Spacer(),
                    // Price
                    Text(_priceLabel(b.amountTotal),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary)),
                  ]),
                  // Rate badge
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _openRating(b),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const Icon(Icons.star_outline, size: 15, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(l.bookingsRatePassenger(pending.first.name),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5))),
                          const Icon(Icons.chevron_right, size: 15, color: AppColors.primary),
                        ])),
                    ),
                  ],
                  // Swipe hint for past bookings
                  if (isPast) ...[
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      const Icon(Icons.swipe_left_outlined, size: 12, color: AppColors.border),
                      const SizedBox(width: 4),
                      Text('Swipe to remove', style: TextStyle(fontSize: 10, color: AppColors.border)),
                    ]),
                  ],
                ]),
              ),
            ),
          );
        },
      ),
    );
  }

  String _priceLabel(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202f');
      buf.write(s[i]);
    }
    return '$buf XAF';
  }

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static const _monthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _monthsFr = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
  ];

  String _dateLabel(DateTime t) {
    final months = Localizations.localeOf(context).languageCode == 'fr'
        ? _monthsFr
        : _monthsEn;
    return '${t.day} ${months[t.month - 1]}';
  }
}
