/// A single review left on a completed trip — confirmed against the
/// real backend source (`app/routers/reviews.py`). The reviewer's name
/// is joined in server-side specifically for this app; without it,
/// only a UUID would be available.
class Review {
  final String id;
  final String tripId;
  final String reviewerId;
  final String revieweeId;
  final String reviewerRole; // "driver" or "passenger"
  final int stars;
  final String? comment;
  final String? emojiReaction;
  final DateTime createdAt;
  final String? reviewerFirstName;
  final String? reviewerLastName;

  Review({
    required this.id,
    required this.tripId,
    required this.reviewerId,
    required this.revieweeId,
    required this.reviewerRole,
    required this.stars,
    this.comment,
    this.emojiReaction,
    required this.createdAt,
    this.reviewerFirstName,
    this.reviewerLastName,
  });

  String get reviewerName {
    final name = [reviewerFirstName, reviewerLastName].where((s) => s != null && s.isNotEmpty).join(' ');
    if (name.isNotEmpty) return name;
    return reviewerRole == 'driver' ? 'Driver' : 'Passenger';
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      tripId: json['trip_id']?.toString() ?? '',
      reviewerId: json['reviewer_id']?.toString() ?? '',
      revieweeId: json['reviewee_id']?.toString() ?? '',
      reviewerRole: json['reviewer_role']?.toString() ?? '',
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString(),
      emojiReaction: json['emoji_reaction']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      reviewerFirstName: json['reviewer_first_name']?.toString(),
      reviewerLastName: json['reviewer_last_name']?.toString(),
    );
  }
}

/// Confirmed: GET /users/{id}/reviews returns this shape — an average,
/// a count, and the full list. Works for either a driver or a
/// passenger; the backend doesn't distinguish, it just looks at who
/// the reviewee is.
class ReviewSummary {
  final double averageStars;
  final int totalReviews;
  final List<Review> reviews;

  ReviewSummary({required this.averageStars, required this.totalReviews, required this.reviews});

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final list = (json['reviews'] as List?) ?? const [];
    return ReviewSummary(
      averageStars: (json['average_stars'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      reviews: list.whereType<Map<String, dynamic>>().map((e) => Review.fromJson(e)).toList(),
    );
  }
}

/// One person the current user still needs to rate for a completed
/// trip — confirmed against the real `PendingReviewOut` schema.
/// role is "driver" or "passenger".
class PendingReview {
  final String userId;
  final String role;
  final String? firstName;
  final String? lastName;

  PendingReview({required this.userId, required this.role, this.firstName, this.lastName});

  bool get isDriver => role == 'driver';

  String get name {
    final full = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;
    return isDriver ? 'Driver' : 'Passenger';
  }

  factory PendingReview.fromJson(Map<String, dynamic> json) {
    return PendingReview(
      userId: json['user_id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
    );
  }
}
