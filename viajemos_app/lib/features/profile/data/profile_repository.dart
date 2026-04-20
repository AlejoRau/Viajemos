import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_profile.dart';

class ProfileRepository {
  final _client = Supabase.instance.client;

  Future<UserProfile> fetchMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    var data = await _client
        .from('profiles')
        .select(
            'full_name, avg_rating_driver, avg_rating_passenger, trips_driven, trips_taken, bio_driver, bio_passenger, instagram, facebook, phone, birth_date, avatar_url, home_city')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      await _client.from('profiles').insert({'id': user.id});
      data = {
        'full_name': null,
        'avg_rating_driver': 0.0,
        'avg_rating_passenger': 0.0,
        'trips_driven': 0,
        'trips_taken': 0,
        'bio_driver': null,
        'bio_passenger': null,
        'instagram': null,
        'facebook': null,
        'phone': null,
        'birth_date': null,
        'avatar_url': null,
      };
    }

    final fullName = (data['full_name'] as String?)?.trim().isNotEmpty == true
        ? data['full_name'] as String
        : (user.userMetadata?['full_name'] as String?)?.trim() ??
            (user.userMetadata?['name'] as String?)?.trim() ??
            user.email ??
            'Usuario';

    final birthDateStr = data['birth_date'] as String?;

    return UserProfile(
      id: user.id,
      fullName: fullName,
      email: user.email ?? '',
      avgRatingDriver: (data['avg_rating_driver'] as num?)?.toDouble() ?? 0.0,
      avgRatingPassenger: (data['avg_rating_passenger'] as num?)?.toDouble() ?? 0.0,
      tripsDriver: (data['trips_driven'] as int?) ?? 0,
      tripsPassenger: (data['trips_taken'] as int?) ?? 0,
      memberSince: DateTime.parse(user.createdAt),
      avatarUrl: data['avatar_url'] as String?,
      phone: data['phone'] as String?,
      birthDate: birthDateStr != null ? DateTime.tryParse(birthDateStr) : null,
      bioDriver: data['bio_driver'] as String?,
      bioPassenger: data['bio_passenger'] as String?,
      instagram: data['instagram'] as String?,
      facebook: data['facebook'] as String?,
      homeCity: data['home_city'] as String?,
    );
  }

  Future<String> uploadAvatar(XFile file) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    // Always store as JPEG — image_picker normalizes images when imageQuality is set,
    // and the bucket only accepts image/jpeg, image/png, image/webp.
    const path_storage = 'avatar.jpg';
    final storagePath = '${user.id}/$path_storage';
    await _client.storage.from('avatars').uploadBinary(
      storagePath,
      await File(file.path).readAsBytes(),
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    // Append a cache-busting timestamp so Flutter doesn't show the old photo
    // after re-upload (NetworkImage caches by URL).
    final baseUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
    final url = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    await _client.from('profiles').update({'avatar_url': url}).eq('id', user.id);
    return url;
  }

  Future<void> updatePersonalData({
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('profiles').update({
      'full_name': '$firstName $lastName'.trim(),
      'birth_date': birthDate?.toIso8601String().substring(0, 10),
    }).eq('id', user.id);
  }

  Future<void> updatePhone(String phone) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('profiles').update({
      'phone': phone.trim().isEmpty ? null : phone.trim(),
    }).eq('id', user.id);
  }

  Future<void> updateBio({
    required String? bioDriver,
    required String? bioPassenger,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('profiles').update({
      'bio_driver': bioDriver,
      'bio_passenger': bioPassenger,
    }).eq('id', user.id);
  }

  Future<UserProfile> fetchPublicProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select('full_name, avg_rating_driver, avg_rating_passenger, trips_driven, trips_taken, cancelled_trips_count, expelled_passengers_count, late_cancellations_count, bio_driver, bio_passenger, instagram, facebook, created_at, birth_date, home_city')
        .eq('id', userId)
        .single();

    final birthDateStr = data['birth_date'] as String?;

    return UserProfile(
      id: userId,
      fullName: (data['full_name'] as String?)?.trim().isNotEmpty == true
          ? data['full_name'] as String
          : 'Usuario',
      email: '',
      avgRatingDriver: (data['avg_rating_driver'] as num?)?.toDouble() ?? 0.0,
      avgRatingPassenger: (data['avg_rating_passenger'] as num?)?.toDouble() ?? 0.0,
      tripsDriver: (data['trips_driven'] as int?) ?? 0,
      tripsPassenger: (data['trips_taken'] as int?) ?? 0,
      cancelledTripsCount: (data['cancelled_trips_count'] as int?) ?? 0,
      expelledPassengersCount: (data['expelled_passengers_count'] as int?) ?? 0,
      lateCancellationsCount: (data['late_cancellations_count'] as int?) ?? 0,
      memberSince: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
      birthDate: birthDateStr != null ? DateTime.tryParse(birthDateStr) : null,
      bioDriver: data['bio_driver'] as String?,
      bioPassenger: data['bio_passenger'] as String?,
      instagram: data['instagram'] as String?,
      facebook: data['facebook'] as String?,
      homeCity: data['home_city'] as String?,
    );
  }

  Future<void> updateCity(String? city) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('profiles').update({
      'home_city': city?.trim().isEmpty == true ? null : city?.trim(),
    }).eq('id', user.id);
  }

  Future<void> updateSocial({
    required String? instagram,
    required String? facebook,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('profiles').update({
      'instagram': instagram,
      'facebook': facebook,
    }).eq('id', user.id);
  }
}
