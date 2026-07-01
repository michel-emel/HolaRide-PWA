import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Six individual digit boxes that auto-advance focus as the person
/// types, and auto-fire [onCompleted] the moment all six are filled —
/// matches the "Enter the code we sent you" screen in the mockup.
class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final String? initialCode;

  const OtpInput({super.key, this.length = 6, required this.onCompleted, this.initialCode});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());

    final code = widget.initialCode;
    if (code != null && code.length == widget.length) {
      for (int i = 0; i < widget.length; i++) {
        _controllers[i].text = code[i];
      }
      // Setting .text programmatically doesn't fire TextField's onChanged,
      // so the normal auto-complete path never runs on its own here —
      // fire it once, after the first frame, same as if the person had
      // typed it themselves.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCompleted(code);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  /// Clears every box — used when the person edits the phone number
  /// and a fresh code is sent, or after a failed verification attempt.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _nodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.length, (i) {
          return SizedBox(
            width: 46,
            height: 56,
            child: TextField(
              controller: _controllers[i],
              focusNode: _nodes[i],
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.infoBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                ),
              ),
              onChanged: (v) => _onChanged(i, v),
            ),
          );
        }),
      ),
    );
  }
}