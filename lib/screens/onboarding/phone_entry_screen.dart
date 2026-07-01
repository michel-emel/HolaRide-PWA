import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../widgets/primary_button.dart';
import 'otp_verify_screen.dart';
import '../profile/terms_privacy_screen.dart';

/// Screen 2 — Phone entry.
///
/// Cameroon-only for now, so the country code is fixed rather than a
/// full picker — if HolaRide ever expands beyond Cameroon, swap the
/// fixed prefix below for a real country-code dropdown.
///
/// This screen now runs in two modes:
/// - **Fresh start** (`isGate: false`, the default) — reached from
///   Splash's "Get Started" or Profile's "Log out", with nothing
///   awaiting a result. On success it navigates forward and replaces
///   the whole stack with Home, same as before.
/// - **Gate** (`isGate: true`) — pushed mid-task by `requireLogin()`
///   when a guest taps something that needs an account (booking,
///   publishing a trip, etc), or from the guest nav bar's "Login" tab.
///   On success it pops itself (and the screens it pushed) back to
///   whoever called it, returning `true` so the original action can
///   proceed.
class PhoneEntryScreen extends StatefulWidget {
  final bool isGate;
  final String? gateReason;
  const PhoneEntryScreen({super.key, this.isGate = false, this.gateReason});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _controller = TextEditingController();
  final _termsRecognizer = TapGestureRecognizer();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _termsRecognizer.onTap = () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()),
        );
  }

  bool get _isValid {
    final digits = _controller.text.trim();
    return digits.length == 9 && digits.startsWith(RegExp(r'[6][0-9]'));
  }

  Future<void> _continue() async {
    if (!_isValid) {
      setState(() => _error = 'Enter a valid 9-digit Cameroon mobile number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final phone = '+237${_controller.text.trim()}';
    try {
      final devCode = await AuthService.instance.requestOtp(phone);
      if (!mounted) return;
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(phone: phone, devCode: devCode, isGate: widget.isGate),
        ),
      );
      if (!mounted) return;
      if (widget.isGate && completed == true) {
        Navigator.of(context).pop(true);
      }
      // Non-gate mode: OtpVerifyScreen (or NameEntryScreen after it)
      // already navigated forward to Home on its own — nothing more to
      // do here.
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/onboarding/phone_entry_screen.dart: $e');
      setState(() => _error = 'Could not reach the server. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isGate
          ? AppBar(backgroundColor: AppColors.background, elevation: 0, scrolledUnderElevation: 0)
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
                        children: [
                          TextSpan(text: 'Welcome to ', style: TextStyle(color: AppColors.textPrimary)),
                          TextSpan(text: 'Hola', style: TextStyle(color: AppColors.textPrimary)),
                          TextSpan(text: 'Ride', style: TextStyle(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Log in or sign up with your phone number',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              if (widget.gateReason != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(widget.gateReason!,
                            style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                    const Text('Phone number',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.infoBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Text('🇨🇲', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 6),
                              Text('+237', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              hintText: '6 75 12 34 56',
                              counterText: '',
                            ),
                            onChanged: (_) => setState(() => _error = null),
                          ),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, size: 15, color: AppColors.danger),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    PrimaryButton(label: 'Continue', onPressed: _continue, loading: _loading),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  text: 'By continuing, you agree to our ',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: 'Terms and Privacy Policy.',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      recognizer: _termsRecognizer,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Text('Your data is safe with us',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}