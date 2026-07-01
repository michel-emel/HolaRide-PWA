/// One line in a driver's payout history.
class PayoutRecord {
  final String id;
  final num amount;
  final String status;
  final DateTime date;

  PayoutRecord({
    required this.id,
    required this.amount,
    required this.status,
    required this.date,
  });

  bool get isPaid => status == 'paid';

  factory PayoutRecord.fromJson(Map<String, dynamic> json) {
    return PayoutRecord(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] ?? 0) as num,
      status: json['status']?.toString() ?? 'pending',
      date: DateTime.tryParse(json['date']?.toString() ?? json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
