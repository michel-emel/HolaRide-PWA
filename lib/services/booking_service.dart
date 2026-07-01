import '../models/booking.dart';
import '../models/payment_status.dart';
import 'api_client.dart';

/// Wraps the booking lifecycle: request a seat, pay once the driver
/// accepts, pay the remaining balance on a deposit booking, or
/// cancel/withdraw a request.
///
/// Endpoint paths and HTTP methods below are confirmed against your
/// backend's real OpenAPI schema (several of my original guesses had
/// the wrong method — PATCH vs POST — even when the path looked right).
/// Field names inside request bodies are still a guess where noted.
class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  final _api = ApiClient.instance;

  /// Sends a seat request to the driver. Lands in `pending_driver_acceptance`
  /// — the passenger cannot pay until the driver explicitly accepts.
  /// Confirmed against the real `BookingCreate` schema: `seats_booked`
  /// (required) and `payment_type` (enum `"full"`/`"partial_80"`,
  /// defaults to `"full"`) — both your earlier guesses (`seats`,
  /// `payment_option`) were wrong field names.
  Future<Booking> requestBooking({
    required String tripId,
    required int seats,
    required PaymentOption paymentOption,
  }) async {
    final res = await _api.post('/trips/$tripId/bookings', body: {
      'seats_booked': seats,
      'payment_type': paymentOption.apiValue,
    });
    return Booking.fromJson(res as Map<String, dynamic>);
  }

  Future<List<Booking>> myBookings() async {
    final res = await _api.get('/me/bookings');
    final list = (res as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map((e) => Booking.fromJson(e)).toList();
  }

  /// There's no direct `GET /bookings/{id}` on your backend — the only
  /// way to look up a single booking's current state is to fetch the
  /// full list and find it. Used for polling (e.g. "is the driver
  /// answering yet").
  Future<Booking?> getById(String bookingId) async {
    final all = await myBookings();
    for (final b in all) {
      if (b.id == bookingId) return b;
    }
    return null;
  }

  /// Starts a Mobile Money payment. Confirmed path:
  /// `POST /bookings/{booking_id}/initiate-payment`. This does NOT
  /// confirm the payment — Mobile Money is asynchronous (it sends a
  /// USSD prompt to the person's phone). Call [pollPaymentStatus] after
  /// this to find out when it actually succeeds or fails.
  ///
  /// Takes no request body at all — confirmed from the real backend
  /// source. It always charges whatever phone number is on the
  /// passenger's own account (`passenger.phone_number`) and detects
  /// MTN vs Orange itself via PawaPay's own provider lookup. A
  /// provider/phone-number picker on the payment screen would be
  /// fiction — the backend ignores both entirely.
  Future<void> initiatePayment({required String bookingId}) async {
    await _api.post('/bookings/$bookingId/initiate-payment');
  }

  /// Confirmed path: `GET /bookings/{booking_id}/payment-status`.
  ///
  /// The response key is `payment_status` (your earlier guess of
  /// `status` was wrong — it was always reading a field that doesn't
  /// exist, so polling could never recognize a terminal result and
  /// would just run until the 3-minute timeout, every time).
  ///
  /// There's also a real race condition in the backend worth handling
  /// here: if PawaPay's webhook resolves the payment in between two of
  /// your polls, the next poll finds no "pending" row anymore and
  /// returns the special value `"none_pending"` instead of "success" —
  /// along with a separate `booking_status` field that reveals what
  /// actually happened. Falling back to that avoids the rare case where
  /// a real successful payment would otherwise look stuck forever.
  Future<PaymentStatus> getPaymentStatus(String bookingId) async {
    final res = await _api.get('/bookings/$bookingId/payment-status');
    final map = res as Map<String, dynamic>;
    final paymentStatus = map['payment_status']?.toString();
    if (paymentStatus == 'none_pending') {
      final bookingStatus = map['booking_status']?.toString();
      return bookingStatus == 'paid' ? PaymentStatus.paid : PaymentStatus.pending;
    }
    return PaymentStatus.fromApi(paymentStatus);
  }

  /// Polls payment status every [interval] until it reaches a terminal
  /// state (paid/failed/expired) or [timeout] elapses. Returns the
  /// final status it saw — callers should treat anything other than
  /// [PaymentStatus.paid] as "didn't go through."
  Future<PaymentStatus> pollPaymentStatus(
    String bookingId, {
    Duration interval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final status = await getPaymentStatus(bookingId);
      if (status.isTerminal) return status;
      await Future.delayed(interval);
    }
    return PaymentStatus.unknown;
  }

  /// Pays the remaining balance on a deposit booking. Confirmed path:
  /// `POST /bookings/{booking_id}/pay-balance`. Same async caveat as
  /// [initiatePayment] — poll [getPaymentStatus] afterward. Also takes
  /// no request body, same as [initiatePayment].
  Future<void> initiateBalancePayment({required String bookingId}) async {
    await _api.post('/bookings/$bookingId/pay-balance');
  }

  /// DEV-ONLY. Calls a backend endpoint added specifically for this —
  /// mirrors `quick_test.py`'s `force_mark_paid()`, instantly marking
  /// a booking "paid" without touching real Mobile Money at all. The
  /// backend 404s this unconditionally unless `PAYMENT_DEV_MODE=true`
  /// is set there, and that flag is forcibly disabled in production
  /// regardless of `.env` — so against a real deployment this call
  /// simply fails with a 404, same as if it didn't exist. The actual
  /// safety boundary lives server-side, not in whether a button is
  /// visible here.
  Future<void> devForcePaid(String bookingId) async {
    await _api.post('/bookings/$bookingId/dev-force-paid');
  }

  /// Cancels (if already paid — subject to the time-tiered fee) or
  /// withdraws (if still just a pending request, no fee) a booking.
  /// Confirmed: `PATCH /bookings/{booking_id}/cancel`.
  Future<void> cancel(String bookingId) async {
    await _api.patch('/bookings/$bookingId/cancel');
  }
}