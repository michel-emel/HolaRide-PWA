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
  final _otpKey = GlobalKey<OtpInputState>();
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  Timer? _timer;
  int _secondsLeft = 45;
  String? _devCode;

  @override
  void initState() {
    super.initState();
    _devCode = widget.devCode;
    _startCountdown();
  }

  void _startCountdown() {
    _secondsLeft = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) { t.cancel(); }
      else { setState(() => _secondsLeft--); }
    });
  }

  String get _formattedCountdown {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; });
    try {
      final devCode = await AuthService.instance.requestOtp(widget.phone);
      _otpKey.currentState?.clear();
      setState(() => _devCode = devCode);
      _startCountdown();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).otpErrorResend);
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
          Text(l.otpAccountExistsTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
          Text(l.otpNoAccountTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
    setState(() { _verifying = true; _error = null; });
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
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0),
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(offset: Offset(0, 16 * (1 - value)), child: child),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(child: Column(children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.sms_rounded, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.skipNameScreen ? l.otpSignInTitle : l.otpVerifyTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(TextSpan(
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    children: [
                      TextSpan(text: l.otpSentTo),
                      TextSpan(text: widget.phone,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(l.otpWrongNumber,
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ])),

                if (_devCode != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Text('🧪', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(l.otpDevMode(_devCode!),
                          style: const TextStyle(fontSize: 11.5, color: AppColors.warning, fontWeight: FontWeight.w600))),
                    ]),
                  ),
                ],

                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface, borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Column(children: [
                    OtpInput(key: _otpKey, onCompleted: _verify),
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
                      Text(l.otpVerifying, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Row(children: [
                        const Icon(Icons.error_outline, size: 15, color: AppColors.danger),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5))),
                      ]),
                    ],
                  ]),
                ),

                const SizedBox(height: 22),
                Center(child: _secondsLeft > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(20)),
                        child: Text(l.otpResendIn(_formattedCountdown),
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      )
                    : GestureDetector(
                        onTap: _resending ? null : _resend,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (_resending)
                              const SizedBox(width: 13, height: 13,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                            else
                              const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 7),
                            Text(_resending ? l.otpResending : l.otpResend,
                                style: const TextStyle(fontSize: 13.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
