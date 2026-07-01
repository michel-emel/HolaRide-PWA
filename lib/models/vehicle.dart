/// Where a driver's vehicle sits in the admin approval pipeline.
/// Driving stays locked on the account until this reaches [approved].
///
/// Confirmed against your backend's real `VehicleOut` schema — the
/// field is `verification_status`, not `status`. There's still no
/// submitted/reviewed timestamp and no rejection reason tracked, so
/// this app doesn't pretend to show those. `photo_urls` DOES exist
/// though — confirmed directly against the real `Vehicle` SQLAlchemy
/// model (`photo_urls = Column(ARRAY(Text), ...)`), correcting an
/// earlier wrong assumption that there was no photo field at all.
enum VehicleStatus {
  pending,
  approved,
  rejected,
  unknown;

  static VehicleStatus fromApi(String? raw) {
    switch (raw) {
      case 'pending':
      case 'under_review':
        return VehicleStatus.pending;
      case 'approved':
      case 'verified':
        return VehicleStatus.approved;
      case 'rejected':
        return VehicleStatus.rejected;
      default:
        return VehicleStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case VehicleStatus.pending:
        return 'Under Review';
      case VehicleStatus.approved:
        return 'Approved';
      case VehicleStatus.rejected:
        return 'Rejected';
      case VehicleStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Matches your backend's real `VehicleOut` schema: id, driver_id,
/// brand, model, plate_number, total_seats, verification_status,
/// vehicle_category_id, photo_urls.
class Vehicle {
  final String id;
  final String driverId;
  final String brand;
  final String model;
  final String plateNumber;
  final int totalSeats;
  final VehicleStatus status;
  final String? vehicleCategoryId;
  final List<String> photoUrls;

  Vehicle({
    required this.id,
    required this.driverId,
    required this.brand,
    required this.model,
    required this.plateNumber,
    required this.totalSeats,
    required this.status,
    this.vehicleCategoryId,
    this.photoUrls = const [],
  });

  String get makeModel => '$brand $model';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      plateNumber: json['plate_number']?.toString() ?? '',
      totalSeats: (json['total_seats'] as num?)?.toInt() ?? 0,
      status: VehicleStatus.fromApi(json['verification_status']?.toString()),
      vehicleCategoryId: json['vehicle_category_id']?.toString(),
      photoUrls: (json['photo_urls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
