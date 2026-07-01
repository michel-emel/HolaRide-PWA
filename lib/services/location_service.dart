import '../models/location.dart';
import 'api_client.dart';

/// Wraps `GET /locations/search?q=` — the person can type either a city
/// or a pickup point name, and results always come back as (city, point)
/// pairs so the UI never has to special-case which one they typed.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  final _api = ApiClient.instance;

  Future<List<LocationResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await _api.get('/locations/search', query: {'q': query}, auth: false);
    final list = (res as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => LocationResult.fromJson(e))
        .toList();
  }
}
