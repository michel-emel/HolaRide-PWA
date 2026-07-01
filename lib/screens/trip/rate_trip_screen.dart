import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';

/// One person to rate — the driver (for a passenger) or one specific
/// passenger (for the driver, since a trip can have several).
class RateTarget {
  final String id;
  final String name;
  final String role; // 'driver' or 'passenger'
  RateTarget({required this.id, required this.name, required this.role});
}

/// Screen shown once a trip is completed — lets the driver rate each
/// confirmed passenger individually, or a passenger rate the driver.
/// Built around the real `POST /trips/{trip_id}/reviews` endpoint:
/// 1-5 stars (required), an optional comment, and an optional quick
/// emoji reaction. Each target gets its own independent card so rating
/// several passengers doesn't have to happen all at once.
class RateTripScreen extends StatefulWidget {
  final String tripId;
  final List<RateTarget> targets;
  const RateTripScreen({super.key, required this.tripId, required this.targets});

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    SessionService.instance.getUser().then((u) {
      if (mounted) setState(() => _myUserId = u?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rate this trip'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _myUserId == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.targets.length > 1
                      ? 'How was each passenger on this trip?'
                      : 'How was your trip?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your rating helps keep HolaRide trustworthy for everyone.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                for (final target in widget.targets) ...[
                  _RatingCard(
                    tripId: widget.tripId,
                    target: target,
                    myUserId: _myUserId!,
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _RatingCard extends StatefulWidget {
  final String tripId;
  final RateTarget target;
  final String myUserId;
  const _RatingCard({required this.tripId, required this.target, required this.myUserId});

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  final _commentController = TextEditingController();
  int _stars = 0;
  String? _emoji;
  bool _checking = true;
  bool _alreadyReviewed = false;
  bool _submitting = false;
  bool _justSubmitted = false;
  String? _error;

  static const _emojiOptions = ['👍', '❤️', '😊', '😐', '👎'];

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    try {
      final already = await ReviewService.instance.hasAlreadyReviewed(
        revieweeId: widget.target.id,
        tripId: widget.tripId,
        myUserId: widget.myUserId,
      );
      if (!mounted) return;
      setState(() {
        _alreadyReviewed = already;
        _checking = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/trip/rate_trip_screen.dart: $e');
      if (!mounted) return;
      setState(() => _checking = false);
    }
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      setState(() => _error = 'Tap a star rating first.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ReviewService.instance.submitReview(
        tripId: widget.tripId,
        stars: _stars,
        comment: _commentController.text.trim(),
        emojiReaction: _emoji,
        revieweeId: widget.target.role == 'passenger' ? widget.target.id : null,
      );
      if (!mounted) return;
      setState(() => _justSubmitted = true);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/trip/rate_trip_screen.dart: $e');
      if (!mounted) return;
      setState(() => _error = 'Could not submit this rating. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.target.role == 'driver' ? 'Your driver' : widget.target.name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.textPrimary.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: _checking
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.2)),
            )
          : (_alreadyReviewed || _justSubmitted)
              ? Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.target.role == 'driver'
                            ? 'Thanks — you\'ve rated your driver.'
                            : 'Thanks — you\'ve rated $label.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(color: AppColors.infoBg, shape: BoxShape.circle),
                          child: Icon(
                            widget.target.role == 'driver' ? Icons.directions_car : Icons.person,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final filled = i < _stars;
                        return IconButton(
                          onPressed: () => setState(() {
                            _stars = i + 1;
                            _error = null;
                          }),
                          icon: Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: AppColors.gold,
                            size: 30,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _emojiOptions.map((e) {
                        final selected = _emoji == e;
                        return InkWell(
                          onTap: () => setState(() => _emoji = selected ? null : e),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.infoBg : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                            ),
                            child: Text(e, style: const TextStyle(fontSize: 16)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _commentController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: widget.target.role == 'driver'
                            ? 'Anything about the ride? (optional)'
                            : 'Anything about this passenger? (optional)',
                        filled: true,
                        fillColor: AppColors.infoBg,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Submit rating'),
                      ),
                    ),
                  ],
                ),
    );
  }
}