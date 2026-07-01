import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/trip.dart';
import '../../services/api_client.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/profile_icon_button.dart';
import 'waiting_for_driver_screen.dart';

/// Screen 10 — Request screen ("Step 1 of 2").
///
/// This only sends the *request* — per the booking acceptance workflow,
/// payment is blocked until the driver explicitly accepts, so there's
/// no payment step here even though a price is shown.
class BookingRequestScreen extends StatefulWidget {
  final Trip trip;
  const BookingRequestScreen({super.key, required this.trip});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  int _seats = 1;
  PaymentOption _paymentOption = PaymentOption.full;
  bool _submitting = false;
  String? _error;

  String _money(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf XAF';
  }

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime t) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${t.day} ${months[t.month - 1]} ${t.year}';
  }

  num get _total => widget.trip.pricePerSeat * _seats;

  /// Matches the backend exactly: `partial_80` means 80% is due NOW,
  /// the remaining 20% before departure — confirmed in
  /// app/routers/bookings.py (`amount_due_now = round(price_total * 0.8, 2)`).
  num get _depositDueNow => (_total * 0.8).round();
  num get _depositRemaining => _total - _depositDueNow;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final booking = await BookingService.instance.requestBooking(
        tripId: widget.trip.id,
        seats: _seats,
        paymentOption: _paymentOption,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WaitingForDriverScreen(trip: widget.trip, booking: booking),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/trip/booking_request_screen.dart: $e');
      setState(() => _error = 'Could not send your request. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Request a Seat'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [ProfileIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                child: const Text('Step 1 of 2',
                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Full trip detail, repeated here rather than assumed —
          // this is a commitment screen (sends a real request to the
          // driver), so there should be zero doubt about which trip
          // it's for.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${trip.originCity} → ${trip.destinationCity}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
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
                if (trip.originLocation.isNotEmpty || trip.destinationLocation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  if (trip.originLocation.isNotEmpty)
                    _pointRow(Icons.fiber_manual_record, AppColors.primary, 'Departure point', trip.originLocation),
                  if (trip.originLocation.isNotEmpty && trip.destinationLocation.isNotEmpty)
                    const SizedBox(height: 10),
                  if (trip.destinationLocation.isNotEmpty)
                    _pointRow(Icons.location_on, AppColors.gold, 'Drop-off point', trip.destinationLocation),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seats', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove,
                      onTap: _seats > 1 ? () => setState(() => _seats--) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text('$_seats', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    ),
                    _StepperButton(
                      icon: Icons.add,
                      onTap: _seats < trip.seatsAvailable ? () => setState(() => _seats++) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${trip.seatsAvailable} seats available',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text('Payment option',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
                const SizedBox(height: 12),
                _PaymentOptionTile(
                  title: 'Pay Full',
                  subtitle: _money(_total),
                  selected: _paymentOption == PaymentOption.full,
                  onTap: () => setState(() => _paymentOption = PaymentOption.full),
                ),
                const SizedBox(height: 10),
                _PaymentOptionTile(
                  title: 'Pay 80% Deposit',
                  subtitle: 'Pay ${_money(_depositDueNow)} now, ${_money(_depositRemaining)} before trip',
                  selected: _paymentOption == PaymentOption.deposit,
                  onTap: () => setState(() => _paymentOption = PaymentOption.deposit),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, size: 15, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _paymentOption == PaymentOption.deposit ? 'Due now' : 'Total',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text(
                      _money(_paymentOption == PaymentOption.deposit ? _depositDueNow : _total),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                    ),
                  ],
                ),
                if (_paymentOption == PaymentOption.deposit) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining before trip',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                      Text(_money(_depositRemaining),
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(label: 'Continue', onPressed: _submit, loading: _submitting),
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
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.infoBg : AppColors.background,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: enabled ? AppColors.primary : AppColors.textSecondary),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.infoBg : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}