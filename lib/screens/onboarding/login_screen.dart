import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import 'otp_verify_screen.dart';
import 'phone_entry_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isGate;
  const LoginScreen({super.key, this.isGate = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  bool _loading = false;
  String? _error;

  bool get _isValid {
    final d = _phoneCtrl.text.trim();
    return d.length == 9 && d.startsWith(RegExp(r'[6][0-9]'));
  }

  Future<void> _continue() async {
    final l = AppLocalizations.of(context);
    if (!_isValid) {
      setState(() => _error = l.loginErrorPhone);
      return;
    }
    setState(() { _loading = true; _error = null; });
    final phone = '+237${_phoneCtrl.text.trim()}';

    try {
      final exists = await AuthService.instance.checkPhoneExists(phone);

      if (!exists) {
        if (!mounted) return;
        setState(() => _loading = false);
        final l2 = AppLocalizations.of(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Text('👤', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Text(l2.loginNoAccountTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            ]),
            content: Text(
              l2.loginNoAccountBody,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l2.cancel,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => PhoneEntryScreen(isGate: widget.isGate)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l2.otpCreateAccount,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        return;
      }

      final devCode = await AuthService.instance.requestOtp(phone);
      if (!mounted) return;
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            phone: phone,
            devCode: devCode,
            isGate: widget.isGate,
            skipNameScreen: true,
          ),
        ),
      );
      if (!mounted) return;
      if (widget.isGate && completed == true) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).loginErrorServer);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // Split the localized title so the last word is highlighted in green
    // (e.g. "Welcome back" → "Welcome " + "back").
    final titleWords = l.loginTitle.trim().split(' ');
    final titleLast = titleWords.length > 1 ? titleWords.removeLast() : '';
    final titleFirst = titleWords.join(' ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                  color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Hero: badge + title + illustration ──────────
                SizedBox(
                  height: 218,
                  child: Stack(
                    children: [
                      // Illustration on the right — blurred, edges feathered
                      // so it melts into the background (no visible rectangle)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: FractionallySizedBox(
                            widthFactor: .70,
                            heightFactor: .88,
                            child: ShaderMask(
                              shaderCallback: (rect) => const RadialGradient(
                                center: Alignment(0.25, 0),
                                radius: 0.95,
                                colors: [Colors.white, Colors.white, Colors.transparent],
                                stops: [0, .62, 1],
                              ).createShader(rect),
                              blendMode: BlendMode.dstIn,
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
                                child: Image.asset(
                                  'assets/images/hero_road.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Soft fade so the text stays readable
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.background,
                                AppColors.background.withOpacity(.85),
                                AppColors.background.withOpacity(0),
                              ],
                              stops: const [0, .45, .85],
                            ),
                          ),
                        ),
                      ),
                      // Badge + title + subtitle
                      Positioned(
                        left: 0, top: 0,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.infoBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.directions_car_filled_outlined,
                                    size: 30, color: AppColors.primary),
                              ),
                              const SizedBox(height: 18),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 32, fontWeight: FontWeight.w800, height: 1.05),
                                  children: [
                                    TextSpan(
                                        text: titleLast.isEmpty ? l.loginTitle : '$titleFirst ',
                                        style: const TextStyle(color: AppColors.textPrimary)),
                                    if (titleLast.isNotEmpty)
                                      TextSpan(text: titleLast,
                                          style: const TextStyle(color: AppColors.primary)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(l.loginSubtitle,
                                  style: const TextStyle(
                                      fontSize: 14.5, color: AppColors.textSecondary, height: 1.35)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Phone card ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 16, offset: const Offset(0, 6))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.editProfilePhone,
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),

                      // Split field: 🇨🇲 +237 | 📞 input
                      Container(
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(.55), width: 1.2),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: const BoxDecoration(
                              color: AppColors.infoBg,
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(13)),
                            ),
                            child: const Row(children: [
                              Text('🇨🇲', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 6),
                              Text('+237',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
                            ]),
                          ),
                          Container(width: 1, color: AppColors.primary.withOpacity(.25)),
                          const SizedBox(width: 12),
                          Icon(Icons.phone_outlined, size: 18, color: AppColors.textSecondary.withOpacity(.7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _phoneCtrl,
                              focusNode: _phoneFocus,
                              keyboardType: TextInputType.phone,
                              maxLength: 9,
                              autofocus: true,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, letterSpacing: .5),
                              decoration: InputDecoration(
                                hintText: l.loginPhoneHint,
                                hintStyle: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w400),
                                counterText: '',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() => _error = null),
                              onSubmitted: (_) => _continue(),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ]),
                      ),

                      const SizedBox(height: 14),

                      // SMS note
                      Row(children: [
                        Container(
                          width: 30, height: 30,
                          decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                          child: const Icon(Icons.shield_outlined, size: 15, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text("We'll send you a verification code by SMS.",
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ),
                      ]),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.error_outline, size: 15, color: AppColors.danger),
                          const SizedBox(width: 6),
                          Expanded(child: Text(_error!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 12.5))),
                        ]),
                      ],

                      const SizedBox(height: 18),

                      // Continue button with arrow
                      Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(.3), blurRadius: 16, offset: const Offset(0, 6))
                          ],
                        ),
                        child: Material(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _loading ? null : _continue,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: _loading
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(l.loginSendCode,
                                            style: const TextStyle(
                                                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                                        const SizedBox(width: 10),
                                        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── New to HolaRide → Create an account ─────────
                Center(
                  child: Column(children: [
                    const Text('New to HolaRide?',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => PhoneEntryScreen(isGate: widget.isGate)),
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(l.otpCreateAccount,
                              style: const TextStyle(
                                  fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                        ]),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 18),

                // ── "or" divider ────────────────────────────────
                Row(children: [
                  Expanded(child: Divider(color: AppColors.border.withOpacity(.8))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('or', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider(color: AppColors.border.withOpacity(.8))),
                ]),

                const SizedBox(height: 18),

                // ── Need help? Contact support ──────────────────
                Center(
                  child: InkWell(
                    onTap: () {
                      // TODO: brancher sur WhatsApp / mail support quand décidé
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support: coming soon')),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 34, height: 34,
                          decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                          child: const Icon(Icons.headset_mic_outlined, size: 17, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        const Text('Need help? ',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        const Text('Contact support',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                      ]),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Secure login footer ─────────────────────────
                Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 34, height: 34,
                      decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                      child: const Icon(Icons.lock_outline, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    const Text('Secure login with SMS verification',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}