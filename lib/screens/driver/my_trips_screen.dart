import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/date_labels.dart';
import '../../models/booking.dart';
import '../../models/review.dart';
import '../../models/trip.dart';
import '../../services/driver_service.dart';
import '../../services/review_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import 'create_trip_screen.dart';
import 'trip_management_screen.dart';
import '../trip/rate_trip_screen.dart';

/// Screen 20 — My Trips (driver).
class MyTripsScreen extends StatefulWidget {
  /// Bumped by MainTabScreen every time this tab is tapped — see the
  /// same parameter on MyBookingsScreen for why this is needed.
  final ValueListenable<int>? refreshSignal;
  const MyTripsScreen({super.key, this.refreshSignal});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  List<Trip> _trips = [];
  bool _loading = true;
  String? _error;

  /// Who's still left to rate, per completed trip — checked once
  /// after loading the trip list, so the "Rate" button shows up
  /// permanently on the trip card itself rather than only existing as
  /// a one-time popup right after tapping "Mark Completed". Without
  /// this, there'd be no way back in if that moment was missed.
  final Map<String, List<PendingReview>> _pendingByTrip = {};

  /// Request / booked-seat counters per trip — powers the red badge
  /// and the footer hint on each card.
  final Map<String, _TripCounts> _countsByTrip = {};

  @override
  void initState() {
    super.initState();
    _load();
    widget.refreshSignal?.addListener(_onRefreshSignal);
  }

  void _onRefreshSignal() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onRefreshSignal);
    super.dispose();
  }

  /// A trip counts as "Past" the moment its outcome is settled —
  /// completed or cancelled — not just once its scheduled departure
  /// time has elapsed. Without this, marking a trip "Completed" did
  /// nothing visible: it would just sit in "Upcoming" until the clock
  /// happened to catch up to its departure time.
  bool _isPast(Trip t) {
    final status = t.status.toLowerCase();
    if (status == 'completed' || status == 'cancelled') return true;
    return !t.departureTime.isAfter(DateTime.now());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await DriverService.instance.myTrips();
      trips.sort((a, b) => b.departureTime.compareTo(a.departureTime));
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _loading = false;
      });
      _loadPendingReviews(trips);
      _loadCounts(trips);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/my_trips_screen.dart: $e');
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load your trips.";
        _loading = false;
      });
    }
  }

  /// Only checked for trips that are actually completed — no point
  /// asking the backend about ones still upcoming. Runs in parallel
  /// rather than one request at a time, since a driver could easily
  /// have a dozen past trips in this list.
  Future<void> _loadPendingReviews(List<Trip> trips) async {
    final completedTrips = trips.where((t) => t.status.toLowerCase() == 'completed').toList();
    if (completedTrips.isEmpty) return;
    final results = await Future.wait(
      completedTrips.map((t) async {
        try {
          final pending = await ReviewService.instance.getPendingReviews(t.id);
          return MapEntry(t.id, pending);
        } catch (e) {
          // ignore: avoid_print
          print('Error in lib/screens/driver/my_trips_screen.dart (pending): $e');
          return MapEntry(t.id, <PendingReview>[]);
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

  /// Fetches the bookings of each ACTIVE trip (a driver has at most
  /// one, so this stays cheap) and derives: how many requests are
  /// waiting for an answer, and how many seats are already booked.
  /// Past trips are skipped — their counters no longer matter.
  Future<void> _loadCounts(List<Trip> trips) async {
    final active = trips.where((t) => !_isPast(t)).toList();
    if (active.isEmpty) return;
    final results = await Future.wait(
      active.map((t) async {
        try {
          final bookings = await DriverService.instance.tripBookings(t.id);
          final requests =
              bookings.where((b) => b.status == BookingStatus.pendingDriverAcceptance).length;
          final seatsBooked = bookings
              .where((b) => b.status == BookingStatus.paid || b.status == BookingStatus.completed)
              .fold<int>(0, (s, b) => s + b.seats);
          return MapEntry(t.id, _TripCounts(requests: requests, seatsBooked: seatsBooked));
        } catch (e) {
          // ignore: avoid_print
          print('Error in lib/screens/driver/my_trips_screen.dart (counts): $e');
          return MapEntry(t.id, const _TripCounts(requests: 0, seatsBooked: 0));
        }
      }),
    );
    if (!mounted) return;
    setState(() {
      _countsByTrip
        ..clear()
        ..addEntries(results);
    });
  }

  void _openRating(Trip trip) {
    final pending = _pendingByTrip[trip.id] ?? const [];
    if (pending.isEmpty) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => RateTripScreen(
              tripId: trip.id,
              targets: pending.map((p) => RateTarget(id: p.userId, name: p.name, role: p.role)).toList(),
            ),
          ),
        )
        .then((_) => _load());
  }

  String _money(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf XAF';
  }

  String _dateLabel(DateTime t) => '${t.day} ${monthAbbrev(context, t.month)} ${t.year}';

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'scheduled':
      case 'ongoing':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      case 'completed':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: buildAppHeader(
          l.bookingsTitle,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            tabs: [Tab(text: l.driverMyTripsUpcoming), Tab(text: l.driverMyTripsPast)],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(_trips.where((t) => !_isPast(t)).toList(), upcoming: true),
            _buildList(_trips.where(_isPast).toList(), upcoming: false),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateTripScreen()),
              ).then((_) => _load()),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF2D9E6E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.driverMyTripsCreate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              // TODO(l10n): move to app_localizations
                              'Publish your seats and start earning',
                              style: TextStyle(color: Colors.white.withOpacity(.85), fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Trip> trips, {required bool upcoming}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(children: [
                const Icon(Icons.wifi_off_outlined, size: 44, color: AppColors.border),
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
              ]),
            ),
          ],
        ),
      );
    }
    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 70),
            Center(
              child: Column(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.infoBg.withOpacity(.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    upcoming ? Icons.directions_car_outlined : Icons.history,
                    size: 32, color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context).driverMyTripsEmpty,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                Text(
                  upcoming
                      ? 'Publish a trip and fill your empty seats.'
                      : 'Your completed and cancelled trips will appear here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ]),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildTripCard(trips[i]),
      ),
    );
  }

  Widget _buildTripCard(Trip t) {
    final pending = _pendingByTrip[t.id] ?? const [];
    final past = _isPast(t);
    final stColor = _statusColor(t.displayStatus);
    final isOngoing = t.status.toLowerCase() == 'ongoing';
    final counts = _countsByTrip[t.id];
    final requestCount = counts?.requests ?? 0;
    final seatsBooked = counts?.seatsBooked ?? 0;

    return InkWell(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => TripManagementScreen(trip: t)))
          .then((_) => _load()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          // Past trips: quieter (flat border); upcoming: elevated.
          border: past ? Border.all(color: AppColors.border) : null,
          boxShadow: past
              ? null
              : [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route + status badge
            Row(children: [
              Expanded(
                child: Text('${t.originCity} → ${t.destinationCity}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  // Red notification badge: requests waiting for an answer.
                  if (requestCount > 0) ...[
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$requestCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: stColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(color: stColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(t.displayStatus,
                          style: TextStyle(color: stColor, fontSize: 11.5, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ]),
                // Booked seats live right under the status badge — kept
                // apart from the date/price chips so they can't be
                // mistaken for plain trip details.
                if (seatsBooked > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.person, size: 11, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('$seatsBooked booked',
                          style: const TextStyle(
                              fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ]),
                  ),
                ],
              ]),
            ]),

            // Pickup / drop-off points
            if (t.originLocation.isNotEmpty || t.destinationLocation.isNotEmpty) ...[
              const SizedBox(height: 10),
              if (t.originLocation.isNotEmpty)
                Row(children: [
                  const Icon(Icons.location_on, size: 15, color: AppColors.primary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(t.originLocation,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                ]),
              if (t.originLocation.isNotEmpty && t.destinationLocation.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 6.5),
                  child: SizedBox(
                    height: 10,
                    child: Column(
                      children: List.generate(2, (_) => Expanded(
                        child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 1),
                            color: AppColors.border),
                      )),
                    ),
                  ),
                ),
              if (t.destinationLocation.isNotEmpty)
                Row(children: [
                  const Icon(Icons.location_on, size: 15, color: AppColors.danger),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(t.destinationLocation,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                ]),
            ],

            const SizedBox(height: 12),

            // Meta chips
            Wrap(spacing: 8, runSpacing: 8, children: [
              _MetaChip(icon: Icons.calendar_month_outlined, label: _dateLabel(t.departureTime)),
              _MetaChip(icon: Icons.schedule, label: _timeLabel(t.departureTime)),
              _MetaChip(icon: Icons.event_seat_outlined, label: '${t.seatsAvailable} left'),
              _MetaChip(icon: Icons.payments_outlined, label: _money(t.pricePerSeat)),
            ]),

            // Rating banner (completed trips with pending reviews)
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openRating(t),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold.withOpacity(.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pending.length == 1
                              ? AppLocalizations.of(context).driverRateOne(pending.first.name)
                              : AppLocalizations.of(context).driverRatePassengers(pending.length),
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Divider(height: 1, color: AppColors.border.withOpacity(.6)),

            // Footer: manage affordance (live hint when ongoing)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Icon(
                  requestCount > 0
                      ? Icons.notifications_active_outlined
                      : isOngoing
                          ? Icons.gps_fixed
                          : Icons.groups_outlined,
                  size: 14,
                  color: requestCount > 0
                      ? AppColors.warning
                      : isOngoing
                          ? AppColors.success
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    requestCount > 0
                        ? '$requestCount pending request${requestCount > 1 ? 's' : ''} — respond now'
                        : isOngoing
                            ? 'Trip in progress — live map & passengers'
                            : 'Requests, passengers & trip actions',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: requestCount > 0
                            ? AppColors.warning
                            : isOngoing
                                ? AppColors.success
                                : AppColors.textSecondary),
                  ),
                ),
                const Text('Manage',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCounts {
  final int requests;
  final int seatsBooked;
  const _TripCounts({required this.requests, required this.seatsBooked});
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(.8)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }
}