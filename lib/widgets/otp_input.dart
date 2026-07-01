import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Six individual digit boxes that auto-advance focus as the person
/// types, and auto-fire [onCompleted] the moment all six are filled.
///
/// Each box fills its share of available width via [Expanded] — no
/// fixed or clamped box width — so the row always uses the full space
/// it's given, with no leftover margins on phones. The whole group is
/// wrapped in a max-width constraint so it doesn't grow oversized on
/// tablets; on phones that constraint never actually binds.
///
/// Exposes [clear] and [shake] so the parent screen can reset the
/// fields (on resend) or give clear visual feedback on a wrong code
/// (on verification failure) via a GlobalKey<OtpInputState>.
class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  const OtpInput({super.key, this.length = 6, required this.onCompleted});

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> with SingleTickerProviderStateMixin {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _nodes;
  late AnimationController _shakeController;
  bool _hasError = false;

  static const double _gap = 10;
  static const double _boxHeight = 60;
  static const double _maxGroupWidth = 380;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (_hasError) setState(() => _hasError = false);
    if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      HapticFeedback.lightImpact();
      _nodes[index].unfocus();
      widget.onCompleted(code);
    }
  }

  /// Clears every box and resets error styling — used when the person
  /// edits the phone number, a fresh code is sent, or after a failed
  /// verification attempt finishes its shake animation.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (_hasError) setState(() => _hasError = false);
    _nodes.first.requestFocus();
  }

  /// Shakes the boxes and flashes them red — call this right after a
  /// failed verification so the person gets an immediate, unmistakable
  /// signal that the code was wrong, then the boxes auto-clear for
  /// them to retry.
  void shake() {
    setState(() => _hasError = true);
    HapticFeedback.mediumImpact();
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 420), clear);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final dx = sin(t * pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxGroupWidth),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: List.generate(widget.length, (i) {
                final isLast = i == widget.length - 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : _gap),
                    child: SizedBox(
                      height: _boxHeight,
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _nodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        cursorColor: AppColors.primary,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _hasError ? AppColors.danger : AppColors.textPrimary,
                        ),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          filled: true,
                          fillColor: _hasError
                              ? AppColors.danger.withOpacity(0.07)
                              : AppColors.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _hasError ? AppColors.danger : Colors.transparent,
                              width: 1.4,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _hasError ? AppColors.danger : Colors.transparent,
                              width: 1.4,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _hasError ? AppColors.danger : AppColors.primary,
                              width: 1.8,
                            ),
                          ),
                        ),
                        onChanged: (v) => _onChanged(i, v),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}