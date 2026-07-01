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
/// Shows only fields that actually exist on your backend's `TripOut`.
/// There's no driver card, vehicle make/model/plate, amenities list,
/// trip note, or duration anywhere in the real response — earlier
/// versions of this screen showed all of that as if it were real data.
/// What's genuinely here: route (city + specific pickup/drop-off
/// point), date/time, price, seats, and vehicle category.
class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trip details'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [ProfileIconButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
              : _buildContent(_trip!),
      bottomNavigationBar: _trip == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: PrimaryButton(
                  label: _trip!.seatsAvailable > 0 ? 'Book a Seat' : 'No seats left',
                  onPressed: _trip!.seatsAvailable > 0 ? () => _bookSeat(_trip!) : null,
                ),
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
          _buildRouteVisual(trip),
          const SizedBox(height: 18),
          Text(_dateLabel(trip.departureTime),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('${trip.originCity} → ${trip.destinationCity}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
          const SizedBox(height: 4),
          Text('${_priceLabel(trip.pricePerSeat)} per seat',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),
          _buildLocationRow(
            icon: Icons.fiber_manual_record,
            iconColor: AppColors.primary,
            city: trip.originCity,
            point: trip.originLocation,
          ),
          const SizedBox(height: 12),
          _buildLocationRow(
            icon: Icons.location_on,
            iconColor: AppColors.gold,
            city: trip.destinationCity,
            point: trip.destinationLocation,
          ),
          if (trip.vehicleCategory.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.directions_car_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                const Text('Vehicle category', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(trip.vehicleCategory,
                      style: const TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.event_seat_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text('${trip.seatsAvailable} seat${trip.seatsAvailable == 1 ? '' : 's'} available',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String city,
    required String point,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }

  Widget _buildRouteVisual(Trip trip) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _RoutePainter()),
          ),
          Positioned(
            top: 14,
            left: 16,
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, size: 10, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(trip.originCity, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
            ),
          ),
          Positioned(
            bottom: 14,
            right: 16,
            child: Row(
              children: [
                Text(trip.destinationCity, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(width: 6),
                const Icon(Icons.location_on, size: 14, color: AppColors.gold),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple dotted route line — a lightweight stand-in for a real map
/// embed. Swap for google_maps_flutter or mapbox_gl later if you want
/// an actual interactive map here; that needs platform API keys this
/// sandbox can't configure for you.
class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.55, size.height * 0.05,
        size.width * 0.88, size.height * 0.78,
      );

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
