import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/trip.dart';
import '../../services/api_client.dart';
import '../../services/booking_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/profile_icon_button.dart';
import 'waiting_for_driver_screen.dart';

/// Screen 10 — Request screen ("Step 1 of 2").
///
/// Sends the booking *request*; the driver must accept before payment
/// is actually captured, but the person still picks how they'll pay
/// (full vs. 80% deposit) up front so the "Total to pay" breakdown
/// reflects it once the driver accepts.
///
/// The seat counter is capped by the trip's real availability
/// (`trip.seatsAvailable`, from `GET /trips/{id}` / search results) —
/// no artificial per-booking cap.
///
/// ⚠️ MOCK / TODO fields (not on the backend yet):
///   - "You can cancel for free up to 2 hours before departure" policy copy
class BookingRequestScreen extends StatefulWidget {
  final Trip trip;
  const BookingRequestScreen({super.key, required this.trip});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

/// TODO(backend): replace once this has a real field/endpoint.
class _Mock {
  static const cancellationWindow = 'You can cancel for free up to 2 hours before departure.';
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

  /// Real cap: exactly what the backend says is still available.
  int get _maxSelectable => widget.trip.seatsAvailable;

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
        leading: const BackButton(),
        title: const Text('Request a Seat'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [ProfileIconButton(), SizedBox(width: 12)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: const Text('Step 1 of 2',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              // Static reassurance copy — same pattern as the "Verified
              // Trip" badge on the trip detail screen.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified_user, size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Safe · Secure · Trusted',
                        style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSeatsCard(trip),
          const SizedBox(height: 16),
          _buildRequestNoticeCard(),
          const SizedBox(height: 16),
          _buildPaymentSummaryCard(trip),
          const SizedBox(height: 14),
          _buildCancellationBanner(),
          const SizedBox(height: 16),
          _buildSubmitButton(),
          const SizedBox(height: 14),
          _buildFooterNote(),
        ],
      ),
    );
  }

  Widget _buildSeatsCard(Trip trip) {
    // Show at most 5 seat pictograms so the row never overflows on
    // small screens; the pictograms light up with the current selection.
    final iconCount = trip.seatsAvailable > 5 ? 5 : trip.seatsAvailable;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How many seats do you need?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
          const SizedBox(height: 14),
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
                onTap: _seats < _maxSelectable ? () => setState(() => _seats++) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${trip.seatsAvailable} seats available',
                    style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(iconCount, (i) {
                  final selected = i < _seats;
                  return Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(Icons.event_seat,
                        size: 24,
                        color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.2)),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestNoticeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your request will be sent to the driver',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: const Icon(Icons.send_outlined, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("You're not paying yet",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Colors.black)),
                      const SizedBox(height: 3),
                      const Text(
                        "Your request will be sent to the driver. You'll only pay after the driver accepts your request.",
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 20, color: AppColors.primary),
                    const SizedBox(height: 26),
                  ],
                ),
                SizedBox(
                  width: 34,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      4,
                      (_) => Container(width: 3, height: 3, decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle,
                          )),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -0.55,
                  child: const Icon(Icons.send, size: 15, color: AppColors.primary),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.gold.withOpacity(0.18),
                  child: Icon(Icons.person, size: 14, color: AppColors.gold.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(Trip trip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment option',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
          const SizedBox(height: 12),
          _PaymentOptionTile(
            icon: Icons.check_circle_outline,
            title: 'Pay Full',
            subtitle: 'Pay ${_money(_total)} now.',
            price: _money(_total),
            selected: _paymentOption == PaymentOption.full,
            onTap: () => setState(() => _paymentOption = PaymentOption.full),
          ),
          const SizedBox(height: 10),
          _PaymentOptionTile(
            icon: Icons.percent,
            title: 'Pay 80% Deposit',
            subtitle: 'Pay ${_money(_depositDueNow)} now,\n${_money(_depositRemaining)} before the trip.',
            price: _money(_depositDueNow),
            tag: 'Pay balance before trip',
            selected: _paymentOption == PaymentOption.deposit,
            onTap: () => setState(() => _paymentOption = PaymentOption.deposit),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total to pay',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black)),
              const SizedBox(width: 6),
              const Text('(paid after driver accepts)',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price per seat', style: TextStyle(fontSize: 13.5, color: Colors.black)),
              Text(_money(trip.pricePerSeat), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Seats', style: TextStyle(fontSize: 13.5, color: Colors.black)),
              Text('$_seats', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_paymentOption == PaymentOption.deposit ? 'Due now' : 'Total amount',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black)),
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
          if (_error != null) ...[
            const SizedBox(height: 14),
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
    );
  }

  // TODO(backend): cancellation window is static copy — confirm the
  // real policy value with backend and wire it up if it can vary.
  Widget _buildCancellationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_Mock.cancellationWindow,
                style: const TextStyle(fontSize: 12.5, color: Colors.black, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _submitting
            ? const SizedBox(
                height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Send Request to Driver',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5)),
                      SizedBox(height: 2),
                      Text('Driver must accept before booking is confirmed',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                    ],
                  ),
                  const SizedBox(width: 14),
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        const Text('Your safety is our priority. ',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const Text('Learn more',
            style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.infoBg : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: enabled ? AppColors.primary : AppColors.textSecondary),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final String? tag;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    this.tag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.infoBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.4 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black)),
                if (tag != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tag!,
                        style: const TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}