/// A published trip a passenger can search and book seats on.
///
/// Rewritten to match your backend's real `TripOut` schema exactly
/// (confirmed via OpenAPI). Earlier versions of this model guessed at
/// fields — driver info (name/rating/photo), vehicle make/model/color/
/// plate, amenities, a trip note, arrival time, duration — none of
/// which actually exist on the backend. If a field isn't in the real
/// `TripOut`, it isn't in this model anymore.
class Trip {
  final String id;
  final String driverId;
  final String? driverFirstName;
  final String? driverLastName;
  final String originCity;
  final String originLocation;
  final String destinationCity;
  final String destinationLocation;

  /// Combined from the backend's separate `departure_date` +
  /// `departure_time` fields into one DateTime, purely for display/
  /// sorting convenience — both source fields are real.
  final DateTime departureTime;

  final num pricePerSeat;
  final int seatsAvailable;

  /// e.g. "Comfort" or "Premium" — the one vehicle-related detail that
  /// actually exists on a trip. No make, model, color, or plate here;
  /// those live on the vehicle itself, not on the published trip.
  final String vehicleCategory;
  final String? vehicleBrand;
  final String? vehicleModel;

  final String status;

  /// Null when the driver has no reviews yet — show "No ratings yet"
  /// rather than a fake 0-star score in that case.
  final double? driverRatingAverage;
  final int driverRatingCount;

  Trip({
    required this.id,
    required this.driverId,
    this.driverFirstName,
    this.driverLastName,
    required this.originCity,
    required this.originLocation,
    required this.destinationCity,
    required this.destinationLocation,
    required this.departureTime,
    required this.pricePerSeat,
    required this.seatsAvailable,
    required this.vehicleCategory,
    this.vehicleBrand,
    this.vehicleModel,
    required this.status,
    this.driverRatingAverage,
    this.driverRatingCount = 0,
  });

  /// e.g. "Jean Claude" — falls back to "Driver" when no name is on
  /// file (shouldn't normally happen, but better than a blank label).
  String get driverName {
    final full = [driverFirstName, driverLastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : 'Driver';
  }

  /// e.g. "Toyota Corolla" — falls back to just the category
  /// ("Comfort") if the vehicle's actual make/model isn't available
  /// for some reason.
  String get vehicleLabel {
    final parts = [vehicleBrand, vehicleModel].where((s) => s != null && s.isNotEmpty).join(' ');
    return parts.isNotEmpty ? parts : vehicleCategory;
  }

  /// Display label for status badges, e.g. "Scheduled" / "Completed".
  String get displayStatus {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    DateTime parseDeparture() {
      try {
        final dateOnly = DateTime.parse(json['departure_date'].toString());
        final timeParts = (json['departure_time']?.toString() ?? '00:00:00').split(':');
        final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
        final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
        return DateTime(dateOnly.year, dateOnly.month, dateOnly.day, hour, minute);
      } catch (_) {
        return DateTime.now();
      }
    }

    return Trip(
      id: json['id']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? '',
      driverFirstName: json['driver_first_name']?.toString(),
      driverLastName: json['driver_last_name']?.toString(),
      originCity: json['departure_city']?.toString() ?? '',
      originLocation: json['departure_location']?.toString() ?? '',
      destinationCity: json['destination_city']?.toString() ?? '',
      destinationLocation: json['destination_location']?.toString() ?? '',
      departureTime: parseDeparture(),
      pricePerSeat: (json['price_per_seat'] ?? 0) as num,
      seatsAvailable: (json['available_seats'] as num?)?.toInt() ?? 0,
      vehicleCategory: json['vehicle_category']?.toString() ?? '',
      vehicleBrand: json['vehicle_brand']?.toString(),
      vehicleModel: json['vehicle_model']?.toString(),
      status: json['status']?.toString() ?? '',
      driverRatingAverage: (json['driver_rating_average'] as num?)?.toDouble(),
      driverRatingCount: (json['driver_rating_count'] as num?)?.toInt() ?? 0,
    );
  }
}
