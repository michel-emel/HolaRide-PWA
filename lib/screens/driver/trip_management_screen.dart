import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/trip.dart';
import '../../services/api_client.dart';
import '../../services/driver_service.dart';
import '../../theme/app_colors.dart';
import '../trip/chat_screen.dart';
import '../trip/live_tracking_screen.dart';
import '../trip/rate_trip_screen.dart';
import '../../widgets/profile_icon_button.dart';

/// Screen 21 — Incoming requests / trip management.
class TripManagementScreen extends StatefulWidget {
  final Trip trip;
  const TripManagementScreen({super.key, required this.trip});

  @override
  State<TripManagementScreen> createState() => _TripManagementScreenState();
}

class _TripManagementScreenState extends State<TripManagementScreen> {
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _error;
  final Set<String> _actingOn = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bookings = await DriverService.instance.tripBookings(widget.trip.id);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/trip_management_screen.dart: $e');
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load requests for this trip.";
        _loading = false;
      });
    }
  }

  List<Booking> get _requests =>
      _bookings.where((b) => b.status == BookingStatus.pendingDriverAcceptance).toList();
  List<Booking> get _confirmed =>
      _bookings.where((b) => b.status == BookingStatus.paid || b.status == BookingStatus.completed).toList();

  Future<void> _accept(Booking b) async {
    setState(() => _actingOn.add(b.id));
    try {
      await DriverService.instance.acceptBooking(b.id);
      await _load();
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/trip_management_screen.dart: $e');
      _showError('Could not accept this request.');
    } finally {
      if (mounted) setState(() => _actingOn.remove(b.id));
    }
  }

  Future<void> _reject(Booking b) async {
    setState(() => _actingOn.add(b.id));
    try {
      await DriverService.instance.rejectBooking(b.id);
      await _load();
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/trip_management_screen.dart: $e');
      _showError('Could not reject this request.');
    } finally {
      if (mounted) setState(() => _actingOn.remove(b.id));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmAndRun(
    String title,
    String message,
    Future<void> Function() action, {
    String? successMessage,
    bool popAfterSuccess = false,
    VoidCallback? onSuccess,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await action();
      if (!mounted) return;
      if (popAfterSuccess) {
        // Terminal action — completed or cancelled, nothing left to
        // manage here. Show clear confirmation, then either run the
        // given onSuccess (e.g. open the rating screen) or just
        // return to the trip list, where the trip is now correctly
        // sitting under "Past" instead of leaving the driver stuck
        // looking at a dead-end screen with no obvious next step.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage ?? 'Done.')),
        );
        if (onSuccess != null) {
          onSuccess();
        } else {
          Navigator.of(context).pop();
        }
      } else {
        await _load();
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/trip_management_screen.dart: $e');
      _showError('Something went wrong. Try again.');
    }
  }

  Future<void> _cancelTrip() => _confirmAndRun(
        'Cancel this trip?',
        'Every passenger who already paid will be notified and refunded per your cancellation policy.',
        () => DriverService.instance.cancelTrip(widget.trip.id),
        successMessage: 'Trip cancelled.',
        popAfterSuccess: true,
      );

  Future<void> _markCompleted() => _confirmAndRun(
        'Mark trip as completed?',
        'This closes the trip out once everyone has arrived.',
        () => DriverService.instance.markTripCompleted(widget.trip.id),
        successMessage: 'Trip marked as completed!',
        popAfterSuccess: true,
        onSuccess: () {
          final targets = _confirmed
              .where((b) => b.passengerId != null && b.passengerId!.isNotEmpty)
              .map((b) => RateTarget(id: b.passengerId!, name: b.passengerName ?? 'Passenger', role: 'passenger'))
              .toList();
          if (targets.isEmpty) {
            // No identifiable passengers to rate (shouldn't normally
            // happen for a trip with confirmed bookings, but fall back
            // to a plain pop rather than showing an empty rating screen).
            Navigator.of(context).pop();
            return;
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => RateTripScreen(tripId: widget.trip.id, targets: targets)),
          );
        },
      );

  Future<void> _pickNoShow() async {
    if (_confirmed.isEmpty) {
      _showError('No confirmed passengers on this trip yet.');
      return;
    }
    final chosen = await showModalBottomSheet<Booking>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Who didn\'t show up?', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ..._confirmed.map(
              (b) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(b.passengerName ?? 'Passenger'),
                subtitle: Text('${b.seats} seat${b.seats > 1 ? 's' : ''}'),
                onTap: () => Navigator.of(context).pop(b),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await _confirmAndRun(
      'Mark ${chosen.passengerName ?? 'this passenger'} as no-show?',
      'This affects their record and may apply a fee per your policy.',
      () => DriverService.instance.markNoShow(chosen.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${trip.originCity} → ${trip.destinationCity}', style: const TextStyle(fontSize: 16)),
              Text(
                '${trip.originLocation.isNotEmpty ? '${trip.originLocation} → ' : ''}'
                '${trip.destinationLocation.isNotEmpty ? '${trip.destinationLocation} · ' : ''}'
                '${trip.departureTime.day}/${trip.departureTime.month} · '
                '${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              tooltip: 'Live tracking',
              icon: const Icon(Icons.my_location),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LiveTrackingScreen(trip: trip)),
              ),
            ),
            const ProfileIconButton(),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Requests (${_requests.length})'),
              Tab(text: 'Bookings (${_confirmed.length})'),
              const Tab(text: 'Trip actions'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
                : TabBarView(
                    children: [_buildRequests(), _buildConfirmed(), _buildActions()],
                  ),
      ),
    );
  }

  Widget _buildRequests() {
    if (_requests.isEmpty) {
      return const Center(child: Text('No new requests.', style: TextStyle(color: AppColors.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final b = _requests[i];
          final busy = _actingOn.contains(b.id);
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceMuted,
                  child: Text(
                    (b.passengerName?.isNotEmpty ?? false) ? b.passengerName![0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.passengerName ?? 'Passenger',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${b.seats} seat${b.seats > 1 ? 's' : ''}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      if ((b.passengerRatingCount) > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: AppColors.gold),
                              const SizedBox(width: 3),
                              Text(
                                '${b.passengerRatingAverage?.toStringAsFixed(1)} (${b.passengerRatingCount})',
                                style: const TextStyle(
                                    fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _accept(b),
                        icon: const Icon(Icons.check_circle, color: AppColors.success),
                        tooltip: 'Accept',
                      ),
                      IconButton(
                        onPressed: () => _reject(b),
                        icon: const Icon(Icons.cancel, color: AppColors.danger),
                        tooltip: 'Reject',
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmed() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _confirmed.length + (_confirmed.isEmpty ? 2 : 1),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i == 0) {
            return InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LiveTrackingScreen(trip: widget.trip)),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.my_location, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Share My Location', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }
          if (_confirmed.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: Text('No confirmed passengers yet.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            );
          }
          final b = _confirmed[i - 1];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceMuted,
                  child: Text(
                    (b.passengerName?.isNotEmpty ?? false) ? b.passengerName![0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.passengerName ?? 'Passenger',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${b.seats} seat${b.seats > 1 ? 's' : ''}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      if ((b.passengerRatingCount) > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: AppColors.gold),
                              const SizedBox(width: 3),
                              Text(
                                '${b.passengerRatingAverage?.toStringAsFixed(1)} (${b.passengerRatingCount})',
                                style: const TextStyle(
                                    fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(b.status.label,
                      style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(tripId: widget.trip.id),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime t) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${t.day} ${months[t.month - 1]} ${t.year}';
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

  Widget _buildActions() {
    final trip = widget.trip;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Repeats the full trip detail right here, not just in the
          // AppBar — these are destructive, trip-specific actions
          // (Cancel Trip especially), so there should be zero doubt
          // about which trip they're about to act on.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
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
                const Text('Acting on this trip', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('${trip.originCity} → ${trip.destinationCity}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                if (trip.originLocation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.fiber_manual_record, size: 9, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(trip.originLocation,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                if (trip.destinationLocation.isNotEmpty) ...[
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
                const SizedBox(height: 8),
                Text('${_dateLabel(trip.departureTime)} · ${_timeLabel(trip.departureTime)}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('${trip.seatsAvailable} seats available · ${_money(trip.pricePerSeat)} per seat',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _markCompleted,
            icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
            label: const Text('Mark Completed'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.success),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickNoShow,
            icon: const Icon(Icons.person_off_outlined, color: AppColors.warning),
            label: const Text('Mark No-show'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cancelTrip,
            icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
            label: const Text('Cancel Trip'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          ),
        ],
      ),
    );
  }
}