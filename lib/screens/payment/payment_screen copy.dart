import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/booking.dart';
import '../../models/trip.dart';
import '../../theme/app_colors.dart';
import '../../services/payment_service.dart';
import '../../services/api_client.dart';
import '../../services/session_service.dart';
import '../main_tab_screen.dart';

// ── Operator colors ──────────────────────────────────────────────
const _mtnYellow    = Color(0xFFFFCC00);
const _mtnDark      = Color(0xFF1A1A1A);
const _orangeOrange = Color(0xFFFF6600);

class PaymentScreen extends StatefulWidget {
  final Trip trip;
  final Booking booking;
  const PaymentScreen({super.key, required this.trip, required this.booking});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum _Step { idle, processing, pending }

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  _Step _step = _Step.idle;
  String? _userPhone;   // account phone (from session)
  String? _payPhone;    // number that will actually be charged (changeable)
  String? _operator;    // 'mtn' | 'orange'
  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _pollCount = 0;
  int _countdown = 300; // 5 min countdown for user to confirm
  static const _maxPolls = 60; // 5 min

  late AnimationController _pulseCtrl;
  late AnimationController _successCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnim   = Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _successAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _loadPhone();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPhone() async {
    final user = await SessionService.instance.getUser();
    if (!mounted) return;
    final phone = user?.phone ?? '';
    setState(() {
      _userPhone = phone;
      _payPhone = phone;
      _operator = _detectOperator(phone);
    });
  }

  String _detectOperator(String phone) {
    final local = phone.replaceAll('+', '').replaceAll('237', '');
    final prefix = local.length >= 3 ? local.substring(0, 3) : '';
    const orange = {'655','656','657','658','659','687','688','689','690','691','692','693','694','695','696','697','698','699'};
    return orange.contains(prefix) ? 'orange' : 'mtn';
  }

  String _fmt(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf XAF';
  }

  String get _countdownLabel {
    final m = _countdown ~/ 60;
    final s = _countdown % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  num get _amountDue =>
      widget.booking.amountDue > 0 ? widget.booking.amountDue : widget.booking.amountTotal;

  Color get _opColor => _operator == 'orange' ? _orangeOrange : _mtnYellow;
  Color get _opDark  => _operator == 'orange' ? Colors.white  : _mtnDark;
  String get _opName => _operator == 'orange' ? 'Orange Money' : 'MTN MoMo';
  String get _opUssd => _operator == 'orange' ? '#150#' : '*126#';

  // ── Change the number that will be charged ──────────────────────
  Future<void> _changePayPhone() async {
    final current = (_payPhone ?? '').replaceAll('+237', '');
    final ctrl = TextEditingController(text: current);
    String? error;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pay with a different number',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('The Mobile Money prompt will be sent to this number.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(.55), width: 1.2),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: const BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(13)),
                    ),
                    child: const Row(children: [
                      Text('🇨🇲', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 6),
                      Text('+237', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 9,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: .5),
                      decoration: const InputDecoration(
                        hintText: '675 123 456',
                        counterText: '',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setSheet(() => error = null),
                    ),
                  ),
                ]),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final d = ctrl.text.trim();
                    if (d.length != 9 || !d.startsWith(RegExp(r'[6][0-9]'))) {
                      setSheet(() => error = 'Enter a valid 9-digit number starting with 6.');
                      return;
                    }
                    Navigator.of(ctx).pop('+237$d');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Use this number', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _payPhone = result;
        _operator = _detectOperator(result);
      });
    }
  }

  Future<void> _pay() async {
    setState(() => _step = _Step.processing);
    try {
      // TODO(wiring): pass `_payPhone` through PaymentService.initiatePayment
      // and the backend `initiate-payment` endpoint so a different number
      // than the account's can actually be charged. Until that's wired,
      // the provider charges the account number.
      await PaymentService.instance.initiatePayment(widget.booking.id);
      setState(() { _step = _Step.pending; _countdown = 300; });
      _startPolling();
      _startCountdown();
    } on ApiException catch (e) {
      setState(() => _step = _Step.idle);
      _showFailureDialog(e.message);
    } catch (_) {
      setState(() => _step = _Step.idle);
      _showFailureDialog('Could not reach the payment provider. Try again.');
    }
  }

  Future<void> _simulate() async {
    setState(() => _step = _Step.processing);
    try {
      await Future.delayed(const Duration(seconds: 2));
      await PaymentService.instance.devForcePaid(widget.booking.id);
      if (mounted) {
        setState(() => _step = _Step.idle);
        _showSuccessDialog();
      }
    } on ApiException catch (e) {
      if (mounted) { setState(() => _step = _Step.idle); _showFailureDialog(e.message); }
    } catch (_) {
      if (mounted) { setState(() => _step = _Step.idle); _showFailureDialog('Simulation failed.'); }
    }
  }

  void _startPolling() {
    _pollCount = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      _pollCount++;
      try {
        final result = await PaymentService.instance.getPaymentStatus(widget.booking.id);
        if (!mounted) return;
        if (result.status == 'success' || result.status == 'paid') {
          _pollTimer?.cancel(); _countdownTimer?.cancel();
          setState(() => _step = _Step.idle);
          _showSuccessDialog();
        } else if (result.status == 'failed') {
          _pollTimer?.cancel(); _countdownTimer?.cancel();
          _handleFailure(result.failureReason, result.errorMessage);
        } else if (_pollCount >= _maxPolls) {
          _pollTimer?.cancel(); _countdownTimer?.cancel();
          setState(() => _step = _Step.idle);
          _showFailureDialog('Payment timed out. Please try again.');
        }
      } catch (_) {}
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() { if (_countdown > 0) _countdown--; });
    });
  }

  void _handleFailure(String? reason, String? serverMessage) {
    setState(() => _step = _Step.idle);
    switch (reason) {
      case 'insufficient_balance':
        _showInsufficientBalance();
      case 'user_cancelled':
        _showFailureDialog('You cancelled the payment on your phone. Tap "Try again" to retry.');
      default:
        _showFailureDialog(serverMessage ?? 'Payment failed. Please try again.');
    }
  }

  // ── Success pop-up ───────────────────────────────────────────────
  void _showSuccessDialog() {
    _successCtrl.reset();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ScaleTransition(
              scale: _successAnim,
              child: Container(
                width: 88, height: 88,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 22),
            const Text('Payment confirmed!',
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w900,
                    fontSize: 22, color: AppColors.primary)),
            const SizedBox(height: 10),
            const Text('Your seat is secured.\nThe driver has been notified.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () { Navigator.of(context).pop(); _goHome(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
    _successCtrl.forward();
  }

  // ── Failure pop-up ───────────────────────────────────────────────
  void _showFailureDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: AppColors.dangerBg, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 42),
            ),
            const SizedBox(height: 20),
            const Text('Payment failed',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.danger)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Try again', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () { Navigator.of(context).pop(); _goHome(); },
              child: const Text('Go back to Home',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
            ),
          ]),
        ),
      ),
    );
  }

  void _showInsufficientBalance() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: _opColor.withOpacity(.15), shape: BoxShape.circle),
              child: const Center(child: Text('💰', style: TextStyle(fontSize: 30))),
            ),
            const SizedBox(height: 16),
            const Text('Insufficient Balance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 8),
            Text(
              'Your $_opName balance is too low for ${_fmt(_amountDue)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _opColor.withOpacity(.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _opColor.withOpacity(.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Top up $_opName',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                        color: _operator == 'orange' ? _orangeOrange : Colors.black87)),
                const SizedBox(height: 4),
                Text('Dial $_opUssd on your phone, then retry.',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () { Navigator.pop(context); _goHome(); },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('Try again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _goHome() {
    _pollTimer?.cancel(); _countdownTimer?.cancel();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainTabScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        automaticallyImplyLeading: _step == _Step.idle,
        leading: _step == _Step.idle
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
                  ),
                ),
              )
            : null,
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_step) {

      // ── IDLE ────────────────────────────────────────────────────
      case _Step.idle:
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // Operator banner
            if (_operator != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _opColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  _OpLogo(operator: _operator!, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_opName,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _opDark)),
                      Text('Auto-detected from your number',
                          style: TextStyle(fontSize: 11.5, color: _opDark.withOpacity(.7))),
                    ]),
                  ),
                ]),
              ),

            // Amount card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Column(children: [
                // Route
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.route, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${widget.trip.originCity} → ${widget.trip.destinationCity}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('${widget.booking.seats} seat${widget.booking.seats > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ])),
                  if (widget.trip.vehicleCategory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(widget.trip.vehicleCategory,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                ]),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),

                // Amount
                Column(children: [
                  const Text('Amount due',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_fmt(_amountDue), style: const TextStyle(
                    fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w900,
                    fontSize: 40, color: AppColors.primary, letterSpacing: -1,
                  )),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.shield_outlined, size: 13, color: AppColors.primary),
                      SizedBox(width: 5),
                      Text('Fees: 2% included',
                          style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Payer phone + Change
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                    child: const Icon(Icons.phone_outlined, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Phone number',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(_payPhone ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ]),
                  ),
                  OutlinedButton(
                    onPressed: _changePayPhone,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withOpacity(.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      // The app's global OutlinedButton theme forces a
                      // full-width minimumSize; inside a Row (unbounded
                      // width) that means w=Infinity → layout crash.
                      // Override it locally.
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Change', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  ),
                ]),
              ]),
            ),

            const SizedBox(height: 16),

            // Prompt info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.smartphone_outlined, size: 19, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text.rich(TextSpan(
                  text: "You'll receive a $_opName prompt on ",
                  style: const TextStyle(fontSize: 13, color: AppColors.primary, height: 1.45),
                  children: [
                    TextSpan(text: '${_payPhone ?? ''}.',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const TextSpan(text: '\nConfirm on your phone to complete the payment.'),
                  ],
                ))),
              ]),
            ),

            const SizedBox(height: 24),

            // Pay button
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: ElevatedButton(
                onPressed: _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock_outline, size: 18),
                  const SizedBox(width: 10),
                  Text('Pay ${_fmt(_amountDue)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
              ),
            ),

            const SizedBox(height: 12),

            // Simulate (dev)
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _simulate,
                icon: const Icon(Icons.science_outlined, size: 15),
                label: const Text('Simulate Payment (dev only)', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        );

      // ── PROCESSING ──────────────────────────────────────────────
      case _Step.processing:
        return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          SizedBox(height: 24),
          Text('Connecting to Mobile Money...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          SizedBox(height: 8),
          Text('Please wait', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ]));

      // ── PENDING ─────────────────────────────────────────────────
      case _Step.pending:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

            // Animated phone icon
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: _opColor.withOpacity(.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _opColor.withOpacity(.4), width: 2),
                ),
              child: Center(child: _OpLogo(operator: _operator ?? 'mtn', size: 56)),
              ),
            ),
            const SizedBox(height: 28),

            const Text('Check your phone', style: TextStyle(
              fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w800,
              fontSize: 24, color: AppColors.textPrimary,
            )),
            const SizedBox(height: 10),
            Text(
              'A $_opName payment request was sent to\n${_payPhone ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),

            // Countdown ring
            SizedBox(
              width: 80, height: 80,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: _countdown / 300,
                  strokeWidth: 5,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(_opColor),
                ),
                Text(_countdownLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
              ]),
            ),
            const SizedBox(height: 12),
            const Text('to confirm', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),

            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.infoBg, borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Text('Open $_opName on your phone',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                const SizedBox(height: 2),
                Text('or dial $_opUssd to approve the request',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),

            const SizedBox(height: 24),
            TextButton(
              onPressed: _goHome,
              child: const Text('Cancel payment', style: TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
          ]),
        );
    }
  }
}

/// Real operator logo from assets, with a safe fallback if the asset
/// is missing (colored badge with the operator initials) so the screen
/// never crashes or shows a broken image.
class _OpLogo extends StatelessWidget {
  final String operator; // 'mtn' | 'orange'
  final double size;
  const _OpLogo({required this.operator, required this.size});

  @override
  Widget build(BuildContext context) {
    final isOrange = operator == 'orange';
    final asset = isOrange
        ? 'assets/images/orange_money.png'
        : 'assets/images/mtn_momo.png';
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Center(
          child: Text(
            isOrange ? 'OM' : 'MTN',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: size * 0.3,
              color: isOrange ? _orangeOrange : _mtnDark,
            ),
          ),
        ),
      ),
    );
  }
}