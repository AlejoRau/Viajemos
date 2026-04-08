class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avgRating,
    required this.tripsDriver,
    required this.tripsPassenger,
    required this.memberSince,
    this.cancelledTripsCount = 0,
    this.expelledPassengersCount = 0,
    this.phone,
    this.birthDate,
    this.bioDriver,
    this.bioPassenger,
    this.instagram,
    this.facebook,
  });

  final String id;
  final String fullName;
  final String email;
  final double avgRating;
  final int tripsDriver;
  final int tripsPassenger;
  final DateTime memberSince;
  final int cancelledTripsCount;
  final int expelledPassengersCount;
  final String? phone;
  final DateTime? birthDate;
  final String? bioDriver;
  final String? bioPassenger;
  final String? instagram;
  final String? facebook;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}
