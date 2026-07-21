/// Represents the logged-in account. Same model whether the person is
/// currently riding or driving — HolaRide accounts are dual-role by design.
class AppUser {
  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final bool canDrive; // true once admin has approved a vehicle for this user
  final DateTime? memberSince;
  final bool isVerified;

  AppUser({
    required this.id,
    required this.phone,
    this.firstName,
    this.lastName,
    this.canDrive = false,
    this.memberSince,
    this.isVerified = false,
  });

  String get displayName {
    final name = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return name.isEmpty ? phone : name;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime? memberSince;
    final createdAtRaw = json['created_at'];
    if (createdAtRaw != null) {
      memberSince = DateTime.tryParse(createdAtRaw.toString());
    }
    return AppUser(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['phone_number']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      canDrive: json['can_drive'] == true || json['has_approved_vehicle'] == true,
      memberSince: memberSince,
      isVerified: json['phone_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'first_name': firstName,
        'last_name': lastName,
        'can_drive': canDrive,
        'created_at': memberSince?.toIso8601String(),
        'phone_verified': isVerified,
      };
}

/// Trips-completed + average-rating pair shown on the profile stats
/// card. Fetched separately from `/me/stats` since neither figure is a
/// stored column — both are computed from bookings/trips/reviews.
class ProfileStats {
  final int tripsCompleted;
  final double? averageRating;

  ProfileStats({required this.tripsCompleted, this.averageRating});

  factory ProfileStats.fromJson(Map<String, dynamic> json) => ProfileStats(
        tripsCompleted: (json['trips_completed'] as num?)?.toInt() ?? 0,
        averageRating: (json['average_rating'] as num?)?.toDouble(),
      );
}