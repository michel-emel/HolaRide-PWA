import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/trip.dart';
import '../../services/api_client.dart';
import '../../services/driver_service.dart';
import '../../theme/app_colors.dart';
import '../trip/chat_screen.dart';
import '../trip/live_trip_screen.dart';
import '../trip/rate_trip_screen.dart';
import '../../widgets/profile_icon_button.dart';
import '../../widgets/status_badge.dart';

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

  // Whether the trip is currently 'ongoing' (location sharing active).
  bool _tripStarted = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _tripStarted = widget.trip.status == 'ongoing';
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

  // ── Start trip (published → ongoing, enables location sharing) ──
  Future<void> _startTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Start this trip?'),
        content: const Text(
          'The trip will be marked as ongoing. Your paid passengers will be '
          'able to follow your live position until you mark it completed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not yet', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Start Trip',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _starting = true);
    try {
      await DriverService.instance.startTrip(widget.trip.id);
      if (!mounted) return;
      setState(() => _tripStarted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip started — passengers can now follow you.')),
      );
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/trip_management_screen.dart: $e');
      _showError('Could not start the trip. Try again.');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
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

  // ── Helpers ─────────────────────────────────────────────────────

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

  /// "Just now", "12m ago", "3h ago", or the date for older requests.
  String _agoLabel(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _dateLabel(t);
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(tripId: widget.trip.id)),
    );
  }

  void _viewPassengerProfile(Booking b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
            child: Center(
              child: Text(
                (b.passengerName?.isNotEmpty ?? false) ? b.passengerName![0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(b.passengerName ?? 'Passenger',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 6),
          if ((b.passengerRatingCount) > 0)
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, size: 18, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(
                '${b.passengerRatingAverage?.toStringAsFixed(1)} · ${b.passengerRatingCount} review${b.passengerRatingCount > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ])
          else
            const Text('New passenger — no reviews yet',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.infoBg.withOpacity(.7), borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _ProfileStat(label: 'Seats requested', value: '${b.seats}'),
              Container(width: 1, height: 30, color: AppColors.border),
              _ProfileStat(label: 'Requested', value: _agoLabel(b.createdAt)),
            ]),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity, height: 48,
            child: OutlinedButton.icon(
              onPressed: () { Navigator.of(context).pop(); _openChat(); },
              icon: const Icon(Icons.chat_bubble_outline, size: 17),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          titleSpacing: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${trip.originCity} → ${trip.destinationCity}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Text(
                [
                  if (trip.originLocation.isNotEmpty) trip.originLocation,
                  if (trip.destinationLocation.isNotEmpty) trip.destinationLocation,
                  '${trip.departureTime.day} ${_dateLabel(trip.departureTime).split(' ')[1]}',
                  _timeLabel(trip.departureTime),
                ].join(' · '),
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: const [ProfileIconButton(), SizedBox(width: 8)],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.group_outlined, size: 16),
                const SizedBox(width: 6),
                Text('Requests (${_requests.length})'),
              ])),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.event_available_outlined, size: 16),
                const SizedBox(width: 6),
                Text('Bookings (${_confirmed.length})'),
              ])),
              const Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bolt_outlined, size: 16),
                SizedBox(width: 6),
                Text('Trip actions'),
              ])),
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

  // ── Requests tab (redesigned per mockup) ────────────────────────

  Widget _buildRequests() {
    final requests = _requests;
    return RefreshIndicator(
      onRefresh: _load,
      // LayoutBuilder + ConstrainedBox + Spacer: the tips card and the
      // support link stick to the BOTTOM of the screen when the request
      // list is short, and flow naturally after the list when it's long.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
          if (requests.isEmpty) ...[
            const SizedBox(height: 40),
            const Center(
              child: Column(children: [
                Icon(Icons.inbox_outlined, size: 48, color: AppColors.border),
                SizedBox(height: 12),
                Text('No new requests.', style: TextStyle(color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(height: 40),
          ] else ...[
            // Green summary banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBg.withOpacity(.7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_user, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'You have ${requests.length} pending request${requests.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Review and respond to your passenger request${requests.length > 1 ? 's' : ''}.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Section header
            Row(children: [
              const Text('Pending Requests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(8)),
                child: Text('${requests.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
            ]),
            const SizedBox(height: 12),

            // Request cards
            ...requests.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRequestCard(b),
                )),
          ],

          // Everything below is pushed to the bottom of the screen.
          const Spacer(),
          const SizedBox(height: 20),

          // Tips card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold.withOpacity(.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tips for a great trip',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Expanded(child: _TipItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Communicate',
                  subtitle: 'Chat with your passenger before the trip.',
                )),
                SizedBox(width: 10),
                Expanded(child: _TipItem(
                  icon: Icons.schedule,
                  title: 'Be on time',
                  subtitle: 'Arrive a few minutes early.',
                )),
                SizedBox(width: 10),
                Expanded(child: _TipItem(
                  icon: Icons.verified_user_outlined,
                  title: 'Drive safe',
                  subtitle: 'Your safety and theirs comes first.',
                )),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // Support footer
          Center(
            child: InkWell(
              onTap: () {
                // TODO: brancher sur WhatsApp / mail support quand décidé
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support: coming soon')),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.question_mark, size: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  const Text('Need help? ',
                      style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                  const Text('Contact support',
                      style: TextStyle(fontSize: 13.5, color: AppColors.primary, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                ]),
              ),
            ),
          ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Booking b) {
    final trip = widget.trip;
    final busy = _actingOn.contains(b.id);
    final originLabel = trip.originLocation.isNotEmpty
        ? '${trip.originLocation}, ${trip.originCity}'
        : trip.originCity;
    final destLabel = trip.destinationLocation.isNotEmpty
        ? '${trip.destinationLocation}, ${trip.destinationCity}'
        : trip.destinationCity;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar with presence dot
          Stack(children: [
            Container(
              width: 56, height: 56,
              decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  (b.passengerName?.isNotEmpty ?? false) ? b.passengerName![0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 22),
                ),
              ),
            ),
            Positioned(
              right: 2, bottom: 2,
              child: Container(
                width: 13, height: 13,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 12),

          // Name + seat pill + points
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(b.passengerName ?? 'Passenger',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                  child: Text('${b.seats} seat${b.seats > 1 ? 's' : ''} requested',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
              ]),
              if ((b.passengerRatingCount) > 0) ...[
                const SizedBox(height: 3),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text('${b.passengerRatingAverage?.toStringAsFixed(1)} (${b.passengerRatingCount})',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ]),
              ],
              const SizedBox(height: 10),
              _PointRow(icon: Icons.location_on, color: AppColors.primary, label: originLabel),
              Padding(
                padding: const EdgeInsets.only(left: 7),
                child: SizedBox(
                  height: 12,
                  child: Column(
                    children: List.generate(3, (_) => Expanded(
                      child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 1),
                          color: AppColors.border),
                    )),
                  ),
                ),
              ),
              _PointRow(icon: Icons.location_on, color: AppColors.danger, label: destLabel),
            ]),
          ),
          const SizedBox(width: 8),

          // Right column: timestamp + Accept / Decline
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_agoLabel(b.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              Row(mainAxisSize: MainAxisSize.min, children: [
                _SquareAction(
                  icon: Icons.check_rounded,
                  color: AppColors.success,
                  label: 'Accept',
                  onTap: () => _accept(b),
                ),
                const SizedBox(width: 8),
                _SquareAction(
                  icon: Icons.close_rounded,
                  color: AppColors.danger,
                  label: 'Decline',
                  onTap: () => _reject(b),
                ),
              ]),
          ]),
        ]),

        const SizedBox(height: 12),
        Divider(height: 1, color: AppColors.border.withOpacity(.6)),
        const SizedBox(height: 10),

        // Meta row: date · time · seats
        Row(children: [
          const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(_dateLabel(widget.trip.departureTime),
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          _metaSep(),
          const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(_timeLabel(widget.trip.departureTime),
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          _metaSep(),
          const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text('${b.seats} seat${b.seats > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ]),

        const SizedBox(height: 10),
        Divider(height: 1, color: AppColors.border.withOpacity(.6)),

        // Footer: Message | View profile
        Row(children: [
          Expanded(
            child: InkWell(
              onTap: _openChat,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text('Message',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ]),
              ),
            ),
          ),
          InkWell(
            onTap: () => _viewPassengerProfile(b),
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('View profile',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 17, color: AppColors.textSecondary),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _metaSep() => Container(
        width: 1, height: 14,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: AppColors.border,
      );

  // ── Bookings tab (redesigned) ───────────────────────────────────

  Widget _buildConfirmed() {
    final confirmed = _confirmed;
    final bookedSeats = confirmed.fold<int>(0, (s, b) => s + b.seats);
    final totalSeats = bookedSeats + widget.trip.seatsAvailable;
    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (confirmed.isEmpty) ...[
                    const SizedBox(height: 40),
                    const Center(
                      child: Column(children: [
                        Icon(Icons.event_seat_outlined, size: 48, color: AppColors.border),
                        SizedBox(height: 12),
                        Text('No confirmed passengers yet.',
                            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('Accepted requests appear here once paid.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ]),
                    ),
                  ] else ...[
                    // Occupancy banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg.withOpacity(.7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.event_seat, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              '$bookedSeats of $totalSeats seat${totalSeats > 1 ? 's' : ''} booked',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: totalSeats == 0 ? 0 : bookedSeats / totalSeats,
                                minHeight: 6,
                                backgroundColor: AppColors.border.withOpacity(.5),
                                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    Row(children: [
                      const Text('Confirmed Passengers',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(8)),
                        child: Text('${confirmed.length}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    ...confirmed.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPassengerCard(b),
                        )),
                  ],

                  // Earnings summary pinned at the bottom.
                  const Spacer(),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.gold.withOpacity(.2)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Icon(Icons.payments_outlined, size: 19, color: AppColors.gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Expected earnings',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(_money(bookedSeats * widget.trip.pricePerSeat),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
                        ]),
                      ),
                      Text(
                        '$bookedSeats seat${bookedSeats > 1 ? 's' : ''} × ${_money(widget.trip.pricePerSeat)}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerCard(Booking b) {
    final isPaid = b.status == BookingStatus.paid;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Avatar with presence dot
          Stack(children: [
            Container(
              width: 52, height: 52,
              decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  (b.passengerName?.isNotEmpty ?? false) ? b.passengerName![0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ),
            ),
            Positioned(
              right: 1, bottom: 1,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(b.passengerName ?? 'Passenger',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPaid ? AppColors.successBg : AppColors.infoBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(bookingStatusLabel(context, b.status),
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isPaid ? AppColors.success : AppColors.primary)),
                ),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                if ((b.passengerRatingCount) > 0) ...[
                  const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text('${b.passengerRatingAverage?.toStringAsFixed(1)} (${b.passengerRatingCount})',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                ],
                const Icon(Icons.event_seat_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text('${b.seats} seat${b.seats > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Divider(height: 1, color: AppColors.border.withOpacity(.6)),
        Row(children: [
          Expanded(
            child: InkWell(
              onTap: _openChat,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text('Message',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ]),
              ),
            ),
          ),
          InkWell(
            onTap: () => _viewPassengerProfile(b),
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('View profile',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 17, color: AppColors.textSecondary),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Trip actions tab (redesigned) ───────────────────────────────

  Widget _buildActions() {
    final trip = widget.trip;
    final isOngoing = _tripStarted;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
          // Trip summary — repeats the full trip detail right here, not
          // just in the AppBar: these are destructive, trip-specific
          // actions (Cancel Trip especially), so there should be zero
          // doubt about which trip they're about to act on.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 14, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.route, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Acting on this trip',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text('${trip.originCity} → ${trip.destinationCity}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isOngoing ? AppColors.successBg : AppColors.infoBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(isOngoing ? 'Ongoing' : 'Published',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800,
                            color: isOngoing ? AppColors.success : AppColors.primary)),
                  ),
                ]),
                const SizedBox(height: 14),
                _PointRow(
                  icon: Icons.location_on,
                  color: AppColors.primary,
                  label: trip.originLocation.isNotEmpty
                      ? '${trip.originLocation}, ${trip.originCity}'
                      : trip.originCity,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: SizedBox(
                    height: 12,
                    child: Column(
                      children: List.generate(3, (_) => Expanded(
                        child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 1),
                            color: AppColors.border),
                      )),
                    ),
                  ),
                ),
                _PointRow(
                  icon: Icons.location_on,
                  color: AppColors.danger,
                  label: trip.destinationLocation.isNotEmpty
                      ? '${trip.destinationLocation}, ${trip.destinationCity}'
                      : trip.destinationCity,
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppColors.border.withOpacity(.6)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _MetaChip(icon: Icons.calendar_month_outlined, label: _dateLabel(trip.departureTime)),
                  _MetaChip(icon: Icons.schedule, label: _timeLabel(trip.departureTime)),
                  _MetaChip(icon: Icons.event_seat_outlined, label: '${trip.seatsAvailable} seats left'),
                  _MetaChip(icon: Icons.payments_outlined, label: '${_money(trip.pricePerSeat)} / seat'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Start Trip / Trip in progress ─────────────────────
          if (!_tripStarted)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _starting ? null : _startTrip,
                icon: _starting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow_rounded, size: 22),
                label: Text(_starting ? 'Starting...' : 'Start Trip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            )
          else
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LiveTripScreen(trip: widget.trip)),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.success.withOpacity(.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.gps_fixed, size: 18, color: AppColors.success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Trip in progress — tap to open the live map.',
                        style: TextStyle(
                            color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13.5)),
                  ),
                  Icon(Icons.map_outlined, size: 18, color: AppColors.success),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: AppColors.success),
                ]),
              ),
            ),

          const SizedBox(height: 20),

          // Manage — grouped action tiles with explanations
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Manage this trip',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              _ActionTile(
                icon: Icons.check_circle_outline,
                color: AppColors.success,
                title: 'Mark Completed',
                subtitle: 'Close the trip once everyone has arrived.',
                onTap: _markCompleted,
              ),
              Divider(height: 1, indent: 64, color: AppColors.border.withOpacity(.6)),
              _ActionTile(
                icon: Icons.person_off_outlined,
                color: AppColors.warning,
                title: 'Mark No-show',
                subtitle: "Report a passenger who didn't show up.",
                onTap: _pickNoShow,
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // Danger zone
          Container(
            decoration: BoxDecoration(
              color: AppColors.dangerBg.withOpacity(.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.danger.withOpacity(.2)),
            ),
            child: _ActionTile(
              icon: Icons.cancel_outlined,
              color: AppColors.danger,
              title: 'Cancel Trip',
              subtitle: 'Notifies and refunds your paid passengers.',
              onTap: _cancelTrip,
            ),
          ),
        ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: color.withOpacity(.12), shape: BoxShape.circle),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────

class _PointRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _PointRow({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
    ]);
  }
}

class _SquareAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _SquareAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TipItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ),
      ]),
      const SizedBox(height: 4),
      Text(subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.35)),
    ]);
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}