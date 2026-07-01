import '../models/participant_location.dart';
import 'api_client.dart';

/// Live GPS sharing for a trip in progress.
///
/// Confirmed against the real backend source: `POST /trips/{trip_id}/
/// location` already accepted ANY participant (the driver or any paid
/// passenger) pushing their own position, keyed by their own user id —
/// that part was already correctly bidirectional. The actual gap was
/// on the read side, which only ever exposed the driver's position.
/// `GET /trips/{trip_id}/locations` (plural) was added to the backend
/// specifically to fix that — it returns every participant's
/// last-known position, so sharing is genuinely two-way (or more,
/// with multiple passengers) rather than "driver shares, one
/// passenger reads."
class LiveLocationService {
  LiveLocationService._();
  static final LiveLocationService instance = LiveLocationService._();

  final _api = ApiClient.instance;

  Future<void> pushLocation(String tripId, double latitude, double longitude) async {
    await _api.post('/trips/$tripId/location', body: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<List<ParticipantLocation>> getParticipants(String tripId) async {
    final res = await _api.get('/trips/$tripId/locations');
    final list = (res as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map((e) => ParticipantLocation.fromJson(e)).toList();
  }
}