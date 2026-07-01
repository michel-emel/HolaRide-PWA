/// Status of an in-flight Mobile Money payment, from
/// `GET /bookings/{booking_id}/payment-status`.
///
/// Mobile Money payments are asynchronous in real life: initiating one
/// just sends a USSD prompt to the person's phone, and PawaPay confirms
/// success or failure later via webhook. So payment screens poll this
/// rather than assuming `initiate-payment` itself returns a final result.
enum PaymentStatus {
  pending,
  processing,
  paid,
  failed,
  expired,
  unknown;

  static PaymentStatus fromApi(String? raw) {
    switch (raw) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
      case 'in_progress':
        return PaymentStatus.processing;
      case 'paid':
      case 'success':
      case 'successful':
      case 'completed':
        return PaymentStatus.paid;
      case 'failed':
        return PaymentStatus.failed;
      case 'expired':
        return PaymentStatus.expired;
      default:
        return PaymentStatus.unknown;
    }
  }

  bool get isTerminal => this == PaymentStatus.paid || this == PaymentStatus.failed || this == PaymentStatus.expired;
}
