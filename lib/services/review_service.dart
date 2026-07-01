import '../models/review.dart';
import 'api_client.dart';

/// Confirmed against the real backend source (`app/routers/reviews.py`).
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final _api = ApiClient.instance;

  /// `revieweeId` is only needed when YOU are the driver reviewing a
  /// passenger (a trip can have several, so it has to be said which
  /// one). When you're a passenger reviewing the driver, leave it
  /// null — the backend works that out from the trip automatically.
  Future<Review> submitReview({
    required String tripId,
    required int stars,
    String? comment,
    String? emojiReaction,
    String? revieweeId,
  }) async {
    final res = await _api.post('/trips/$tripId/reviews', body: {
      'stars': stars,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      if (emojiReaction != null && emojiReaction.isNotEmpty) 'emoji_reaction': emojiReaction,
      if (revieweeId != null) 'reviewee_id': revieweeId,
    });
    return Review.fromJson(res as Map<String, dynamic>);
  }

  /// Public — no auth needed, works for either a driver or a passenger.
  Future<ReviewSummary> getUserReviews(String userId) async {
    final res = await _api.get('/users/$userId/reviews', auth: false);
    return ReviewSummary.fromJson(res as Map<String, dynamic>);
  }

  /// Confirmed: `GET /trips/{trip_id}/reviews/pending` — who the
  /// CURRENT user still needs to rate for this trip. Empty list means
  /// nothing to show, including for a trip that isn't completed yet.
  /// Preferred over [hasAlreadyReviewed] below now that this real
  /// endpoint exists — it's one call instead of fetching someone's
  /// entire review history just to check one trip.
  Future<List<PendingReview>> getPendingReviews(String tripId) async {
    final res = await _api.get('/trips/$tripId/reviews/pending');
    final list = (res as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map((e) => PendingReview.fromJson(e)).toList();
  }

  /// Convenience used by the rating screen to check, before showing
  /// the form, whether the current user has already reviewed this
  /// specific person for this specific trip — there's no dedicated
  /// endpoint for that, so this works it out from the full list
  /// GET /users/{id}/reviews already returns.
  Future<bool> hasAlreadyReviewed({
    required String revieweeId,
    required String tripId,
    required String myUserId,
  }) async {
    final summary = await getUserReviews(revieweeId);
    return summary.reviews.any((r) => r.tripId == tripId && r.reviewerId == myUserId);
  }
}
