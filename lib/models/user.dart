/// Represents the logged-in account. Same model whether the person is
/// currently riding or driving — HolaRide accounts are dual-role by design.
class AppUser {
  final String id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final bool canDrive; // true once admin has approved a vehicle for this user

  AppUser({
    required this.id,
    required this.phone,
    this.firstName,
    this.lastName,
    this.canDrive = false,
  });

  String get displayName {
    final name = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return name.isEmpty ? phone : name;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['phone_number']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      canDrive: json['can_drive'] == true || json['has_approved_vehicle'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'first_name': firstName,
        'last_name': lastName,
        'can_drive': canDrive,
      };
}
