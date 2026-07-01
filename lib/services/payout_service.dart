import '../models/payout.dart';
import 'api_client.dart';

/// Driver payout history. There's no "withdraw" action here on purpose
/// — your backend has no `POST .../withdraw` or `GET .../balance`
/// endpoint at all (confirmed absent from the schema), which lines up
/// with the product design: payouts go out automatically via PawaPay
/// after a trip completes, not on a manual request. This only shows
/// what's already happened.
class PayoutService {
  PayoutService._();
  static final PayoutService instance = PayoutService._();

  final _api = ApiClient.instance;

  /// Confirmed: `GET /drivers/me/payouts`.
  Future<List<PayoutRecord>> getHistory() async {
    final res = await _api.get('/drivers/me/payouts');
    final list = (res as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map((e) => PayoutRecord.fromJson(e)).toList();
  }
}
