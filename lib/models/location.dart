/// A single result from `GET /locations/search?q=`.
///
/// Matches the real `LocationSearchResult` schema exactly: a specific
/// pickup/drop-off point (`id`, `name`) plus the city it belongs to
/// (`cityId`, `cityName`). The point's own `id` is what trip creation
/// actually needs (`departure_location_id`/`destination_location_id`);
/// `cityName` alone is what trip *search* filters by — the backend
/// matches routes at the city level, not the specific point.
class LocationResult {
  final String id;
  final String name;
  final String cityId;
  final String cityName;

  LocationResult({
    required this.id,
    required this.name,
    required this.cityId,
    required this.cityName,
  });

  /// "(City, Point)" display, e.g. "Yaoundé, Emana" — or just the city
  /// name alone when there's no specific point (e.g. a city-only
  /// shortcut from Home's popular routes).
  String get label => name.isEmpty ? cityName : '$cityName, $name';

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      cityId: json['city_id']?.toString() ?? '',
      cityName: json['city_name']?.toString() ?? '',
    );
  }
}
