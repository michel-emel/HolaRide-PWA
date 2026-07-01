import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;

/// Fetches a real, road-following route between two points using
/// OSRM's free public demo routing server — no API key, no account
/// setup, no billing needed, same philosophy as the free OpenStreetMap
/// tiles already used for the map itself.
///
/// NOTE: this is OSRM's shared public DEMO server
/// (router.project-osrm.org), meant for evaluation/testing — fine for
/// development and an early launch, but it has fair-use rate limits
/// and no uptime guarantee. If real usage grows, either self-host
/// OSRM or switch to a paid provider (Mapbox Directions, Google
/// Directions) — both need their own API key/account, which can't be
/// set up on your behalf.
class RouteService {
  RouteService._();
  static final RouteService instance = RouteService._();

  /// Returns the route's points in order, or null if anything goes
  /// wrong (offline, rate-limited, demo server unavailable) — callers
  /// should fall back to drawing a plain straight line in that case,
  /// rather than showing nothing or crashing.
  Future<List<ll.LatLng>?> fetchRoute(ll.LatLng from, ll.LatLng to) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final geometry = routes.first['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;
      // GeoJSON order is [longitude, latitude] — easy to get backwards.
      return coordinates.map((c) {
        final pair = c as List;
        return ll.LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
      }).toList();
    } catch (_) {
      return null;
    }
  }
}