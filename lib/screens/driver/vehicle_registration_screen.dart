import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_client.dart';
import '../../services/session_service.dart';
import '../../services/vehicle_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'vehicle_status_screen.dart';

/// Screen 17 — Vehicle registration ("Add your vehicle").
///
/// This is what unlocks driving on the account — submitting here puts
/// the vehicle into `pending` review, not `approved`. Nothing about
/// pricing lives here; that's entirely admin-controlled once approved.
///
/// The moment submission succeeds, the app switches into "driver
/// mode" (see `SessionService.setDriverMode`) even though the vehicle
/// itself is still pending — that's a deliberate choice: someone
/// submitting this form is clearly trying to be a driver right now,
/// not waiting for admin approval to start seeing driver-oriented
/// screens. Mode switching never changes what the backend actually
/// permits; "Become a Driver" in Profile just won't show again once
/// any vehicle exists, replaced by a "Switch to Driver/Passenger"
/// toggle instead.
///
/// There's no photo upload on THIS screen specifically — your real
/// `VehicleCreate` schema (confirmed from its OpenAPI spec) takes
/// plain JSON, and `POST /drivers/me/vehicle` isn't a file-upload
/// endpoint, so a vehicle has to exist before there's a `vehicle_id`
/// to attach photos to. Photos are added on the next screen instead
/// (Vehicle Status / "My Vehicle"), via the real
/// `POST /drivers/me/vehicle/{vehicle_id}/photos` multipart endpoint —
/// confirmed against the actual `Vehicle` model, which does have a
/// `photo_urls` column.
class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() => _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();
  int _totalSeats = 4;
  bool _submitting = false;
  String? _error;

  bool get _isValid =>
      _brandController.text.trim().isNotEmpty &&
      _modelController.text.trim().isNotEmpty &&
      _plateController.text.trim().isNotEmpty &&
      _totalSeats > 0;

  Future<void> _submit() async {
    if (!_isValid) {
      setState(() => _error = 'Fill in brand, model, plate number, and seats.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await VehicleService.instance.submitVehicle(
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: _yearController.text.trim().isEmpty ? null : int.tryParse(_yearController.text.trim()),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        plateNumber: _plateController.text.trim(),
        totalSeats: _totalSeats,
      );
      if (!mounted) return;
      // Switch into driver mode right away — see the class doc above
      // for why this happens at submission, not at approval.
      await SessionService.instance.setDriverMode(true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VehicleStatusScreen()),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e, stack) {
      // ignore: avoid_print
      print('Vehicle submission failed (non-API error): $e\n$stack');
      setState(() => _error = 'Could not submit your vehicle. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add your vehicle'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                child: const Icon(Icons.directions_car, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tell us about your car — this is what gets reviewed before you can publish trips.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vehicle details',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _field('Brand', _brandController, hint: 'e.g. Toyota')),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Model', _modelController, hint: 'e.g. Corolla')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field('Year (optional)', _yearController,
                          hint: 'e.g. 2018', keyboardType: TextInputType.number, maxLength: 4),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Color (optional)', _colorController, hint: 'e.g. Silver')),
                  ],
                ),
                const SizedBox(height: 12),
                _field('License plate', _plateController, hint: 'e.g. CMR-123-AA'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.event_seat_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Total seats', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        onPressed: _totalSeats > 1 ? () => setState(() => _totalSeats--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_totalSeats', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      IconButton(
                        onPressed: _totalSeats < 30 ? () => setState(() => _totalSeats++) : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, size: 15, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5))),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                PrimaryButton(label: 'Submit for Review', onPressed: _submit, loading: _submitting),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(hintText: hint, counterText: '', filled: true, fillColor: AppColors.infoBg),
        ),
      ],
    );
  }
}
