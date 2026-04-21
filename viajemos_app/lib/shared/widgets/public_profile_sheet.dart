import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/passenger/domain/trip_search_result.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/domain/user_profile.dart';
import 'sheet_handle.dart';

/// Shows a public profile bottom sheet for any user by their ID.
/// [viewerIsDriver]: true = viewer is a driver (shows passenger profile of the other),
///                  false = viewer is a passenger (shows driver profile of the other),
///                  null = show both sections.
void showPublicProfile(
  BuildContext context,
  String userId, {
  TripSearchResult? tripContext,
  bool? viewerIsDriver,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PublicProfileSheet(
      userId: userId,
      tripContext: tripContext,
      viewerIsDriver: viewerIsDriver,
    ),
  );
}

class _PublicProfileSheet extends StatefulWidget {
  const _PublicProfileSheet({required this.userId, this.tripContext, this.viewerIsDriver});
  final String userId;
  final TripSearchResult? tripContext;
  final bool? viewerIsDriver;

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
          const SheetHandle(),
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
            Expanded(child: _ProfileBody(profile: _profile!, viewerIsDriver: widget.viewerIsDriver)),
        ],
      ),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody({required this.profile, this.viewerIsDriver});
  final UserProfile profile;
  /// true  = default to passenger tab (viewer is driver)
  /// false = default to driver tab (viewer is passenger)
  /// null  = default to driver tab
  final bool? viewerIsDriver;

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  late bool _showingDriver; // true = showing driver tab

  @override
  void initState() {
    super.initState();
    // Default: show the tab most relevant to the viewer
    // viewer is driver → see passenger tab first; viewer is passenger → see driver tab first
    _showingDriver = widget.viewerIsDriver != true;
  }

  UserProfile get p => widget.profile;

  int _age(DateTime birth) {
    final today = DateTime.now();
    int age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) age--;
    return age;
  }

  String _formatYear(DateTime d) {
    const months = ['enero','febrero','marzo','abril','mayo','junio',
        'julio','agosto','septiembre','octubre','noviembre','diciembre'];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + rating + toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  p.initials,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)),
                        children: [
                          TextSpan(text: p.fullName),
                          if (p.birthDate != null) ...[
                            const TextSpan(text: ', ',
                                style: TextStyle(fontWeight: FontWeight.w400,
                                    color: Color(0xFF94A3B8))),
                            TextSpan(text: '${_age(p.birthDate!)}',
                                style: const TextStyle(fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B))),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _RatingRow(
                      labelDriver: _showingDriver ? null : 'Conductor',
                      labelPassenger: _showingDriver ? null : 'Pasajero',
                      ratingDriver: p.avgRatingDriver,
                      ratingPassenger: p.avgRatingPassenger,
                      showingDriver: _showingDriver,
                    ),
                    const SizedBox(height: 3),
                    Text('Miembro desde ${_formatYear(p.memberSince)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    // Role toggle
                    _RoleToggle(
                      showingDriver: _showingDriver,
                      onChanged: (v) => setState(() => _showingDriver = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Stats
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _showingDriver
                ? _DriverStats(profile: p, key: const ValueKey('driver'))
                : _PassengerStats(profile: p, key: const ValueKey('passenger')),
          ),

          const SizedBox(height: 20),

          // Bio — siempre visible, igual en los dos tabs
          Builder(builder: (_) {
            final bio = _showingDriver
                ? (p.bioDriver?.isNotEmpty == true ? p.bioDriver! : p.bioPassenger ?? '')
                : (p.bioPassenger?.isNotEmpty == true ? p.bioPassenger! : p.bioDriver ?? '');
            if (bio.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sobre mí',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                Text(bio,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF475569), height: 1.5)),
                const SizedBox(height: 16),
              ],
            );
          }),

          // Social
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          const Text('Redes sociales',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 10),
          if ((p.instagram == null || p.instagram!.isEmpty) &&
              (p.facebook == null || p.facebook!.isEmpty))
            const Text('Este usuario no agregó sus redes sociales.',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          if (p.instagram != null && p.instagram!.isNotEmpty) ...[
            _SocialRow(icon: Icons.camera_alt_outlined, label: '@${p.instagram}'),
            const SizedBox(height: 8),
          ],
          if (p.facebook != null && p.facebook!.isNotEmpty)
            _SocialRow(icon: Icons.facebook_rounded, label: p.facebook!),
        ],
      ),
    );
  }
}

// ── Role toggle ───────────────────────────────────────────────────────────────

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.showingDriver, required this.onChanged});
  final bool showingDriver;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleTab(
            label: 'Conductor',
            icon: Icons.directions_car_rounded,
            active: showingDriver,
            onTap: () => onChanged(true),
          ),
          const SizedBox(width: 2),
          _ToggleTab(
            label: 'Pasajero',
            icon: Icons.airline_seat_recline_normal_rounded,
            active: !showingDriver,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [const BoxShadow(color: Color(0x18000000), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13,
                color: active ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Stats sections ────────────────────────────────────────────────────────────

class _DriverStats extends StatelessWidget {
  const _DriverStats({super.key, required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatBox(
          value: '${profile.tripsDriver}',
          label: 'Viajes como conductor',
          icon: Icons.directions_car_rounded,
        ),
        if (profile.cancelledTripsCount > 0 || profile.expelledPassengersCount > 0) ...[
          const SizedBox(height: 12),
          Row(children: [
            if (profile.cancelledTripsCount > 0)
              Expanded(child: _StatBox(
                  value: '${profile.cancelledTripsCount}',
                  label: 'Viajes\ncancelados',
                  icon: Icons.cancel_outlined,
                  negative: true)),
            if (profile.cancelledTripsCount > 0 && profile.expelledPassengersCount > 0)
              const SizedBox(width: 12),
            if (profile.expelledPassengersCount > 0)
              Expanded(child: _StatBox(
                  value: '${profile.expelledPassengersCount}',
                  label: 'Pasajeros\nexpulsados',
                  icon: Icons.person_remove_rounded,
                  negative: true)),
          ]),
        ],
      ],
    );
  }
}

class _PassengerStats extends StatelessWidget {
  const _PassengerStats({super.key, required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatBox(
          value: '${profile.tripsPassenger}',
          label: 'Viajes como pasajero',
          icon: Icons.airline_seat_recline_normal_rounded,
        ),
        if (profile.kickedOutCount > 0 || profile.lateCancellationsCount > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (profile.kickedOutCount > 0) ...[
                Expanded(
                  child: _StatBox(
                    value: '${profile.kickedOutCount}',
                    label: 'Viajes\nque lo bajaron',
                    icon: Icons.directions_walk_rounded,
                    negative: true,
                  ),
                ),
                if (profile.lateCancellationsCount > 0) const SizedBox(width: 12),
              ],
              if (profile.lateCancellationsCount > 0)
                Expanded(
                  child: _StatBox(
                    value: '${profile.lateCancellationsCount}',
                    label: 'Bajas en\ncorto aviso',
                    icon: Icons.alarm_off_rounded,
                    negative: true,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
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

// ── Rating row — muestra conductor y/o pasajero según el tab activo ──────────

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.ratingDriver,
    required this.ratingPassenger,
    required this.showingDriver,
    this.labelDriver,
    this.labelPassenger,
  });
  final double ratingDriver;
  final double ratingPassenger;
  final bool showingDriver;
  final String? labelDriver;
  final String? labelPassenger;

  Widget _chip(double rating, String label) {
    final hasRating = rating > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFACC15)),
        const SizedBox(width: 3),
        Text(
          hasRating ? rating.toStringAsFixed(1) : 'Sin cal.',
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showingDriver) {
      return _chip(ratingDriver, 'conductor');
    }
    return _chip(ratingPassenger, 'pasajero');
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
