import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  String _dateTimeLabel(DateTime t) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${t.day} ${months[t.month - 1]} ${t.year} · $time';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'scheduled':
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: buildAppHeader(
          'My Trips',
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: 'Upcoming'), Tab(text: 'Past')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(_trips.where((t) => !_isPast(t)).toList()),
            _buildList(_trips.where(_isPast).toList()),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateTripScreen()),
              ).then((_) => _load()),
              icon: const Icon(Icons.add),
              label: const Text('Create New Trip'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Trip> trips) {
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
    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            Center(child: Text('No trips here yet.', style: TextStyle(color: AppColors.textSecondary))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final t = trips[i];
          final pending = _pendingByTrip[t.id] ?? const [];
          return InkWell(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => TripManagementScreen(trip: t)))
                .then((_) => _load()),
            borderRadius: BorderRadius.circular(16),
            child: Container(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.originCity} → ${t.destinationCity}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            if (t.originLocation.isNotEmpty || t.destinationLocation.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  if (t.originLocation.isNotEmpty) ...[
                                    const Icon(Icons.fiber_manual_record, size: 9, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(t.originLocation,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                  if (t.originLocation.isNotEmpty && t.destinationLocation.isNotEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.arrow_forward, size: 9, color: AppColors.textSecondary),
                                    ),
                                  if (t.destinationLocation.isNotEmpty) ...[
                                    const Icon(Icons.location_on, size: 10, color: AppColors.gold),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(t.destinationLocation,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(_dateTimeLabel(t.departureTime),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                            const SizedBox(height: 2),
                            Text('${t.seatsAvailable} seats · ${_money(t.pricePerSeat)}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(t.displayStatus).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.displayStatus,
                          style: TextStyle(
                              color: _statusColor(t.displayStatus), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _openRating(t),
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
                                pending.length == 1
                                    ? 'Rate ${pending.first.name}'
                                    : 'Rate ${pending.length} passengers',
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
}
