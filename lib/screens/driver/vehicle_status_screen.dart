import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../theme/app_colors.dart';
import 'create_trip_screen.dart';
import 'vehicle_registration_screen.dart';

/// Screen 18 — Vehicle status ("My Vehicle").
///
/// There's no approval timeline here on purpose. The real
/// `VehicleOut` schema only has a `verification_status` field — no
/// submitted/reviewed timestamps and no rejection reason — so a
/// step-by-step timeline with dates would just be made-up data.
/// This shows the one status that's actually real.
///
/// Photos use the real `POST /drivers/me/vehicle/{id}/photos`
/// multipart endpoint — confirmed against the actual `Vehicle` model,
/// which does have a `photo_urls` column, correcting an earlier wrong
/// assumption elsewhere in this app that no photo field existed at
/// all. Uploading is optional and can happen anytime, including
/// after approval — admin isn't required to wait on photos to approve
/// a vehicle, this is just supporting documentation/visual reference.
class VehicleStatusScreen extends StatefulWidget {
  const VehicleStatusScreen({super.key});

  @override
  State<VehicleStatusScreen> createState() => _VehicleStatusScreenState();
}

class _VehicleStatusScreenState extends State<VehicleStatusScreen> {
  Vehicle? _vehicle;
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final vehicle = await VehicleService.instance.getMyVehicle();
      if (!mounted) return;
      setState(() {
        _vehicle = vehicle;
        _loading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/vehicle_status_screen.dart: $e');
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load your vehicle status.";
        _loading = false;
      });
    }
  }

  Future<void> _addPhotos() async {
    if (_vehicle == null) return;
    final picker = ImagePicker();
    List<XFile> picked;
    try {
      picked = await picker.pickMultiImage(imageQuality: 85);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/vehicle_status_screen.dart: $e');
      return;
    }
    if (picked.isEmpty) return;
    setState(() {
      _uploading = true;
      _uploadError = null;
    });
    try {
      await VehicleService.instance.uploadPhotos(_vehicle!.id, picked.map((f) => f.path).toList());
      await _load();
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/vehicle_status_screen.dart: $e');
      if (!mounted) return;
      setState(() => _uploadError = "Some photos didn't upload. Try again.");
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('My Vehicle')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
              : _vehicle == null
                  ? _buildNoVehicle()
                  : _buildVehicle(_vehicle!),
    );
  }

  Widget _buildNoVehicle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text("You haven't added a vehicle yet.",
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VehicleRegistrationScreen()),
              ),
              child: const Text('Add your vehicle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicle(Vehicle v) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  child: const Icon(Icons.directions_car, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.makeModel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('${v.plateNumber} · ${v.totalSeats} seats',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _statusBanner(v),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Photos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              TextButton.icon(
                onPressed: _uploading ? null : _addPhotos,
                icon: _uploading
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(_uploading ? 'Uploading...' : 'Add Photos'),
              ),
            ],
          ),
          if (_uploadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_uploadError!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
            ),
          if (v.photoUrls.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('No photos yet — add a few so passengers recognize your car.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ),
            )
          else
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: v.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    v.photoUrls[i],
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      color: AppColors.infoBg,
                      child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          if (v.status == VehicleStatus.approved) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateTripScreen()),
              ),
              child: const Text('Create your first trip'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBanner(Vehicle v) {
    final Color bg;
    final Color fg;
    final String message;
    switch (v.status) {
      case VehicleStatus.pending:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        message = "We are verifying your documents and vehicle. You'll be notified once it's approved.";
        break;
      case VehicleStatus.approved:
        bg = AppColors.successBg;
        fg = AppColors.success;
        message = 'Your vehicle is approved — you can publish trips now.';
        break;
      case VehicleStatus.rejected:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        message = 'Your submission was rejected. Contact support for details, or submit a new vehicle.';
        break;
      case VehicleStatus.unknown:
        bg = AppColors.surfaceMuted;
        fg = AppColors.textSecondary;
        message = 'Status unavailable right now.';
        break;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            v.status == VehicleStatus.approved
                ? Icons.check_circle
                : v.status == VehicleStatus.rejected
                    ? Icons.error_outline
                    : Icons.access_time,
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
                Text(v.status.label, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: fg, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
