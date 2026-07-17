import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../widgets/otp_input.dart';
import '../main_tab_screen.dart';
import 'name_entry_screen.dart';
import 'welcome_screen.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String phone;
  final String? devCode;
  final bool isGate;
  final bool skipNameScreen;
  const OtpVerifyScreen({
    super.key,
    required this.phone,
    this.devCode,
    this.isGate = false,
    this.skipNameScreen = false,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const int _totalSeconds = 45;

  final _otpKey = GlobalKey<OtpInputState>();
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  Timer? _timer;
  int _secondsLeft = _totalSeconds;
  String? _devCode;

  @override
  void initState() {
    super.initState();
    _devCode = widget.devCode;
    _startCountdown();
  }

  void _startCountdown() {
    _secondsLeft = _totalSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _formattedCountdown {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final devCode = await AuthService.instance.requestOtp(widget.phone);
      _otpKey.currentState?.clear();
      setState(() => _devCode = devCode);
      _startCountdown();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).otpErrorResend);
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _goHome() {
    if (widget.isGate) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainTabScreen()),
        (route) => false,
      );
    }
  }

  void _showAccountExistsDialog() {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('✅', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(l.otpAccountExistsTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        content: Text(l.otpAccountExistsBody,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => WelcomeScreen(isGate: widget.isGate)),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.welcomeSignIn,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showNoAccountDialog() {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('👤', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(l.otpNoAccountTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        content: Text(l.otpNoAccountBody,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => WelcomeScreen(isGate: widget.isGate)),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.otpCreateAccount,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _verify(String code) async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final result = await AuthService.instance.verifyOtp(widget.phone, code);
      if (!mounted) return;

      if (widget.skipNameScreen) {
        if (result.isNewUser) {
          _showNoAccountDialog();
        } else {
          _goHome();
        }
      } else {
        if (!result.isNewUser) {
          _showAccountExistsDialog();
        } else if (result.needsName) {
          final completed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => NameEntryScreen(isGate: widget.isGate)),
          );
          if (!mounted) return;
          if (widget.isGate && completed == true) Navigator.of(context).pop(true);
        } else {
          _goHome();
        }
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      _otpKey.currentState?.shake();
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).otpErrorVerify);
      _otpKey.currentState?.shake();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // "Sign in to HolaRide" / "Verify your number" — last word in green.
    final titleWords = (widget.skipNameScreen ? l.otpSignInTitle : l.otpVerifyTitle).trim().split(' ');
    final titleLast = titleWords.isNotEmpty ? titleWords.removeLast() : '';
    final titleRest = titleWords.join(' ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Back button ─────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Icon badge ───────────────────────────────────
                Center(
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sms_rounded, color: AppColors.primary, size: 30),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Title ────────────────────────────────────────
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
                    children: [
                      TextSpan(text: titleLast.isEmpty ? '' : '$titleRest ',
                          style: const TextStyle(color: AppColors.textPrimary)),
                      TextSpan(text: titleLast, style: const TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Subtitle: sent-to phone ─────────────────────
                Text(l.otpSentTo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(widget.phone,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),

                const SizedBox(height: 16),

                // ── "Secure and private" badge ──────────────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.verified_user_outlined, size: 15, color: AppColors.primary),
                      const SizedBox(width: 7),
                      const Text('Your code is secure and private',
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(l.otpWrongNumber,
                          style: const TextStyle(
                              fontSize: 13.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),

                if (_devCode != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.build_outlined, size: 15, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l.otpDevMode(_devCode!),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ],

                const SizedBox(height: 22),

                // ── OTP card ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enter the 6-digit code',
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      Center(child: OtpInput(key: _otpKey, onCompleted: _verify)),

                      if (_verifying) ...[
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: AppColors.surfaceMuted,
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(l.otpVerifying,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Row(children: [
                          const Icon(Icons.error_outline, size: 15, color: AppColors.danger),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                          ),
                        ]),
                      ],

                      const SizedBox(height: 16),
                      Row(children: [
                        const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                              children: [
                                const TextSpan(text: "Didn't receive the code? "),
                                TextSpan(text: 'Check your SMS',
                                    style: const TextStyle(
                                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                                const TextSpan(text: ' or try again.'),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── Resend row with circular countdown ──────────
                if (_secondsLeft > 0)
                  Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Resend code in',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 46, height: 46,
                        child: Stack(alignment: Alignment.center, children: [
                          SizedBox(
                            width: 46, height: 46,
                            child: CircularProgressIndicator(
                              value: _secondsLeft / _totalSeconds,
                              strokeWidth: 3,
                              backgroundColor: AppColors.surfaceMuted,
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                          Text(_formattedCountdown,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ]),
                      ),
                    ]),
                  )
                else ...[
                  Row(children: [
                    Expanded(child: Divider(color: AppColors.border.withOpacity(.8))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text('or', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ),
                    Expanded(child: Divider(color: AppColors.border.withOpacity(.8))),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _resending ? null : _resend,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _resending
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.send_outlined, size: 17),
                              const SizedBox(width: 9),
                              Text(l.otpResend,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ]),
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // ── Need help ────────────────────────────────────
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support: coming soon')),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      Container(
                        width: 34, height: 34,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.headset_mic_outlined, size: 17, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: 'Need help? ',
                                style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary)),
                            TextSpan(text: 'Contact our support team',
                                style: TextStyle(
                                    fontSize: 13.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}