import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../services/document_service.dart';
import '../../theme/app_colors.dart';
import 'create_trip_screen.dart';
import 'vehicle_registration_screen.dart';

/// Screen 18 — Vehicle status ("My Vehicle").
///
/// Photos (public — passengers see them to recognise the car) vs
/// Documents (private legal papers, admin-only). Documents are
/// optional and never block approval.
///
/// Document flow is DEFERRED-SEND: picking a file only stages it
/// locally (preview + "replace"/"remove"); nothing is uploaded until
/// the driver taps that document's own Send button. This way a wrong
/// pick can be swapped before anything leaves the phone.
class VehicleStatusScreen extends StatefulWidget {
  const VehicleStatusScreen({super.key});

  @override
  State<VehicleStatusScreen> createState() => _VehicleStatusScreenState();
}

/// A file staged locally, not yet uploaded. On mobile we have a real
/// [path]; on web only [bytes] + [filename] (the browser gives no path).
class _StagedFile {
  final String? path;
  final List<int>? bytes;
  final String filename;
  final bool isPdf;
  _StagedFile({this.path, this.bytes, required this.filename, required this.isPdf});
}

class _VehicleStatusScreenState extends State<VehicleStatusScreen> {
  Vehicle? _vehicle;
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String? _uploadError;

  // Documents: what's already on the server, and what's staged locally.
  Map<DriverDocType, DriverDocument> _documents = {};
  final Map<DriverDocType, _StagedFile> _staged = {};
  DriverDocType? _sendingDoc;

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
      if (vehicle != null) _loadDocuments(vehicle.id);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/vehicle_status_screen.dart: $e');
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).vehicleStatusLoadError;
        _loading = false;
      });
    }
  }

  Future<void> _loadDocuments(String vehicleId) async {
    try {
      final docs = await DocumentService.instance.myDocuments(vehicleId);
      if (!mounted) return;
      setState(() => _documents = docs);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/vehicle_status_screen.dart (docs): $e');
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
      setState(() => _uploadError = AppLocalizations.of(context).vehicleStatusPhotoError);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Documents: pick (stage only) ────────────────────────────────

  Future<void> _pickDocument(DriverDocType type) async {
    if (_vehicle == null) return;

    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_docLabel(type),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(context).pop('camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(context).pop('gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            title: const Text('Upload a PDF'),
            onTap: () => Navigator.of(context).pop('pdf'),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
    if (source == null) return;

    String? path;
    List<int>? bytes;
    String filename = 'document';
    bool isPdf = false;
    try {
      if (source == 'pdf') {
        final res = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: kIsWeb, // web: load bytes (no path available)
        );
        if (res == null) return;
        final f = res.files.single;
        filename = f.name;
        isPdf = true;
        if (kIsWeb) {
          bytes = f.bytes;
        } else {
          path = f.path;
        }
      } else {
        final picker = ImagePicker();
        final img = await picker.pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 85,
        );
        if (img == null) return;
        filename = img.name;
        if (kIsWeb) {
          bytes = await img.readAsBytes();
        } else {
          path = img.path;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error picking document: $e');
      return;
    }
    if (path == null && bytes == null) return;

    // Stage locally — NOT uploaded yet.
    setState(() => _staged[type] =
        _StagedFile(path: path, bytes: bytes, filename: filename, isPdf: isPdf));
  }

  // ── Documents: send (upload the staged file) ────────────────────

  Future<void> _sendDocument(DriverDocType type) async {
    final staged = _staged[type];
    if (staged == null || _vehicle == null) return;

    setState(() => _sendingDoc = type);
    try {
      await DocumentService.instance.upload(
        vehicleId: _vehicle!.id,
        type: type,
        filePath: staged.path,
        bytes: staged.bytes,
        filename: staged.filename,
      );
      if (!mounted) return;
      setState(() => _staged.remove(type)); // clear the staged copy
      await _loadDocuments(_vehicle!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_docLabel(type)} sent.')),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error uploading document: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send the document. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _sendingDoc = null);
    }
  }

  String _docLabel(DriverDocType t) {
    switch (t) {
      case DriverDocType.driverLicence:
        return 'Driver licence';
      case DriverDocType.idCard:
        return 'ID card (CNI)';
      case DriverDocType.registration:
        return 'Vehicle registration (carte grise)';
      case DriverDocType.insurance:
        return 'Insurance';
    }
  }

  IconData _docIcon(DriverDocType t) {
    switch (t) {
      case DriverDocType.driverLicence:
        return Icons.badge_outlined;
      case DriverDocType.idCard:
        return Icons.contact_page_outlined;
      case DriverDocType.registration:
        return Icons.description_outlined;
      case DriverDocType.insurance:
        return Icons.verified_user_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l.profileMyVehicle)),
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
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(l.vehicleStatusNoVehicle,
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VehicleRegistrationScreen()),
              ),
              child: Text(l.vehicleStatusAdd),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicle(Vehicle v) {
    final l = AppLocalizations.of(context);
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
                      Text(
                          '${v.plateNumber} · ${v.totalSeats > 1 ? l.bookingsSeatPlural(v.totalSeats) : l.bookingsSeatSingular(v.totalSeats)}',
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

          // ── Photos ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.vehicleStatusPhotos, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              TextButton.icon(
                onPressed: _uploading ? null : _addPhotos,
                icon: _uploading
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(_uploading ? l.vehicleStatusUploading : l.vehicleStatusAddPhotos),
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
              child: Center(
                child: Text(l.vehicleStatusNoPhotos,
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
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

          const SizedBox(height: 24),

          // ── Documents ──────────────────────────────────────────
          const Text('Documents',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          const Text('Optional — helps us verify you faster. Only our team can see these.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          ...DriverDocType.values.map((type) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _documentSlot(type),
              )),

          if (v.status == VehicleStatus.approved) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateTripScreen()),
              ),
              child: Text(l.vehicleStatusFirstTrip),
            ),
          ],
        ],
      ),
    );
  }

  Widget _documentSlot(DriverDocType type) {
    final doc = _documents[type];
    final staged = _staged[type];
    final sending = _sendingDoc == type;
    final hasDoc = doc != null;

    // ── Staged (picked but not sent yet) ──────────────────────────
    if (staged != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(.4)),
        ),
        child: Column(children: [
          Row(children: [
            // Preview thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (staged.isPdf || kIsWeb)
                  // Image.file isn't supported on Flutter Web, and a PDF
                  // has no image preview — show a typed placeholder in
                  // both cases. On mobile, real images preview normally.
                  ? Container(
                      width: 46, height: 46,
                      color: staged.isPdf ? AppColors.dangerBg : AppColors.infoBg,
                      child: Icon(
                        staged.isPdf ? Icons.picture_as_pdf : Icons.image,
                        color: staged.isPdf ? AppColors.danger : AppColors.primary,
                        size: 22,
                      ),
                    )
                  : Image.file(File(staged.path!), width: 46, height: 46, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_docLabel(type),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(staged.isPdf ? 'PDF ready to send' : 'Image ready to send',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
            // Remove staged file
            if (!sending)
              IconButton(
                onPressed: () => setState(() => _staged.remove(type)),
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                tooltip: 'Remove',
              ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            // Replace
            Expanded(
              child: OutlinedButton.icon(
                onPressed: sending ? null : () => _pickDocument(type),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Change'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send
            Expanded(
              child: FilledButton.icon(
                onPressed: sending ? null : () => _sendDocument(type),
                icon: sending
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 16),
                label: Text(sending ? 'Sending...' : 'Send'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ]),
      );
    }

    // ── Sent (on the server) or empty ─────────────────────────────
    Color chipBg = AppColors.infoBg;
    Color chipFg = AppColors.primary;
    String chipText = 'Add';
    IconData chipIcon = Icons.add;
    if (hasDoc) {
      switch (doc.status) {
        case 'approved':
          chipBg = AppColors.successBg;
          chipFg = AppColors.success;
          chipText = 'Approved';
          chipIcon = Icons.check_circle_outline;
          break;
        case 'rejected':
          chipBg = AppColors.dangerBg;
          chipFg = AppColors.danger;
          chipText = 'Rejected';
          chipIcon = Icons.error_outline;
          break;
        default:
          chipBg = AppColors.warningBg;
          chipFg = AppColors.warning;
          chipText = 'In review';
          chipIcon = Icons.access_time;
      }
    }

    return InkWell(
      onTap: () => _pickDocument(type),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasDoc ? chipFg.withOpacity(.3) : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: hasDoc ? chipBg : AppColors.infoBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasDoc
                    ? (doc.fileType == 'pdf' ? Icons.picture_as_pdf_outlined : Icons.image_outlined)
                    : _docIcon(type),
                color: hasDoc ? chipFg : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_docLabel(type),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(
                    hasDoc
                        ? '${doc.fileType == 'pdf' ? 'PDF' : 'Image'} · tap to replace'
                        : 'Photo or PDF',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(chipIcon, size: 13, color: chipFg),
                const SizedBox(width: 4),
                Text(chipText,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: chipFg)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner(Vehicle v) {
    final l = AppLocalizations.of(context);
    final Color bg;
    final Color fg;
    final String message;
    switch (v.status) {
      case VehicleStatus.pending:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        message = l.vehicleStatusPending;
        break;
      case VehicleStatus.approved:
        bg = AppColors.successBg;
        fg = AppColors.success;
        message = l.vehicleStatusApproved;
        break;
      case VehicleStatus.rejected:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
        message = l.vehicleStatusRejected;
        break;
      case VehicleStatus.unknown:
        bg = AppColors.surfaceMuted;
        fg = AppColors.textSecondary;
        message = l.vehicleStatusUnavailable;
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
                Text(l.vehicleStatusStatusLabel, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
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