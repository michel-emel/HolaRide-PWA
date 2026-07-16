import 'package:flutter/material.dart';
import '../../models/trip.dart';
import '../../services/auth_gate.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/profile_icon_button.dart';
import 'booking_request_screen.dart';

/// Screen 9 — Trip detail.
///
/// Real fields (come straight from `TripOut`): trip id, route (city +
/// specific pickup/drop-off point), date/time, price, seats, vehicle
/// category, driver rating average/count.
///
/// ⚠️ MOCK / TODO fields (NOT on the backend yet — hardcoded below so
/// the UI matches the design mockup). Wire these up to real backend
/// fields once they exist, then delete the `_Mock` block entirely:
///   - "Verified Trip" trust badge
///   - driver name, photo, "verified driver" status
///   - ID / phone / background-check verification badges
///   - trips completed count + "know more about the driver" action
///   - estimated duration + distance (used to compute "arrival est.")
///   - luggage allowance
///   - "No hidden fees" / "Secure booking" footer copy
class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

/// TODO(backend): replace this whole block once TripOut exposes real
/// driver/vehicle/duration/trust data. Nothing in here is real user data.
class _Mock {
  static const verifiedTrip = true;
  static const driverName = 'Jean M.';
  static const driverPhotoUrl = ''; // TODO: real avatar URL from backend
  static const driverVerified = true;
  static const idVerified = true;
  static const phoneVerified = true;
  static const backgroundChecked = true;
  static const tripsCompleted = 25;
  static const estDurationMinutes = 210; // ~3h30
  static const estDistanceKm = 240;
  static const luggagePerPassenger = '1 bag per passenger';
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Trip? _trip;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final trip = await TripService.instance.getById(widget.tripId);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _loading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/trip/trip_detail_screen.dart: $e');
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load this trip.";
        _loading = false;
      });
    }
  }

  Future<void> _bookSeat(Trip trip) async {
    final loggedIn = await requireLogin(context, reason: 'Log in to book a seat on this trip.');
    if (!loggedIn || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookingRequestScreen(trip: trip)),
    );
  }

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime t) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_weekday(t.weekday)}, ${t.day} ${months[t.month - 1]} ${t.year}';
  }

  String _weekday(int w) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];

  String _priceLabel(num price) {
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf XAF';
  }

  // TODO(backend): once real duration exists, drop this and use it directly.
  String _durationLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  // TODO(backend): estimated arrival — swap for a real arrival field
  // once the backend returns one instead of derived-from-mock-duration.
  DateTime _estArrival(DateTime departure) =>
      departure.add(const Duration(minutes: _Mock.estDurationMinutes));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Trip Details'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [
          SizedBox(width: 8),
          ProfileIconButton(),
          SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
              : _buildContent(_trip!),
      bottomNavigationBar: _trip == null ? null : _buildBottomBar(_trip!),
    );
  }

  Widget _buildBottomBar(Trip trip) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total price (1 seat)',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      Text(_priceLabel(trip.pricePerSeat),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      // TODO(backend): "no hidden fees" is static copy, not a fee breakdown.
                      const Text('No hidden fees', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 50,
                  width: 170,
                  child: ElevatedButton(
                    onPressed: trip.seatsAvailable > 0 ? () => _bookSeat(trip) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(trip.seatsAvailable > 0 ? 'Book a Seat' : 'No seats left',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        if (trip.seatsAvailable > 0) ...[
                          const SizedBox(width: 8),
                          const CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.arrow_forward, size: 13, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                // TODO(backend): "secure booking" is static reassurance copy.
                const Text('Secure booking', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Trip trip) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(_dateLabel(trip.departureTime),
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${trip.originCity} → ${trip.destinationCity}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.gold, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                trip.driverRatingCount > 0
                                    ? '${trip.driverRatingAverage?.toStringAsFixed(1)} · ${trip.driverRatingCount} '
                                        '${trip.driverRatingCount == 1 ? "review" : "reviews"} for this driver'
                                    : 'No driver reviews yet',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // TODO(backend): "Verified Trip" trust badge is static —
                    // there is no trip-level trust/verification flag yet.
                    // Background intentionally unchanged (still green-tinted).
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primary,
                            child: const Icon(Icons.gpp_good, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Verified Trip', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Colors.black)),
                              Text('Safe • Reliable • Trusted',
                                  style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Price per seat', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(_priceLabel(trip.pricePerSeat),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildPromoBanner(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildLocationRow(
                        icon: Icons.fiber_manual_record,
                        iconColor: AppColors.primary,
                        city: trip.originCity,
                        point: trip.originLocation,
                        tag: 'Departure',
                        time: _timeLabel(trip.departureTime),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 6, top: 4, bottom: 4),
                        child: SizedBox(
                          height: 18,
                          child: VerticalDivider(width: 1, thickness: 1),
                        ),
                      ),
                      _buildLocationRow(
                        icon: Icons.location_on,
                        iconColor: AppColors.gold,
                        city: trip.destinationCity,
                        point: trip.destinationLocation,
                        tag: 'Arrival',
                        // TODO(backend): drop "(est.)" once a real arrival time exists.
                        time: '${_timeLabel(_estArrival(trip.departureTime))} (est.)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // TODO(backend): duration + distance are mocked — there is
                // no ETA/distance field on TripOut yet.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.schedule, size: 18, color: AppColors.primary),
                      const SizedBox(height: 4),
                      Text('~${_durationLabel(_Mock.estDurationMinutes)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      const Icon(Icons.route_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(height: 4),
                      Text('~${_Mock.estDistanceKm} km',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildTripFactsRow(trip),
          const SizedBox(height: 18),
          _buildDriverCard(trip),
          const SizedBox(height: 16),
          _buildSafetyBanner(),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.shield_outlined, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Affordable, safe and reliable travel',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text('Book with confidence and enjoy your journey.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String city,
    required String point,
    required String tag,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(city, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              if (point.isNotEmpty)
                Text(point, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ],
          ),
        ),
        // Fixed width so "Departure"/"Arrival" pills line up between rows
        // regardless of label length.
        SizedBox(
          width: 78,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(tag,
                style: const TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 8),
        // Fixed width + right-aligned so the two times line up in a column.
        SizedBox(
          width: 64,
          child: Text(time,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildTripFactsRow(Trip trip) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trip.vehicleCategory.isNotEmpty) ...[
            // TODO(backend): swap the generic car icon for a real vehicle
            // photo once TripOut exposes one.
            Container(
              width: 48,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car, color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: _factItem(
                label: 'Vehicle category',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(trip.vehicleCategory,
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 3,
            child: _factItem(
              icon: Icons.event_seat_outlined,
              label: 'Seats available',
              value: '${trip.seatsAvailable} seat${trip.seatsAvailable == 1 ? '' : 's'} left',
            ),
          ),
          const SizedBox(width: 8),
          // TODO(backend): luggage allowance isn't on TripOut yet.
          Expanded(
            flex: 3,
            child: _factItem(
              icon: Icons.luggage_outlined,
              label: 'Luggage',
              value: _Mock.luggagePerPassenger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _factItem({IconData? icon, required String label, String? value, Widget? child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        if (child != null)
          child
        else
          Text(value ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // TODO(backend): everything in this card except the star rating is
  // mock data (_Mock) — there is no driver name/photo/verification/
  // trip-count field on TripOut. Replace once the backend adds one.
  Widget _buildDriverCard(Trip trip) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.surfaceMuted,
                    backgroundImage: _Mock.driverPhotoUrl.isNotEmpty
                        ? NetworkImage(_Mock.driverPhotoUrl)
                        : null,
                    child: _Mock.driverPhotoUrl.isEmpty
                        ? const Icon(Icons.person, color: AppColors.textSecondary)
                        : null,
                  ),
                  if (_Mock.driverVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 11, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Driver', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    const Text(_Mock.driverName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    if (_Mock.driverVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Verified driver',
                            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
              if (trip.driverRatingCount > 0)
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.gold, size: 16),
                            const SizedBox(width: 4),
                            Text('${trip.driverRatingAverage?.toStringAsFixed(1)}',
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        ),
                        Text('${trip.driverRatingCount} '
                                '${trip.driverRatingCount == 1 ? "review" : "reviews"}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_Mock.idVerified) _verifiedChip(Icons.shield_outlined, 'ID Verified'),
              if (_Mock.phoneVerified) _verifiedChip(Icons.smartphone_outlined, 'Phone Verified'),
              if (_Mock.backgroundChecked) _verifiedChip(Icons.check_circle_outline, 'Background Checked'),
              _verifiedChip(Icons.route_outlined, '${_Mock.tripsCompleted} Trips completed', trailingChevron: true),
            ],
          ),
          const SizedBox(height: 12),
          // TODO(backend): no driver-profile endpoint exists yet — this
          // button currently has nowhere real to navigate to.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Driver profile coming soon')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Know more about the driver',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifiedChip(IconData icon, String label, {bool trailingChevron = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            if (trailingChevron) ...[
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondary),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.gold,
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your safety is our priority', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text('SOS, live location sharing and in-app chat available.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Row(
            children: const [
              Text('Learn more', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12.5)),
              Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}