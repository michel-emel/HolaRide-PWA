import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';
import '../../models/trip.dart';
import '../../services/api_client.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_labels.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/profile_icon_button.dart';

/// Screen 15 — Cancel / Withdraw.
///
/// Used for two related but distinct actions: withdrawing a request
/// that hasn't been paid yet (free, since nothing was charged), or
/// cancelling a paid booking (subject to the admin-configured,
/// time-tiered cancellation fee). The copy below reflects whichever
/// case applies — same screen, no fee surprise either way.
class CancelWithdrawScreen extends StatefulWidget {
  final Trip? trip;
  final Booking booking;
  const CancelWithdrawScreen({super.key, required this.trip, required this.booking});

  @override
  State<CancelWithdrawScreen> createState() => _CancelWithdrawScreenState();
}

class _CancelWithdrawScreenState extends State<CancelWithdrawScreen> {
  bool _submitting = false;
  String? _error;

  bool get _isPaid => widget.booking.status == BookingStatus.paid;

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime t) {
    return '${t.day} ${monthAbbrev(context, t.month)} ${t.year}';
  }

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await BookingService.instance.cancel(widget.booking.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/bookings/cancel_withdraw_screen.dart: $e');
      setState(() => _error = AppLocalizations.of(context).cancelError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final trip = widget.trip;
    final booking = widget.booking;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: !_submitting,
        actions: const [ProfileIconButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(color: AppColors.warningBg, shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, size: 50, color: AppColors.warning),
            ),
            const SizedBox(height: 24),
            Text(
              _isPaid ? l.cancelTripTitle : l.withdrawTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              _isPaid ? l.cancelTripBody : l.withdrawBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            if (trip != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${trip.originCity} → ${trip.destinationCity}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
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
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    const SizedBox(height: 4),
                    Text(
                        booking.seats > 1
                            ? l.bookingsSeatPlural(booking.seats)
                            : l.bookingsSeatSingular(booking.seats),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
            const SizedBox(height: 26),
            PrimaryButton(
              label: _isPaid ? l.cancelTripBtn : l.withdrawBtn,
              backgroundColor: AppColors.danger,
              onPressed: _confirm,
              loading: _submitting,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
              child: Text(_isPaid ? l.keepTripBtn : l.keepRequestBtn),
            ),
          ],
        ),
      ),
    );
  }
}
