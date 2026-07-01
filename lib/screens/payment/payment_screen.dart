import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/payment_status.dart';
import '../../models/trip.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/booking_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/profile_icon_button.dart';
import '../main_tab_screen.dart';

/// Screen 12 — Payment screen.
///
/// Shown once the driver has accepted — this is the first moment a
/// passenger is allowed to pay, per the booking acceptance workflow.
///
/// There's no MTN/Orange picker or "number to charge" field here
/// anymore — confirmed against the real backend source, the
/// initiate-payment endpoint takes no request body at all. It always
/// charges whatever phone number is on your account and detects the
/// provider itself via PawaPay. A picker here would just be UI the
/// backend silently ignores, so this screen now shows the real number
/// that's actually about to be charged instead.
class PaymentScreen extends StatefulWidget {
  final Trip trip;
  final Booking booking;
  const PaymentScreen({super.key, required this.trip, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  AppUser? _user;
  bool _paying = false;
  bool _waitingConfirmation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await SessionService.instance.getUser();
    if (mounted) setState(() => _user = user);
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

  num get _amountDue => widget.booking.paymentOption == PaymentOption.deposit
      ? (widget.booking.amountTotal * 0.8).round()
      : widget.booking.amountTotal;

  Future<void> _completeSuccess() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Payment confirmed'),
        content: Text(
          widget.booking.paymentOption == PaymentOption.deposit
              ? 'Your 20% deposit was received. The rest is due before the trip.'
              : 'Your seat is booked. Have a safe trip!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainTabScreen()),
      (route) => false,
    );
  }

  /// DEV-ONLY shortcut for while real PawaPay payment is still being
  /// worked out — see `BookingService.devForcePaid` for the actual
  /// safety mechanism (a server-side 404 unless `PAYMENT_DEV_MODE` is
  /// explicitly on, forcibly disabled in production regardless). This
  /// button only renders in debug builds at all (see `kDebugMode` in
  /// the build method below) as an extra belt-and-suspenders measure,
  /// but that's a convenience, not the real protection.
  Future<void> _simulatePayment() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      await BookingService.instance.devForcePaid(widget.booking.id);
      if (!mounted) return;
      await _completeSuccess();
    } on ApiException catch (e) {
      setState(() => _error = 'Dev simulate failed: ${e.message} (is PAYMENT_DEV_MODE on in your .env?)');
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/payment/payment_screen.dart: $e');
      setState(() => _error = 'Could not simulate payment.');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _pay() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      await BookingService.instance.initiatePayment(bookingId: widget.booking.id);
      if (!mounted) return;
      // Mobile Money is asynchronous — a USSD prompt just went to their
      // phone. Wait here and poll rather than assuming success.
      setState(() => _waitingConfirmation = true);
      final status = await BookingService.instance.pollPaymentStatus(widget.booking.id);
      if (!mounted) return;
      setState(() => _waitingConfirmation = false);

      if (status == PaymentStatus.paid) {
        await _completeSuccess();
      } else {
        setState(() => _error = switch (status) {
              PaymentStatus.failed => 'The payment failed. Check your Mobile Money balance and try again.',
              PaymentStatus.expired => 'The payment request expired before you confirmed it. Try again.',
              _ => 'Still waiting on confirmation — check your phone, then try again if nothing came through.',
            });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/payment/payment_screen.dart: $e');
      setState(() => _error = 'Payment could not be completed. Try again.');
    } finally {
      if (mounted) {
        setState(() {
          _paying = false;
          _waitingConfirmation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [ProfileIconButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                child: const Icon(Icons.shield_outlined, size: 40, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Complete your payment',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'The driver has accepted your request.\nPlease pay to confirm your booking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.trip.originCity} → ${widget.trip.destinationCity}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  if (widget.trip.originLocation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.fiber_manual_record, size: 9, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(widget.trip.originLocation,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  if (widget.trip.destinationLocation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 11, color: AppColors.gold),
                        const SizedBox(width: 5),
                        Text(widget.trip.destinationLocation,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${widget.trip.departureTime.day}/${widget.trip.departureTime.month}/${widget.trip.departureTime.year}'
                    ' · ${widget.trip.departureTime.hour.toString().padLeft(2, '0')}:${widget.trip.departureTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.booking.seats} seat${widget.booking.seats > 1 ? 's' : ''}'
                    '${widget.booking.paymentOption == PaymentOption.deposit ? ' · 20% deposit' : ''}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smartphone, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mobile Money number',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        Text(
                          _user?.phone ?? '...',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'MTN or Orange Money is detected automatically — you\'ll get a USSD prompt on this number.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ),
            if (_waitingConfirmation) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check your phone — confirm the Mobile Money prompt to finish.',
                        style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: _waitingConfirmation ? 'Waiting for confirmation...' : 'Pay ${_money(_amountDue)}',
              onPressed: _pay,
              loading: _paying,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: (_paying || _waitingConfirmation) ? null : _simulatePayment,
                icon: const Icon(Icons.bug_report_outlined, size: 18),
                label: const Text('Simulate payment (dev only)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Only visible in debug builds. Bypasses real Mobile Money — '
                'works only while PAYMENT_DEV_MODE is on in the backend.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 13, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Text('Your payment is secure and encrypted.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
