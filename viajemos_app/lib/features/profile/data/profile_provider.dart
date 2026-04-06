import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_repository.dart';
import '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (_) => ProfileRepository(),
);

final profileProvider = FutureProvider<UserProfile>((ref) {
  return ref.read(profileRepositoryProvider).fetchMyProfile();
});
