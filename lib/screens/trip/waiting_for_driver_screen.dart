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

class _WaitingForDriverScreenState extends State<WaitingForDriverScreen>
    with SingleTickerProviderStateMixin {
  Timer? _poller;
  Booking? _booking;
  bool _navigating = false;

  // Hourglass flip animation: flip 180°, rest, flip again, rest — loops
  // seamlessly (ends at a full turn, visually identical to the start).
  late final AnimationController _flipCtrl;
  late final Animation<double> _flip;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _poller = Timer.periodic(const Duration(seconds: 6), (_) => _checkStatus());

    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat();
    _flip = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5).chain(CurveTween(curve: Curves.easeInOut)), weight: 22),
      TweenSequenceItem(tween: ConstantTween(0.5), weight: 28),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 22),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 28),
    ]).animate(_flipCtrl);
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

  void _goHome() {
    _poller?.cancel();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainTabScreen()),
      (route) => false,
    );
  }

  void _openProfile() {
    _poller?.cancel();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainTabScreen(initialIndex: 3)),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('Waiting for the driver',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
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
          const SizedBox(height: 12),

          // ── Animated hourglass ──────────────────────────────
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(.08), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: RotationTransition(
                turns: _flip,
                child: const Icon(Icons.hourglass_top, size: 62, color: AppColors.primary),
              ),
            ),
          ),

          const SizedBox(height: 26),
          const Text("We've sent your request to the driver.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text("You'll be notified here as soon as they respond.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary, height: 1.4)),

          const SizedBox(height: 20),

          // ── Response-time banner ────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Icon(Icons.schedule, size: 20, color: AppColors.gold),
              const SizedBox(width: 12),
              const Expanded(
                child: Text.rich(TextSpan(
                  text: 'Most drivers respond within ',
                  style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                  children: [
                    TextSpan(text: '5–10 minutes.',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                )),
              ),
            ]),
          ),

          const SizedBox(height: 22),
          Divider(color: AppColors.border.withOpacity(.7)),
          const SizedBox(height: 18),

          // ── What happens next? ──────────────────────────────
          const Text('What happens next?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepItem(icon: Icons.send_outlined, label: 'Request sent', rotateIcon: true),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(double.infinity, 2),
                      painter: _HDashPainter(color: AppColors.primary.withOpacity(.3)),
                    ),
                  ),
                ),
              ),
              const _StepItem(icon: Icons.notifications_none, label: 'Driver notified'),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: CustomPaint(
                      size: const Size(double.infinity, 2),
                      painter: _HDashPainter(color: AppColors.primary.withOpacity(.3)),
                    ),
                  ),
                ),
              ),
              const _StepItem(icon: Icons.person_outline, label: 'Driver responds'),
            ],
          ),

          const SizedBox(height: 22),

          // ── Notify card ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.infoBg.withOpacity(.7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.notifications_active_outlined, size: 22, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("We'll notify you immediately",
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text("You can continue using the app.\nWe'll let you know as soon as the driver accepts.",
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── Go Home button ──────────────────────────────────
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _goHome,
                borderRadius: BorderRadius.circular(16),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_outlined, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text('Go Home',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── "or" divider ────────────────────────────────────
          Row(children: [
            Expanded(child: Divider(color: AppColors.border.withOpacity(.8))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('or', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            Expanded(child: Divider(color: AppColors.border.withOpacity(.8))),
          ]),

          const SizedBox(height: 14),

          // ── Withdraw request ────────────────────────────────
          SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: _withdraw,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.danger.withOpacity(.5), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel_outlined, size: 20, color: AppColors.danger),
                  SizedBox(width: 10),
                  Text('Withdraw request',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 15.5)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Center(
            child: Text('You can cancel for free up to 2 hours before departure.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Step item (circle icon + label) ─────────────────────────────────────
class _StepItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool rotateIcon;
  const _StepItem({required this.icon, required this.label, this.rotateIcon = false});

  @override
  Widget build(BuildContext context) {
    Widget child = Icon(icon, size: 22, color: AppColors.primary);
    if (rotateIcon) child = Transform.rotate(angle: -0.6, child: child);
    return Column(children: [
      Container(
        width: 52, height: 52,
        decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
        child: Center(child: child),
      ),
      const SizedBox(height: 8),
      Text(label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]);
  }
}

// ── Horizontal dashed line ──────────────────────────────────────────────
class _HDashPainter extends CustomPainter {
  final Color color;
  _HDashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 6.0, gap = 5.0;
    final y = size.height / 2;
    double x = 6;
    while (x < size.width - 6) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width - 6), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _HDashPainter old) => old.color != color;
}