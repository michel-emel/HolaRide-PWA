import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import 'otp_verify_screen.dart';
import 'login_screen.dart';
import '../profile/terms_privacy_screen.dart';

class PhoneEntryScreen extends StatefulWidget {
  final bool isGate;
  final String? gateReason;
  const PhoneEntryScreen({super.key, this.isGate = false, this.gateReason});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _phoneController     = TextEditingController();
  final _termsRecognizer     = TapGestureRecognizer();
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
    final d = _phoneController.text.trim();
    return _firstNameController.text.trim().isNotEmpty &&
        d.length == 9 &&
        d.startsWith(RegExp(r'[6][0-9]'));
  }

  Future<void> _continue() async {
    final l = AppLocalizations.of(context);
    final firstName = _firstNameController.text.trim();
    final lastName  = _lastNameController.text.trim();
    final digits    = _phoneController.text.trim();

    if (firstName.isEmpty) {
      setState(() => _error = l.registerErrorFirstName);
      return;
    }
    if (digits.length != 9 || !digits.startsWith(RegExp(r'[6][0-9]'))) {
      setState(() => _error = l.registerErrorPhone);
      return;
    }

    setState(() { _loading = true; _error = null; });
    final phone = '+237$digits';

    try {
      final exists = await AuthService.instance.checkPhoneExists(phone);
      if (exists) {
        if (!mounted) return;
        setState(() => _loading = false);
        _showAccountExistsDialog(phone);
        return;
      }

      final devCode = await AuthService.instance.requestOtp(
        phone,
        firstName: firstName,
        lastName: lastName.isEmpty ? null : lastName,
      );
      if (!mounted) return;
      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            phone: phone,
            devCode: devCode,
            isGate: widget.isGate,
          ),
        ),
      );
      if (!mounted) return;
      if (widget.isGate && completed == true) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).registerErrorServer);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAccountExistsDialog(String phone) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('✅', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Text(l.registerAccountExistsTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        ]),
        content: Text(
          l.registerAccountExistsBody,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginScreen(isGate: widget.isGate)),
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // Split the localized title so the trailing word(s) are green
    // (e.g. "Create your account" → "Create your " + "account").
    final titleWords = l.registerTitle.trim().split(' ');
    final titleLast = titleWords.length > 1 ? titleWords.removeLast() : '';
    final titleFirst = titleWords.join(' ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isGate
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              scrolledUnderElevation: 0,
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
            )
          : null,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Hero: badge + title + illustration ──────────
                SizedBox(
                  height: 208,
                  child: Stack(
                    children: [
                      // Illustration on the right — softly blurred, feathered edges
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
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.infoBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_add_alt_1_outlined,
                                    size: 28, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 30, fontWeight: FontWeight.w800, height: 1.05),
                                  children: [
                                    TextSpan(
                                        text: titleLast.isEmpty ? l.registerTitle : '$titleFirst ',
                                        style: const TextStyle(color: AppColors.textPrimary)),
                                    if (titleLast.isNotEmpty)
                                      TextSpan(text: titleLast,
                                          style: const TextStyle(color: AppColors.primary)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(l.registerSubtitle,
                                  style: const TextStyle(
                                      fontSize: 14, color: AppColors.textSecondary, height: 1.35)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                if (widget.gateReason != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.gateReason!,
                          style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600))),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],

                // ── Form card ───────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // First name
                      _FieldLabel(icon: Icons.person_outline, text: l.registerFirstName),
                      const SizedBox(height: 8),
                      _FilledInput(
                        controller: _firstNameController,
                        hint: l.registerFirstNameHint,
                        icon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() => _error = null),
                      ),

                      const SizedBox(height: 18),

                      // Last name (optional)
                      Row(children: [
                        _FieldLabel(icon: Icons.person_outline, text: l.registerLastName),
                        const SizedBox(width: 6),
                        Text(l.optional,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: 8),
                      _FilledInput(
                        controller: _lastNameController,
                        hint: l.registerLastNameHint,
                        icon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 18),

                      // Phone number
                      _FieldLabel(icon: Icons.phone_outlined, text: l.registerPhoneNumber),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                              color: AppColors.infoBg, borderRadius: BorderRadius.circular(14)),
                          child: const Row(children: [
                            Text('🇨🇲', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text('+237',
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
                          ]),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilledInput(
                            controller: _phoneController,
                            hint: l.loginPhoneHint,
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (_) => setState(() => _error = null),
                            onSubmitted: (_) => _continue(),
                          ),
                        ),
                      ]),

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
                                        Text(l.registerContinue,
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

                const SizedBox(height: 16),

                // ── Terms ───────────────────────────────────────
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: l.registerTermsPrefix,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: l.registerTermsLink,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          recognizer: _termsRecognizer,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                // ── "or" divider ────────────────────────────────
                Row(children: [
                  Expanded(child: Divider(color: AppColors.border.withOpacity(.8))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('or', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider(color: AppColors.border.withOpacity(.8))),
                ]),

                const SizedBox(height: 16),

                // ── Already have an account? Sign in ────────────
                Center(
                  child: InkWell(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => LoginScreen(isGate: widget.isGate)),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(l.registerAlreadyHaveAccount,
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        Text(l.welcomeSignIn,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                      ]),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Data safety banner ──────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg.withOpacity(.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: const Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.yourDataSafe,
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        const Text('We never share your information with third parties.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ),
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

// ── Field label with icon ────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FieldLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(text,
          style: const TextStyle(
              fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
    ]);
  }
}

// ── Filled input (soft grey box with leading icon, like the mockup) ─────
class _FilledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _FilledInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(.6)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textSecondary.withOpacity(.7)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w400),
              counterText: '',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        ),
      ]),
    );
  }
}