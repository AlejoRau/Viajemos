import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/passenger/domain/trip_search_result.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/domain/user_profile.dart';

/// Shows a public profile bottom sheet for any user by their ID.
/// Pass [tripContext] to show a trip info banner at the top of the sheet.
void showPublicProfile(BuildContext context, String userId, {TripSearchResult? tripContext}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PublicProfileSheet(userId: userId, tripContext: tripContext),
  );
}

class _PublicProfileSheet extends StatefulWidget {
  const _PublicProfileSheet({required this.userId, this.tripContext});
  final String userId;
  final TripSearchResult? tripContext;

  @override
  State<_PublicProfileSheet> createState() => _PublicProfileSheetState();
}

class _PublicProfileSheetState extends State<_PublicProfileSheet> {
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ProfileRepository().fetchPublicProfile(widget.userId);
      if (mounted) setState(() { _profile = p; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'No se pudo cargar el perfil'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            Expanded(child: _ProfileBody(profile: _profile!)),
        ],
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + rating
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  profile.initials,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)),
                        children: [
                          TextSpan(text: profile.fullName),
                          if (profile.birthDate != null) ...[
                            const TextSpan(
                              text: ', ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF94A3B8)),
                            ),
                            TextSpan(
                              text: '${_age(profile.birthDate!)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: Color(0xFFFACC15)),
                        const SizedBox(width: 4),
                        Text(
                          profile.avgRating > 0
                              ? profile.avgRating.toStringAsFixed(1)
                              : 'Sin calificación',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Miembro desde ${_formatYear(profile.memberSince)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Trip stats
          Row(
            children: [
              Expanded(
                child: _StatBox(
                    value: '${profile.tripsDriver}',
                    label: 'Viajes como\nconductor',
                    icon: Icons.directions_car_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                    value: '${profile.tripsPassenger}',
                    label: 'Viajes como\npasajero',
                    icon: Icons.airline_seat_recline_normal_rounded),
              ),
            ],
          ),
          if (profile.cancelledTripsCount > 0 ||
              profile.expelledPassengersCount > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (profile.cancelledTripsCount > 0)
                  Expanded(
                    child: _StatBox(
                        value: '${profile.cancelledTripsCount}',
                        label: 'Viajes\ncancelados',
                        icon: Icons.cancel_outlined,
                        negative: true),
                  ),
                if (profile.cancelledTripsCount > 0 &&
                    profile.expelledPassengersCount > 0)
                  const SizedBox(width: 12),
                if (profile.expelledPassengersCount > 0)
                  Expanded(
                    child: _StatBox(
                        value: '${profile.expelledPassengersCount}',
                        label: 'Pasajeros\nexpulsados',
                        icon: Icons.person_remove_rounded,
                        negative: true),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Bio driver
          if (profile.bioDriver != null && profile.bioDriver!.isNotEmpty) ...[
            const Text('Como conductor',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 6),
            Text(profile.bioDriver!,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.5)),
            const SizedBox(height: 16),
          ],

          // Bio passenger
          if (profile.bioPassenger != null &&
              profile.bioPassenger!.isNotEmpty) ...[
            const Text('Como pasajero',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 6),
            Text(profile.bioPassenger!,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.5)),
            const SizedBox(height: 16),
          ],

          // Social — always shown
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          const Text('Redes sociales',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 10),
          if (profile.instagram == null || profile.instagram!.isEmpty) ...[
            if (profile.facebook == null || profile.facebook!.isEmpty)
              const Text(
                'Este usuario no agregó sus redes sociales.',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              )
          ],
          if (profile.instagram != null && profile.instagram!.isNotEmpty) ...[
            _SocialRow(
                icon: Icons.camera_alt_outlined,
                label: '@${profile.instagram}'),
            const SizedBox(height: 8),
          ],
          if (profile.facebook != null && profile.facebook!.isNotEmpty)
            _SocialRow(
                icon: Icons.facebook_rounded, label: profile.facebook!),
        ],
      ),
    );
  }

  int _age(DateTime birth) {
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    return age;
  }

  String _formatYear(DateTime d) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    this.negative = false,
  });
  final String value;
  final String label;
  final IconData icon;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final color = negative ? Colors.red.shade600 : AppColors.primary;
    final bg = negative
        ? Colors.red.withValues(alpha: 0.07)
        : AppColors.inputBackground;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: negative ? color : const Color(0xFF1E293B))),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}
