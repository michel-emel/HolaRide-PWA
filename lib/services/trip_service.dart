import '../models/trip.dart';
import 'api_client.dart';

/// Wraps trip search and detail lookups. The home screen and the search
/// results screen both go through [search] — home just calls it with no
/// route filters and a small [limit] to show "available trips near you".
class TripService {
  TripService._();
  static final TripService instance = TripService._();

  final _api = ApiClient.instance;

  /// Confirmed query params: `origin_city`, `destination_city`,
  /// `departure_date`, `limit`. There's no `passengers` filter on the
  /// real endpoint — the search form still collects a passenger count
  /// for the person's own planning, it just isn't sent to the backend.
  Future<List<Trip>> search({
    String? originCity,
    String? destinationCity,
    DateTime? departureDate,
    int? limit,
  }) async {
    final query = <String, dynamic>{
      if (originCity != null && originCity.isNotEmpty) 'origin_city': originCity,
      if (destinationCity != null && destinationCity.isNotEmpty) 'destination_city': destinationCity,
      if (departureDate != null) 'departure_date': _dateOnly(departureDate),
      if (limit != null) 'limit': limit,
    };
    final res = await _api.get('/trips/search', query: query, auth: false);
    final list = (res as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map((e) => Trip.fromJson(e)).toList();
  }

  Future<Trip> getById(String id) async {
    final res = await _api.get('/trips/$id', auth: false);
    return Trip.fromJson(res as Map<String, dynamic>);
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}