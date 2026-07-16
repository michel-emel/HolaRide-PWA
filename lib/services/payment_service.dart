import 'api_client.dart';

class PaymentResult {
  final String status;
  final String? failureReason;
  final String? errorMessage;
  const PaymentResult({required this.status, this.failureReason, this.errorMessage});
}

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> initiatePayment(String bookingId) async {
    final res = await _api.post('/bookings/$bookingId/initiate-payment', body: {});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<PaymentResult> getPaymentStatus(String bookingId) async {
    final res = await _api.get('/bookings/$bookingId/payment-status');
    final map = res as Map<String, dynamic>;
    return PaymentResult(
      status:        map['payment_status']?.toString() ?? 'pending',
      failureReason: map['failure_reason']?.toString(),
      errorMessage:  map['error_message']?.toString(),
    );
  }

  Future<void> devForcePaid(String bookingId) async {
    await _api.post('/bookings/$bookingId/dev-force-paid', body: {});
  }
}