import '../models/booking.dart';
import '../models/trip.dart';
import 'api_client.dart';

/// Everything a driver does once their vehicle is approved: publish a
/// trip, see who's requesting seats on it, accept/reject those
/// requests, and close the trip out.
///
/// Price is never set by the driver here — the backend snapshots it at
/// trip creation based on route and vehicle category, which is why
/// [createTrip] takes a `vehicleId` instead of a price.
///
/// Endpoint paths and HTTP methods confirmed against your backend's
/// real OpenAPI schema. Several of my original guesses used POST where
/// the real endpoint is PATCH — fixed below.
class DriverService {
  DriverService._();
  static final DriverService instance = DriverService._();

  final _api = ApiClient.instance;

  /// Confirmed: `POST /trips`, matching the real `TripCreate` schema —
  /// `vehicle_id`, `departure_location_id`, `destination_location_id`
  /// (real location UUIDs, not city strings), separate `departure_date`
  /// and `departure_time` fields (not one combined timestamp), and
  /// `available_seats`. [vehicleId] matters because price is determined
  /// by route + the vehicle's assigned category — without it, the
  /// backend has no category to price against.
  Future<Trip> createTrip({
    required String departureLocationId,
    required String destinationLocationId,
    required DateTime departureDate,
    required int departureHour,
    required int departureMinute,
    required int availableSeats,
    required String vehicleId,
  }) async {
    final dateStr = '${departureDate.year.toString().padLeft(4, '0')}-'
        '${departureDate.month.toString().padLeft(2, '0')}-'
        '${departureDate.day.toString().padLeft(2, '0')}';
    final timeStr = '${departureHour.toString().padLeft(2, '0')}:'
        '${departureMinute.toString().padLeft(2, '0')}:00';
    final res = await _api.post('/trips', body: {
      'vehicle_id': vehicleId,
      'departure_location_id': departureLocationId,
      'destination_location_id': destinationLocationId,
      'departure_date': dateStr,
      'departure_time': timeStr,
      'available_seats': availableSeats,
    });
    return Trip.fromJson(res as Map<String, dynamic>);
  }

  /// `GET /trips/price-preview` — added to the backend specifically so
  /// this screen can show a real number instead of "set automatically."
  /// Uses the exact same pricing lookup `createTrip` ends up using
  /// server-side, so this can never drift out of sync with the price a
  /// published trip would actually get.
  Future<num> previewPrice({
    required String vehicleId,
    required String departureLocationId,
    required String destinationLocationId,
  }) async {
    final res = await _api.get('/trips/price-preview', query: {
      'vehicle_id': vehicleId,
      'departure_location_id': departureLocationId,
      'destination_location_id': destinationLocationId,
    });
    final map = res as Map<String, dynamic>;
    return (map['price_per_seat'] ?? 0) as num;
  }

  Future<List<Trip>> myTrips() async {
    final res = await _api.get('/drivers/me/trips');
    final list = (res as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map((e) => Trip.fromJson(e)).toList();
  }

  /// `GET /trips/{trip_id}/bookings` — added to the backend specifically
  /// for this. Returns every booking on one of your own trips, complete
  /// with the passenger's name and phone, so the Requests/Bookings tabs
  /// in trip management actually have something real to show.
  Future<List<Booking>> tripBookings(String tripId) async {
    final res = await _api.get('/trips/$tripId/bookings');
    final list = (res as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map((e) => Booking.fromJson(e)).toList();
  }

  /// Confirmed: `PATCH /bookings/{booking_id}/accept`.
  Future<void> acceptBooking(String bookingId) async {
    await _api.patch('/bookings/$bookingId/accept');
  }

  /// Confirmed: `PATCH /bookings/{booking_id}/reject`.
  Future<void> rejectBooking(String bookingId) async {
    await _api.patch('/bookings/$bookingId/reject');
  }

  /// Confirmed: `PATCH /bookings/{booking_id}/mark-no-show`.
  Future<void> markNoShow(String bookingId) async {
    await _api.patch('/bookings/$bookingId/mark-no-show');
  }

  /// Confirmed: `PATCH /trips/{trip_id}/cancel`.
  Future<void> cancelTrip(String tripId) async {
    await _api.patch('/trips/$tripId/cancel');
  }

  /// Confirmed: `PATCH /trips/{trip_id}/complete`.
  Future<void> markTripCompleted(String tripId) async {
    await _api.patch('/trips/$tripId/complete');
  }
}