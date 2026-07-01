import '../models/vehicle.dart';
import 'api_client.dart';

/// Wraps vehicle submission and approval-status lookup — this is what
/// unlocks driving on an account. No price-setting lives here; that's
/// admin-controlled and happens server-side once a vehicle is approved.
///
/// Confirmed against your backend's real OpenAPI schema:
/// `POST /drivers/me/vehicle` takes a plain JSON body (matching
/// `VehicleCreate` — brand, model, year, color, plate_number,
/// total_seats) and returns the created vehicle directly as JSON.
/// It is NOT a multipart/file-upload endpoint — there's no photo field
/// in the schema at all, so vehicle photos aren't submitted here.
/// `GET /drivers/me/vehicles` (still a guess on exact response shape,
/// though the plural path is confirmed) is used for status checks.
class VehicleService {
  VehicleService._();
  static final VehicleService instance = VehicleService._();

  final _api = ApiClient.instance;

  /// Returns null if the person has never submitted a vehicle yet.
  Future<Vehicle?> getMyVehicle() async {
    try {
      final res = await _api.get('/drivers/me/vehicles');
      final list = (res as List?) ?? const [];
      if (list.isEmpty) return null;
      final vehicles = list.whereType<Map<String, dynamic>>().map(Vehicle.fromJson).toList();
      return vehicles.isEmpty ? null : vehicles.first;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Confirmed: `POST /drivers/me/vehicle`, plain JSON body matching
  /// `VehicleCreate`. `brand`, `model`, `plate_number`, and
  /// `totalSeats` are required; `year` and `color` are optional.
  Future<Vehicle> submitVehicle({
    required String brand,
    required String model,
    int? year,
    String? color,
    required String plateNumber,
    required int totalSeats,
  }) async {
    final res = await _api.post('/drivers/me/vehicle', body: {
      'brand': brand,
      'model': model,
      if (year != null) 'year': year,
      if (color != null && color.isNotEmpty) 'color': color,
      'plate_number': plateNumber,
      'total_seats': totalSeats,
    });
    return Vehicle.fromJson(res as Map<String, dynamic>);
  }

  /// `POST /drivers/me/vehicle/{vehicle_id}/photos`, multipart. Field
  /// name is assumed to be `photos` (plural, matching the endpoint
  /// path and the `photo_urls` column it fills) — `ApiClient.postMultipart`
  /// already supports multiple files under one repeated field name for
  /// exactly this reason. Uploads one at a time so a single failed
  /// file doesn't lose progress on the others already sent.
  Future<void> uploadPhotos(String vehicleId, List<String> filePaths) async {
    for (final path in filePaths) {
      await _api.postMultipart(
        '/drivers/me/vehicle/$vehicleId/photos',
        files: [MapEntry('photos', path)],
      );
    }
  }
}
