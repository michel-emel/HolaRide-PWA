import 'package:flutter/material.dart';
import '../../models/payout.dart';
import '../../services/payout_service.dart';
import '../../theme/app_colors.dart';

/// Screen 22 — Payout history.
///
/// No balance card or withdraw button — your backend doesn't have
/// those endpoints. Payouts go out automatically via PawaPay once a
/// trip completes, so this is purely a record of what's already
/// happened, with a "total paid out" figure computed client-side from
/// that history rather than from a balance endpoint that doesn't exist.
class PayoutHistoryScreen extends StatefulWidget {
  const PayoutHistoryScreen({super.key});

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  List<PayoutRecord> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final history = await PayoutService.instance.getHistory();
      history.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/payout_history_screen.dart: $e');
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load your payouts.";
        _loading = false;
      });
    }
  }

  num get _totalPaid =>
      _history.where((p) => p.isPaid).fold<num>(0, (sum, p) => sum + p.amount);

  String _money(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf XAF';
  }

  String _dateLabel(DateTime t) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${t.day} ${months[t.month - 1]} ${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payout history')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total paid out',
                                style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(_money(_totalPaid),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            const Text(
                              'Sent automatically to your Mobile Money after each completed trip.',
                              style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text('History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 10),
                      if (_history.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('No payouts yet.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      else
                        ..._history.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_dateLabel(p.date),
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                                        const SizedBox(height: 2),
                                        Text('Payout', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(_money(p.amount),
                                          style: const TextStyle(fontWeight: FontWeight.w800)),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p.isPaid ? AppColors.successBg : AppColors.warningBg,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          p.isPaid ? 'Paid' : 'Pending',
                                          style: TextStyle(
                                            color: p.isPaid ? AppColors.success : AppColors.warning,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
