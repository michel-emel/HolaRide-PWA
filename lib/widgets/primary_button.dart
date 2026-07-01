import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A full-width primary button that shows a spinner instead of its label
/// while [loading] is true, and disables itself automatically — every
/// screen with an async action (OTP verify, search, pay...) uses this
/// instead of rolling its own loading logic per button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: backgroundColor == null
          ? null
          : ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor ?? Colors.white,
              minimumSize: const Size.fromHeight(52),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Text(label),
    );
  }
}

/// The CTA button used on the splash/onboarding hero screens.
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const GoldButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnDark,
    );
  }
}