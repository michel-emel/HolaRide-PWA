import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/trip.dart';
import '../../theme/app_colors.dart';
import '../../services/booking_service.dart';
import '../bookings/cancel_withdraw_screen.dart';
import '../main_tab_screen.dart';
import '../payment/payment_screen.dart';

/// Screen 11 — Waiting for driver.
///
/// Polls the booking every few seconds so the passenger finds out the
/// moment the driver accepts or declines, without needing to manually
/// refresh. A push-notification-driven version can replace this polling
/// later without changing anything else on this screen.
class WaitingForDriverScreen extends StatefulWidget {
  final Trip trip;
  final Booking booking;
  const WaitingForDriverScreen({super.key, required this.trip, required this.booking});

  @override
  State<WaitingForDriverScreen> createState() => _WaitingForDriverScreenState();
}

class _WaitingForDriverScreenState extends State<WaitingForDriverScreen> {
  Timer? _poller;
  Booking? _booking;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _poller = Timer.periodic(const Duration(seconds: 6), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    if (_navigating) return;
    try {
      final updated = await BookingService.instance.getById(widget.booking.id);
      if (!mounted || updated == null) return;
      setState(() => _booking = updated);

      if (updated.status == BookingStatus.pendingPayment) {
        _navigating = true;
        _poller?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentScreen(trip: widget.trip, booking: updated),
          ),
        );
      } else if (updated.status == BookingStatus.rejected) {
        _navigating = true;
        _poller?.cancel();
        _showDeclined();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/trip/waiting_for_driver_screen.dart: $e');
      // Transient network hiccup — just try again on the next tick.
    }
  }

  void _showDeclined() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Request declined'),
        content: const Text(
          'The driver wasn\'t able to accept your request this time. You can search for another trip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainTabScreen()),
              (route) => false,
            ),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Future<void> _withdraw() async {
    final confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CancelWithdrawScreen(trip: widget.trip, booking: widget.booking),
      ),
    );
    if (confirmed == true && mounted) {
      _poller?.cancel();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainTabScreen()),
        (route) => false,
      );
    }
  }

  void _openProfile() {
    _poller?.cancel();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainTabScreen(initialIndex: 3)),
      (route) => false,
    );
  }

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime t) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${t.day} ${months[t.month - 1]} ${t.year}';
  }

  String _priceLabel(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf XAF';
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final seats = _booking?.seats ?? widget.booking.seats;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: _openProfile,
            icon: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, size: 19, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
              child: const Icon(Icons.hourglass_top, size: 52, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Waiting for the driver',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'We\'ve sent your request to the driver.\nYou\'ll be notified here as soon as they respond.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${trip.originCity} → ${trip.destinationCity}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    if (trip.vehicleCategory.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                        child: Text(trip.vehicleCategory,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${_dateLabel(trip.departureTime)} · ${_timeLabel(trip.departureTime)}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),
                if (trip.originLocation.isNotEmpty)
                  _pointRow(Icons.fiber_manual_record, AppColors.primary, 'Departure point', trip.originLocation),
                if (trip.originLocation.isNotEmpty && trip.destinationLocation.isNotEmpty)
                  const SizedBox(height: 10),
                if (trip.destinationLocation.isNotEmpty)
                  _pointRow(Icons.location_on, AppColors.gold, 'Drop-off point', trip.destinationLocation),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _statBlock('Seats requested', '$seats'),
                    ),
                    Expanded(
                      child: _statBlock('Price per seat', _priceLabel(trip.pricePerSeat)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: const [
              Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'This request can take time. We\'ll notify you immediately.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _withdraw,
              child: const Text('Withdraw request', style: TextStyle(color: AppColors.danger)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _pointRow(IconData icon, Color color, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
      ],
    );
  }
}