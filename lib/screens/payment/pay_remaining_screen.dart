import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/payment_status.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/booking_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/profile_icon_button.dart';

/// Screen 13 — Pay remaining balance.
///
/// Shown for a deposit booking once it's time to settle the remaining
/// 20% before the trip.
///
/// No MTN/Orange picker or "number to charge" field here anymore —
/// confirmed against the real backend source, `pay-balance` takes no
/// request body at all and always charges whatever number is on your
/// account, detecting the provider itself. This screen now shows the
/// real number instead of a picker the backend would've ignored.
class PayRemainingScreen extends StatefulWidget {
  final Booking booking;
  const PayRemainingScreen({super.key, required this.booking});

  @override
  State<PayRemainingScreen> createState() => _PayRemainingScreenState();
}

class _PayRemainingScreenState extends State<PayRemainingScreen> {
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

  /// DEV-ONLY shortcut — see `payment_screen.dart` for the full
  /// explanation. Same backend endpoint, same server-side 404 unless
  /// `PAYMENT_DEV_MODE` is on, same `kDebugMode` gate on this button.
  Future<void> _simulatePayment() async {
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      await BookingService.instance.devForcePaid(widget.booking.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = 'Dev simulate failed: ${e.message} (is PAYMENT_DEV_MODE on in your .env?)');
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/payment/pay_remaining_screen.dart: $e');
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
      await BookingService.instance.initiateBalancePayment(bookingId: widget.booking.id);
      if (!mounted) return;
      setState(() => _waitingConfirmation = true);
      final status = await BookingService.instance.pollPaymentStatus(widget.booking.id);
      if (!mounted) return;
      setState(() => _waitingConfirmation = false);

      if (status == PaymentStatus.paid) {
        Navigator.of(context).pop(true);
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
      print('Error in lib/screens/payment/pay_remaining_screen.dart: $e');
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

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime t) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${t.day} ${months[t.month - 1]} ${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final trip = booking.trip;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pay remaining balance'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [ProfileIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (trip != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
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
                  Text('${trip.originCity} → ${trip.destinationCity}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  if (trip.originLocation.isNotEmpty) ...[
                    const SizedBox(height: 4),
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
                  const SizedBox(height: 4),
                  Text('${_dateLabel(trip.departureTime)} · ${_timeLabel(trip.departureTime)}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('20% deposit paid', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(_money(booking.amountPaid),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Remaining balance', style: TextStyle(color: AppColors.textSecondary)),
                Text(_money(booking.amountDue),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
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
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2)),
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
            label: _waitingConfirmation ? 'Waiting for confirmation...' : 'Pay ${_money(booking.amountDue)}',
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
        ],
      ),
    );
  }
}
