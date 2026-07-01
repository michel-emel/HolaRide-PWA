import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../widgets/primary_button.dart';
import '../main_tab_screen.dart';

/// Screen 4 — Name entry (first-time signup only).
///
/// See `phone_entry_screen.dart` for what `isGate` means.
class NameEntryScreen extends StatefulWidget {
  final bool isGate;
  const NameEntryScreen({super.key, this.isGate = false});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _continue() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Tell us what to call you.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final parts = name.split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    try {
      await AuthService.instance.completeProfile(firstName: firstName, lastName: lastName);
      if (!mounted) return;
      if (widget.isGate) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainTabScreen()),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/onboarding/name_entry_screen.dart: $e');
      setState(() => _error = 'Could not save your name. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, size: 36, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 22),
              const Text('What should\nwe call you?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 10),
              const Text(
                'This will be visible on your profile',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 26),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(hintText: 'e.g. Michel Kamga'),
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 22),
              PrimaryButton(label: 'Continue', onPressed: _continue, loading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}