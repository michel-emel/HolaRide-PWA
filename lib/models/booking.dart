import 'trip.dart';

/// All the lifecycle states a booking can be in, per the booking
/// acceptance workflow: a request must be accepted by the driver before
/// the passenger is even allowed to pay.
enum BookingStatus {
  pendingDriverAcceptance,
  pendingPayment,
  paid,
  rejected,
  cancelled,
  completed,
  noShow,
  unknown;

  static BookingStatus fromApi(String? raw) {
    switch (raw) {
      case 'pending_driver_acceptance':
        return BookingStatus.pendingDriverAcceptance;
      case 'pending_payment':
        return BookingStatus.pendingPayment;
      case 'paid':
        return BookingStatus.paid;
      case 'rejected':
        return BookingStatus.rejected;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      case 'no_show':
        return BookingStatus.noShow;
      default:
        return BookingStatus.unknown;
    }
  }

  /// Semantic color bucket — actual colors are resolved in the
  /// StatusBadge widget from AppColors, kept out of the model on purpose.
  String get kind {
    switch (this) {
      case BookingStatus.paid:
      case BookingStatus.completed:
        return 'success';
      case BookingStatus.pendingDriverAcceptance:
      case BookingStatus.pendingPayment:
        return 'warning';
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return 'danger';
      case BookingStatus.unknown:
        return 'info';
    }
  }
}

enum PaymentOption {
  full,
  deposit;

  /// Confirmed against the real `BookingCreate` schema: the enum value
  /// is `"partial_80"`, not `"deposit"`.
  String get apiValue => this == PaymentOption.full ? 'full' : 'partial_80';

  static PaymentOption fromApi(String? raw) =>
      raw == 'partial_80' ? PaymentOption.deposit : PaymentOption.full;
}

class PassengerInfo {
  final String id;
  final String name;
  final String? photoUrl;

  PassengerInfo({required this.id, required this.name, this.photoUrl});

  factory PassengerInfo.fromJson(Map<String, dynamic> json) {
    return PassengerInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          [json['first_name'], json['last_name']]
              .where((e) => e != null && e.toString().isNotEmpty)
              .join(' '),
      photoUrl: json['photo_url']?.toString(),
    );
  }
}

class Booking {
  final String id;
  final Trip? trip;
  final String? tripId;
  final PassengerInfo? passenger;
  final int seats;
  final BookingStatus status;
  final PaymentOption paymentOption;
  final num amountTotal;
  final num amountPaid;
  final num amountDue;
  final DateTime createdAt;

  /// Only populated when this came from the driver-facing
  /// `GET /trips/{trip_id}/bookings` (the real `DriverBookingOut`
  /// schema, added to the backend specifically for this) — null
  /// everywhere else, since no other endpoint exposes passenger
  /// identity at all.
  final String? passengerId;
  final String? passengerName;
  final String? passengerPhone;
  final double? passengerRatingAverage;
  final int passengerRatingCount;

  Booking({
    required this.id,
    this.trip,
    this.tripId,
    this.passenger,
    required this.seats,
    required this.status,
    required this.paymentOption,
    required this.amountTotal,
    required this.amountPaid,
    required this.amountDue,
    required this.createdAt,
    this.passengerId,
    this.passengerName,
    this.passengerPhone,
    this.passengerRatingAverage,
    this.passengerRatingCount = 0,
  });

  /// Matches the real `BookingOut`/`MyBookingOut`/`DriverBookingOut`
  /// schemas, confirmed via the actual backend source — `seats_booked`,
  /// `price_total`, `outstanding_balance` (earlier guesses of `seats`,
  /// `amount_total`, `amount_due` were wrong field names). There's no
  /// nested `trip` object on any of them — `MyBookingOut` instead
  /// embeds the trip's own fields flatly (`departure_city`,
  /// `departure_location`, etc. sitting directly on the booking), so
  /// a minimal [Trip] is built from those when present by reusing
  /// [Trip.fromJson] on the same map (with `id` corrected to the
  /// trip's own id, not the booking's).
  ///
  /// ✅ CORRIGÉ : `MyBookingOut` a DEUX champs de statut distincts —
  /// `status` (celui du BOOKING : paid/completed/cancelled/...) et
  /// `trip_status` (celui du TRIP : published/ongoing/completed/...).
  /// Avant ce correctif, le spread `{...json, 'id': json['trip_id']}`
  /// laissait passer `json['status']` (le statut du BOOKING) tel quel
  /// vers `Trip.fromJson`, qui lit justement la clé `'status'` — donc
  /// le Trip reconstruit héritait à tort du statut du booking. On
  /// écrase maintenant explicitement `'status'` avec `trip_status`
  /// avant de construire le Trip, pour que `trip.status` reflète le
  /// vrai statut du trajet (c'est lui, et lui seul, qui détermine par
  /// exemple si le partage de position live est encore possible).
  factory Booking.fromJson(Map<String, dynamic> json) {
    Trip? trip;
    if (json['departure_city'] != null && json['departure_date'] != null) {
      trip = Trip.fromJson({
        ...json,
        'id': json['trip_id'],
        'status': json['trip_status'], // ✅ NOUVEAU — voir doc ci-dessus
      });
    }

    final firstName = json['passenger_first_name']?.toString();
    final lastName = json['passenger_last_name']?.toString();
    final fullName = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

    return Booking(
      id: json['id']?.toString() ?? '',
      trip: trip,
      tripId: json['trip_id']?.toString(),
      passenger: null,
      seats: (json['seats_booked'] as num?)?.toInt() ?? 1,
      status: BookingStatus.fromApi(json['status']?.toString()),
      paymentOption: PaymentOption.fromApi(json['payment_type']?.toString()),
      amountTotal: (json['price_total'] as num?) ?? 0,
      amountPaid: (json['amount_paid'] as num?) ?? 0,
      amountDue: (json['outstanding_balance'] as num?) ?? 0,
      passengerId: json['passenger_id']?.toString(),
      passengerName: fullName.isNotEmpty ? fullName : null,
      passengerPhone: json['passenger_phone']?.toString(),
      passengerRatingAverage: (json['passenger_rating_average'] as num?)?.toDouble(),
      passengerRatingCount: (json['passenger_rating_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}