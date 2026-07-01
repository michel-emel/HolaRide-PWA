/// A single participant's last-known position on a trip, from the
/// real `GET /trips/{trip_id}/locations` endpoint — added to the
/// backend specifically to make location sharing genuinely
/// bidirectional. Covers the driver AND any paid passenger who's
/// shared a position, not just the driver.
class ParticipantLocation {
  final String userId;

  /// "driver" or "passenger" — set server-side by comparing against
  /// the trip's own driver_id, not something the client decides.
  final String role;
  final String? firstName;
  final String? lastName;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  ParticipantLocation({
    required this.userId,
    required this.role,
    this.firstName,
    this.lastName,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  bool get isDriver => role == 'driver';

  String get displayName {
    final name = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    if (name.isNotEmpty) return name;
    return isDriver ? 'Driver' : 'Passenger';
  }

  factory ParticipantLocation.fromJson(Map<String, dynamic> json) {
    return ParticipantLocation(
      userId: json['user_id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'passenger',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}