import 'package:flutter/material.dart';

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
    this.avatarUrl,
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
  final String? avatarUrl;
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

  // ── Completeness booleans ─────────────────────────────────────────────────
  bool get hasAvatar    => avatarUrl != null && avatarUrl!.isNotEmpty;
  bool get hasPhone     => phone != null && phone!.isNotEmpty;
  bool get hasBirthDate => birthDate != null;
  bool get hasBio       => (bioDriver?.isNotEmpty ?? false) || (bioPassenger?.isNotEmpty ?? false);
  bool get hasInstagram => instagram != null && instagram!.isNotEmpty;
  bool get hasFacebook  => facebook != null && facebook!.isNotEmpty;

  bool itemDone(ProfileCompletenessItem item) => switch (item) {
    ProfileCompletenessItem.avatar    => hasAvatar,
    ProfileCompletenessItem.phone     => hasPhone,
    ProfileCompletenessItem.birthDate => hasBirthDate,
    ProfileCompletenessItem.bio       => hasBio,
    ProfileCompletenessItem.instagram => hasInstagram,
    ProfileCompletenessItem.facebook  => hasFacebook,
  };

  int get completenessScore {
    int score = 0;
    for (final item in ProfileCompletenessItem.values) {
      if (itemDone(item)) score++;
    }
    return score;
  }

  ProfileTrustLevel get trustLevel {
    final identified = hasPhone && hasBirthDate;
    final verified   = identified && hasAvatar && hasBio;
    final complete   = verified && (hasInstagram || hasFacebook);
    if (complete)   return ProfileTrustLevel.complete;
    if (verified)   return ProfileTrustLevel.verified;
    if (identified) return ProfileTrustLevel.identified;
    return ProfileTrustLevel.basic;
  }
}

// ── Trust level ───────────────────────────────────────────────────────────────

enum ProfileTrustLevel { basic, identified, verified, complete }

extension ProfileTrustLevelX on ProfileTrustLevel {
  String get spanishName => switch (this) {
    ProfileTrustLevel.basic      => 'Básico',
    ProfileTrustLevel.identified => 'Identificado',
    ProfileTrustLevel.verified   => 'Verificado',
    ProfileTrustLevel.complete   => 'Completo',
  };

  int get levelNumber => switch (this) {
    ProfileTrustLevel.basic      => 0,
    ProfileTrustLevel.identified => 1,
    ProfileTrustLevel.verified   => 2,
    ProfileTrustLevel.complete   => 3,
  };

  Color get color => switch (this) {
    ProfileTrustLevel.basic      => const Color(0xFF94A3B8),
    ProfileTrustLevel.identified => const Color(0xFFF59E0B),
    ProfileTrustLevel.verified   => const Color(0xFF1A73E8),
    ProfileTrustLevel.complete   => const Color(0xFF15803D),
  };

  IconData get icon => switch (this) {
    ProfileTrustLevel.basic      => Icons.shield_outlined,
    ProfileTrustLevel.identified => Icons.verified_user_outlined,
    ProfileTrustLevel.verified   => Icons.verified_outlined,
    ProfileTrustLevel.complete   => Icons.workspace_premium_rounded,
  };
}

// ── Completeness items ────────────────────────────────────────────────────────

enum ProfileCompletenessItem { avatar, phone, birthDate, bio, instagram, facebook }

extension ProfileCompletenessItemX on ProfileCompletenessItem {
  String get label => switch (this) {
    ProfileCompletenessItem.avatar    => 'Foto de perfil',
    ProfileCompletenessItem.phone     => 'Teléfono verificado',
    ProfileCompletenessItem.birthDate => 'Fecha de nacimiento',
    ProfileCompletenessItem.bio       => 'Descripción personal',
    ProfileCompletenessItem.instagram => 'Instagram',
    ProfileCompletenessItem.facebook  => 'Facebook',
  };

  String get subtitle => switch (this) {
    ProfileCompletenessItem.avatar    => 'Los usuarios confían más en perfiles con foto',
    ProfileCompletenessItem.phone     => 'Permite que te contacten durante el viaje',
    ProfileCompletenessItem.birthDate => 'Confirma que sos mayor de 16 años',
    ProfileCompletenessItem.bio       => 'Contá quién sos para generar confianza',
    ProfileCompletenessItem.instagram => 'Tus viajeros pueden conocerte mejor',
    ProfileCompletenessItem.facebook  => 'Tus viajeros pueden conocerte mejor',
  };
}
