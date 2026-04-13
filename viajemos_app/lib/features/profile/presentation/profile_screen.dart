import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/badge_providers.dart';
import '../data/profile_provider.dart';
import '../domain/user_profile.dart';
import '../../../features/vehicles/data/vehicles_provider.dart';
import '../../../features/vehicles/domain/vehicle.dart';
import '../../../shared/widgets/vehicle_selector_sheet.dart';
import '../../../shared/services/push_notification_service.dart';

// ── Auto-save ─────────────────────────────────────────────────────────────────

enum _SaveStatus { idle, saving, saved }

class _AutoSaveIndicator extends StatelessWidget {
  const _AutoSaveIndicator(this.status);
  final _SaveStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _SaveStatus.idle => const SizedBox.shrink(),
      _SaveStatus.saving => const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF94A3B8)),
        ),
      _SaveStatus.saved => const Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: Color(0xFF16A34A),
        ),
    };
  }
}

// ── ProfileScreen ─────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramFocusNode = FocusNode();
  final _facebookFocusNode = FocusNode();
  bool _controllersInitialized = false;

  UserProfile? _currentProfile;

  _SaveStatus _socialSaveStatus = _SaveStatus.idle;
  Timer? _socialDebounce;

  // Last saved text — listeners compare against these to ignore pure cursor moves.
  String _lastInstagram = '';
  String _lastFacebook = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // If the provider already has data when this widget is created (e.g. after
    // navigating away and back), ref.listen won't fire because the value didn't
    // change. Read it once after the first frame as a fallback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controllersInitialized) return;
      ref.read(profileProvider).whenData(_initControllers);
    });
  }

  @override
  void dispose() {
    _socialDebounce?.cancel();
    _instagramController.removeListener(_onSocialChanged);
    _facebookController.removeListener(_onSocialChanged);
    _tabController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _instagramFocusNode.dispose();
    _facebookFocusNode.dispose();
    super.dispose();
  }

  void _initControllers(UserProfile profile) {
    _currentProfile = profile;
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    _instagramController.text = profile.instagram ?? '';
    _facebookController.text = profile.facebook ?? '';
    _lastInstagram = _instagramController.text;
    _lastFacebook = _facebookController.text;
    _instagramController.addListener(_onSocialChanged);
    _facebookController.addListener(_onSocialChanged);
  }

  void _onSocialChanged() {
    if (_instagramController.text == _lastInstagram &&
        _facebookController.text == _lastFacebook) return;
    _lastInstagram = _instagramController.text;
    _lastFacebook = _facebookController.text;

    // Si ambos están vacíos no hay nada que guardar
    if (_instagramController.text.trim().isEmpty &&
        _facebookController.text.trim().isEmpty) {
      _socialDebounce?.cancel();
      setState(() => _socialSaveStatus = _SaveStatus.idle);
      return;
    }

    _socialDebounce?.cancel();
    if (_socialSaveStatus != _SaveStatus.saving) {
      setState(() => _socialSaveStatus = _SaveStatus.saving);
    }
    _socialDebounce = Timer(const Duration(milliseconds: 800), _saveSocial);
  }

  Future<void> _saveSocial() async {
    try {
      await ref.read(profileRepositoryProvider).updateSocial(
            instagram: _instagramController.text.trim().isEmpty
                ? null
                : _instagramController.text.trim(),
            facebook: _facebookController.text.trim().isEmpty
                ? null
                : _facebookController.text.trim(),
          );
      if (!mounted) return;
      // Refresh the provider so navigating back shows up-to-date data.
      ref.invalidate(profileProvider);
      setState(() => _socialSaveStatus = _SaveStatus.saved);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _socialSaveStatus = _SaveStatus.idle);
      });
    } catch (e) {
      if (mounted) setState(() => _socialSaveStatus = _SaveStatus.idle);
    }
  }

  void _showEditPersonalData(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPersonalDataSheet(profile: profile),
    );
  }

  void _showOpinions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OpinionsSheet(),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 800);
    if (file == null || !mounted) return;
    try {
      await ref.read(profileRepositoryProvider).uploadAvatar(file);
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la foto de perfil')),
        );
      }
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Foto de perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Elegir de la galería'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Tomar una foto'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBio(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditBioSheet(profile: profile),
    );
  }

  void _onCompletenessAction(ProfileCompletenessItem item) {
    final profile = _currentProfile;
    switch (item) {
      case ProfileCompletenessItem.avatar:
        _showAvatarOptions();
      case ProfileCompletenessItem.phone:
        _tabController.animateTo(1);
      case ProfileCompletenessItem.birthDate:
        if (profile != null) _showEditPersonalData(profile);
      case ProfileCompletenessItem.bio:
        if (profile != null) _showEditBio(profile);
      case ProfileCompletenessItem.instagram:
        _instagramFocusNode.requestFocus();
      case ProfileCompletenessItem.facebook:
        _facebookFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(roleProvider);
    final isDriver = role == '/driver';
    final profileAsync = ref.watch(profileProvider);

    // Pre-fill controllers when the profile loads for the first time.
    // The postFrameCallback in initState covers the case where the provider
    // already had data (navigating back), so this only fires on a fresh load.
    ref.listen<AsyncValue<UserProfile>>(profileProvider, (_, next) {
      next.whenData(_initControllers);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Información Personal'),
            Tab(text: 'Cuenta'),
          ],
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => TabBarView(
          controller: _tabController,
          children: [
            _InfoPersonalTab(
              isDriver: isDriver,
              profile: profile,
              phone: profile.phone,
              instagramController: _instagramController,
              facebookController: _facebookController,
              instagramFocusNode: _instagramFocusNode,
              facebookFocusNode: _facebookFocusNode,
              onEditPersonalData: () => _showEditPersonalData(profile),
              onAvatarTap: _showAvatarOptions,
              onCompletenessAction: _onCompletenessAction,
              socialSaveStatus: _socialSaveStatus,
              onGoToAccount: () => _tabController.animateTo(1),
            ),
            _CuentaTab(
              email: profile.email,
              phone: profile.phone,
              onOpinionsTap: _showOpinions,
              onLogout: () async {
                await PushNotificationService.deleteToken();
                await Supabase.instance.client.auth.signOut();
                // Reset all in-memory providers so the next user starts clean.
                ref.invalidate(profileProvider);
                ref.invalidate(unreadCountProvider);
                ref.invalidate(pendingRequestsCountProvider);
                ref.invalidate(pendingInvitationsCountProvider);
                ref.read(roleProvider.notifier).state = '/driver';
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Información Personal ───────────────────────────────────────────────

class _InfoPersonalTab extends StatelessWidget {
  const _InfoPersonalTab({
    required this.isDriver,
    required this.profile,
    required this.phone,
    required this.instagramController,
    required this.facebookController,
    required this.instagramFocusNode,
    required this.facebookFocusNode,
    required this.onEditPersonalData,
    required this.onAvatarTap,
    required this.onCompletenessAction,
    required this.socialSaveStatus,
    required this.onGoToAccount,
  });

  final bool isDriver;
  final UserProfile profile;
  final String? phone;
  final TextEditingController instagramController;
  final TextEditingController facebookController;
  final FocusNode instagramFocusNode;
  final FocusNode facebookFocusNode;
  final VoidCallback onEditPersonalData;
  final VoidCallback onAvatarTap;
  final void Function(ProfileCompletenessItem) onCompletenessAction;
  final _SaveStatus socialSaveStatus;
  final VoidCallback onGoToAccount;

  Widget _initialsCircle(UserProfile p) => CircleAvatar(
        radius: 48,
        backgroundColor: AppColors.primaryLight,
        child: Text(p.initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Hero ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 28, bottom: 8),
                    child: GestureDetector(
                      onTap: onAvatarTap,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFC7D2FE), width: 3),
                              boxShadow: [
                                BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: ClipOval(
                                child: profile.avatarUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: profile.avatarUrl!,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => _initialsCircle(profile),
                                        errorWidget: (_, __, ___) => _initialsCircle(profile),
                                      )
                                    : _initialsCircle(profile),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 28,
                    child: GestureDetector(
                      onTap: onEditPersonalData,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                            SizedBox(width: 5),
                            Text('Editar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Nombre, rating y nivel de confianza ───────────────────────
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Text(
                  profile.fullName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 17, color: Color(0xFFFACC15)),
                    const SizedBox(width: 4),
                    Text(
                      profile.avgRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Text(
                        isDriver ? 'Conductor' : 'Pasajero',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Trust level badge
                _TrustBadge(level: profile.trustLevel),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Stats ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFF5F7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                children: [
                  Expanded(child: _StatItem(
                    value: '${isDriver ? profile.tripsDriver : profile.tripsPassenger}',
                    label: isDriver ? 'Conducidos' : 'Realizados',
                    icon: isDriver ? Icons.directions_car_rounded : Icons.airline_seat_recline_normal_rounded,
                  )),
                  _StatDivider(),
                  Expanded(child: _StatItem(
                    value: '${profile.memberSince.year}',
                    label: 'Miembro desde',
                    icon: Icons.calendar_today_rounded,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Completeness card ─────────────────────────────────────────
          if (profile.completenessScore < 6)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _ProfileCompletenessCard(
                profile: profile,
                onAction: onCompletenessAction,
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Redes sociales ─────────────────────────────────────
                _ProfileSectionLabel(label: 'Redes sociales', trailing: _AutoSaveIndicator(socialSaveStatus)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      _SocialRow(controller: instagramController, focusNode: instagramFocusNode, hint: 'tu_usuario', icon: _InstagramIcon(), label: 'Instagram'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 1, thickness: 1, color: const Color(0xFFEEF2FF)),
                      ),
                      _SocialRow(controller: facebookController, focusNode: facebookFocusNode, hint: 'tu_usuario', icon: _FacebookIcon(), label: 'Facebook'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Vehículos ──────────────────────────────────────────
                const _VehiclesSection(),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trust badge ───────────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.level});
  final ProfileTrustLevel level;

  @override
  Widget build(BuildContext context) {
    final color = level.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            level.spanishName,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Nivel ${level.levelNumber}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completeness card ─────────────────────────────────────────────────────────

class _ProfileCompletenessCard extends StatefulWidget {
  const _ProfileCompletenessCard({required this.profile, required this.onAction});
  final UserProfile profile;
  final void Function(ProfileCompletenessItem) onAction;

  @override
  State<_ProfileCompletenessCard> createState() => _ProfileCompletenessCardState();
}

class _ProfileCompletenessCardState extends State<_ProfileCompletenessCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  late final AnimationController _animController;
  late final Animation<double> _arrowTurn;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _arrowTurn  = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _expandAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  String get _cardTitle {
    final s = widget.profile.completenessScore;
    if (s == 0) return 'Completá tu perfil para generar confianza';
    if (s <= 2) return 'Vas bien — seguí completando tu perfil';
    if (s <= 4) return 'Casi listo — te falta poco';
    return 'Un paso más para tener el perfil completo';
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.profile.completenessScore;
    final pct   = (score / 6 * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7D2FE)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tappable header ──────────────────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_rounded, size: 17, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _cardTitle,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$score/6 · $pct%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  RotationTransition(
                    turns: _arrowTurn,
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          // ── Progress bar (always visible) ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 6,
                minHeight: 6,
                backgroundColor: const Color(0xFFEEF2FF),
                valueColor: AlwaysStoppedAnimation<Color>(
                  score == 6 ? const Color(0xFF15803D) : AppColors.primary,
                ),
              ),
            ),
          ),
          // ── Expandable items list ────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFEEF2FF)),
                ...ProfileCompletenessItem.values.map((item) {
                  final done = widget.profile.itemDone(item);
                  return _CompletenessItemRow(
                    item: item,
                    done: done,
                    onTap: done ? null : () => widget.onAction(item),
                  );
                }),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletenessItemRow extends StatelessWidget {
  const _CompletenessItemRow({required this.item, required this.done, this.onTap});
  final ProfileCompletenessItem item;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: done ? const Color(0xFF15803D) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: done ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textSecondary,
                  ),
                ),
                if (!done)
                  Text(
                    item.subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (!done)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Completar →',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Edit Bio Sheet ────────────────────────────────────────────────────────────

class _EditBioSheet extends ConsumerStatefulWidget {
  const _EditBioSheet({required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<_EditBioSheet> createState() => _EditBioSheetState();
}

class _EditBioSheetState extends ConsumerState<_EditBioSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.profile.bioDriver?.isNotEmpty == true
        ? widget.profile.bioDriver!
        : (widget.profile.bioPassenger ?? '');
    _controller = TextEditingController(text: existing);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateBio(
            bioDriver: text.isEmpty ? null : text,
            bioPassenger: text.isEmpty ? null : text,
          );
      ref.invalidate(profileProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Tu descripción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text(
              'Contales a los demás quién sos. Aparece en tu perfil público.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _BioField(controller: _controller),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets del hero ──────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, required this.icon, this.iconColor, this.textColor});
  final String value;
  final String label;
  final IconData icon;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: textColor != null ? color.withValues(alpha: 0.7) : AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Bio Field ─────────────────────────────────────────────────────────────────

class _BioField extends StatefulWidget {
  const _BioField({required this.controller});
  final TextEditingController controller;

  @override
  State<_BioField> createState() => _BioFieldState();
}

class _BioFieldState extends State<_BioField> {
  bool _focused = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charCount = widget.controller.text.length;
    const maxChars = 300;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _focused
            ? [
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 4)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
              ]
            : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Acento lateral izquierdo
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _focused
                        ? [AppColors.primary, const Color(0xFF4FA3F7)]
                        : [const Color(0xFFD1DCF0), const Color(0xFFE2E8F3)],
                  ),
                ),
              ),
              // Contenido
              Expanded(
                child: Stack(
                  children: [
                    // Comilla decorativa de fondo
                    Positioned(
                      right: 10,
                      bottom: 28,
                      child: Text(
                        '\u201C',
                        style: TextStyle(
                          fontSize: 72,
                          height: 1,
                          color: AppColors.primary.withValues(alpha: _focused ? 0.06 : 0.03),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          minLines: 4,
                          maxLines: null,
                          maxLength: maxChars,
                          cursorColor: AppColors.primary,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.65),
                          decoration: InputDecoration(
                            hintText: 'Contá algo sobre vos...',
                            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.4), fontSize: 14, height: 1.65),
                            filled: true,
                            fillColor: Colors.transparent,
                            counterText: '',
                            contentPadding: const EdgeInsets.fromLTRB(14, 14, 44, 6),
                            enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 14, 10),
                          child: Text(
                            '$charCount/$maxChars',
                            style: TextStyle(
                              fontSize: 11,
                              color: charCount > maxChars * 0.85
                                  ? (charCount >= maxChars ? Colors.red : const Color(0xFFE67E22))
                                  : AppColors.textSecondary.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 48, color: AppColors.border);
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel({required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

// ── Tab 2: Cuenta ─────────────────────────────────────────────────────────────

class _CuentaTab extends StatefulWidget {
  const _CuentaTab({required this.email, required this.phone, required this.onOpinionsTap, required this.onLogout});
  final String email;
  final String? phone;
  final VoidCallback onOpinionsTap;
  final VoidCallback onLogout;

  @override
  State<_CuentaTab> createState() => _CuentaTabState();
}

class _CuentaTabState extends State<_CuentaTab> {

  void _showChangeEmail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangeEmailSheet(currentEmail: widget.email),
    );
  }

  void _showChangePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _showPhoneVerification() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhoneVerificationSheet(currentPhone: widget.phone),
    ).then((_) => setState(() {}));
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HelpSheet(),
    );
  }

  void _showRate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RateSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Verificación ──────────────────────────────────────────────
          if (widget.phone == null || widget.phone!.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Verificá tu teléfono para poder usar todas las funciones de la app.',
                      style: TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showPhoneVerification,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Verificar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Datos de cuenta ───────────────────────────────────────────
          const _SectionHeading('Datos de cuenta'),
          const SizedBox(height: 12),
          _AccountRow(
            icon: Icons.phone_rounded,
            label: 'Teléfono',
            value: widget.phone != null && widget.phone!.isNotEmpty
                ? widget.phone!
                : 'Sin verificar',
            valueColor: widget.phone == null || widget.phone!.isEmpty
                ? const Color(0xFFEF4444)
                : null,
            trailingIcon: widget.phone != null && widget.phone!.isNotEmpty
                ? Icons.check_circle_rounded
                : Icons.error_rounded,
            trailingIconColor: widget.phone != null && widget.phone!.isNotEmpty
                ? const Color(0xFF16A34A)
                : const Color(0xFFEF4444),
            onTap: _showPhoneVerification,
          ),
          const SizedBox(height: 8),
          _AccountRow(
            icon: Icons.mail_rounded,
            label: 'Email',
            value: widget.email,
            onTap: _showChangeEmail,
          ),
          const SizedBox(height: 8),
          _AccountRow(
            icon: Icons.lock_outline_rounded,
            label: 'Contraseña',
            value: '••••••••',
            onTap: _showChangePassword,
          ),
          const SizedBox(height: 8),
          _AccountRow(
            icon: Icons.home_outlined,
            label: 'Dirección postal',
            value: '',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dirección postal — próximamente disponible')),
            ),
          ),
          const SizedBox(height: 24),

          // ── Actividad ─────────────────────────────────────────────────
          const _SectionHeading('Actividad'),
          const SizedBox(height: 12),
          _AccountRow(
            icon: Icons.reviews_outlined,
            label: 'Opiniones',
            value: 'Recibidas y realizadas',
            onTap: widget.onOpinionsTap,
          ),
          const SizedBox(height: 24),

          // ── Soporte ───────────────────────────────────────────────────
          const _SectionHeading('Soporte'),
          const SizedBox(height: 12),
          _AccountRow(
            icon: Icons.star_rate_outlined,
            label: 'Valorar la app',
            value: '',
            onTap: _showRate,
          ),
          const SizedBox(height: 8),
          _AccountRow(
            icon: Icons.help_outline_rounded,
            label: 'Ayuda',
            value: '',
            onTap: _showHelp,
          ),
          const SizedBox(height: 32),

          // ── Cerrar sesión ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: widget.onLogout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                foregroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('Cerrar sesión'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Sheet: Cambiar email ───────────────────────────────────────────────────────

class _ChangeEmailSheet extends StatefulWidget {
  const _ChangeEmailSheet({required this.currentEmail});
  final String currentEmail;

  @override
  State<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<_ChangeEmailSheet> {
  late final _emailController = TextEditingController(text: widget.currentEmail);
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newEmail = _emailController.text.trim();
    if (newEmail == widget.currentEmail) { Navigator.pop(context); return; }
    if (!newEmail.contains('@')) {
      setState(() => _error = 'Ingresá un email válido');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(email: newEmail));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te enviamos un correo de confirmación al nuevo email')),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Error al actualizar el email'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Cambiar email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditField(label: 'Nuevo email', controller: _emailController, keyboardType: TextInputType.emailAddress),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Text(
            'Te enviaremos un correo de confirmación al nuevo email.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _SaveButton(loading: _loading, onPressed: _save),
        ],
      ),
    );
  }
}

// ── Sheet: Cambiar contraseña ─────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _newPassController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newPass = _newPassController.text;
    if (newPass.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (newPass != _confirmController.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPass));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Error al actualizar la contraseña'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Cambiar contraseña',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PasswordField(
            label: 'Nueva contraseña',
            controller: _newPassController,
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 14),
          _PasswordField(
            label: 'Confirmar contraseña',
            controller: _confirmController,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
          ],
          const SizedBox(height: 24),
          _SaveButton(loading: _loading, onPressed: _save),
        ],
      ),
    );
  }
}

// ── Sheet: Valorar la app ─────────────────────────────────────────────────────

class _RateSheet extends StatefulWidget {
  const _RateSheet();

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  int _stars = 0;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Valorar la app',
      child: _sent
          ? SizedBox(
              width: double.infinity,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 16),
                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 52),
                  SizedBox(height: 14),
                  Text('¡Gracias por tu opinión!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('Tu valoración nos ayuda a mejorar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  SizedBox(height: 28),
                ],
              ),
            )
          : Column(
              children: [
                const Text('¿Cómo calificarías tu experiencia con Viajemos?',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () => setState(() => _stars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                        color: i < _stars ? const Color(0xFFFACC15) : AppColors.border,
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _stars == 0 ? null : () {
                      setState(() => _sent = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (context.mounted) Navigator.pop(context);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Enviar valoración',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Sheet: Ayuda ──────────────────────────────────────────────────────────────

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Ayuda',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HelpItem(
            icon: Icons.mail_outline_rounded,
            title: 'Contactanos',
            subtitle: 'soporte@viajemos.app',
          ),
          const SizedBox(height: 12),
          _HelpItem(
            icon: Icons.security_rounded,
            title: 'Política de privacidad',
            subtitle: 'Cómo usamos tus datos',
          ),
          const SizedBox(height: 12),
          _HelpItem(
            icon: Icons.description_outlined,
            title: 'Términos y condiciones',
            subtitle: 'Condiciones de uso de la plataforma',
          ),
          const SizedBox(height: 12),
          _HelpItem(
            icon: Icons.info_outline_rounded,
            title: 'Versión',
            subtitle: '1.0.0 (beta)',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Widgets compartidos para sheets ───────────────────────────────────────────

class _BottomSheetWrapper extends StatelessWidget {
  const _BottomSheetWrapper({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.label, required this.controller, required this.obscure, required this.onToggle});
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.textSecondary),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Guardar cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}

// ── Sheet: Editar datos personales ────────────────────────────────────────────

class _EditPersonalDataSheet extends ConsumerStatefulWidget {
  const _EditPersonalDataSheet({required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<_EditPersonalDataSheet> createState() =>
      _EditPersonalDataSheetState();
}

class _EditPersonalDataSheetState
    extends ConsumerState<_EditPersonalDataSheet> {
  late final _firstNameController = TextEditingController(
      text: widget.profile.fullName.split(' ').first);
  late final _lastNameController = TextEditingController(
      text: widget.profile.fullName.contains(' ')
          ? widget.profile.fullName.split(' ').skip(1).join(' ')
          : '');
  late final _emailController =
      TextEditingController(text: widget.profile.email);
  late String _birthDate = _formatDate(widget.profile.birthDate);
  DateTime? _selectedBirthDate = null;

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final parsed = _birthDate.split('/');
    final initial = parsed.length == 3
        ? DateTime(int.parse(parsed[2]), int.parse(parsed[1]),
            int.parse(parsed[0]))
        : DateTime(now.year - 25);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 16),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDate = _formatDate(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Editar datos personales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EditField(
                      label: 'Nombre',
                      controller: _firstNameController),
                  const SizedBox(height: 14),
                  _EditField(
                      label: 'Apellido',
                      controller: _lastNameController),
                  const SizedBox(height: 14),

                  // Fecha de nacimiento
                  const Text('Fecha de nacimiento',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickBirthDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _birthDate.isEmpty
                                ? 'Seleccionar fecha'
                                : _birthDate,
                            style: TextStyle(
                              fontSize: 15,
                              color: _birthDate.isEmpty
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_month_rounded,
                              size: 18,
                              color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _EditField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final repo =
                            ref.read(profileRepositoryProvider);
                        await repo.updatePersonalData(
                          firstName:
                              _firstNameController.text.trim(),
                          lastName:
                              _lastNameController.text.trim(),
                          birthDate: _selectedBirthDate ??
                              widget.profile.birthDate,
                        );
                        ref.invalidate(profileProvider);
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Guardar cambios',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet: Opiniones ──────────────────────────────────────────────────────────

class _OpinionsSheet extends StatefulWidget {
  const _OpinionsSheet();

  @override
  State<_OpinionsSheet> createState() => _OpinionsSheetState();
}

class _OpinionsSheetState extends State<_OpinionsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Opiniones',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Recibidas'),
              Tab(text: 'Realizadas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _OpinionsEmptyState(
                  icon: Icons.inbox_rounded,
                  message: 'Todavía no recibiste opiniones.',
                ),
                _OpinionsEmptyState(
                  icon: Icons.rate_review_outlined,
                  message: 'Todavía no realizaste opiniones.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpinionsEmptyState extends StatelessWidget {
  const _OpinionsEmptyState(
      {required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor,
    this.trailingIcon,
    this.trailingIconColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? valueColor;
  final IconData? trailingIcon;
  final Color? trailingIconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(value,
                        style: TextStyle(
                            fontSize: 14,
                            color: valueColor ?? AppColors.textPrimary)),
                  ],
                ],
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: trailingIconColor, size: 20)
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.border, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SocialRow extends StatefulWidget {
  const _SocialRow({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.label,
    this.focusNode,
  });
  final TextEditingController controller;
  final String hint;
  final Widget icon;
  final String label;
  final FocusNode? focusNode;

  @override
  State<_SocialRow> createState() => _SocialRowState();
}

class _SocialRowState extends State<_SocialRow> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          widget.icon,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  cursorColor: AppColors.primary,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    prefixText: '@',
                    prefixStyle: TextStyle(
                      fontSize: 14,
                      color: hasText ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: widget.hint,
                    hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.4), fontSize: 14),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                    filled: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
  });
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

// ── Iconos de redes sociales ──────────────────────────────────────────────────

class _InstagramIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDD2A7B).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: FaIcon(FontAwesomeIcons.instagram, color: Colors.white, size: 18),
      ),
    );
  }
}

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1877F2).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: FaIcon(FontAwesomeIcons.facebookF, color: Colors.white, size: 17),
      ),
    );
  }
}

// ── Sección vehículos ─────────────────────────────────────────────────────────

class _VehiclesSection extends ConsumerWidget {
  const _VehiclesSection();

  Future<void> _openSelector(BuildContext context, WidgetRef ref) async {
    final input = await showModalBottomSheet<VehicleInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VehicleSelectorSheet(),
    );
    if (input == null || !context.mounted) return;
    try {
      await ref.read(vehiclesRepositoryProvider).addVehicle(
            brand: input.brand,
            model: input.model,
            color: input.color,
            colorHex: input.colorHex,
          );
      ref.invalidate(vehiclesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el vehículo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Mis autos'),
        const SizedBox(height: 10),
        vehiclesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: Colors.red)),
          data: (vehicles) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final v in vehicles) ...[
                _VehicleRow(vehicle: v),
                const Divider(height: 1, color: AppColors.border),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _openSelector(context, ref),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary, width: 2),
                      ),
                      child: const Icon(Icons.add,
                          size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    const Text('Agregar vehículo',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleRow extends ConsumerWidget {
  const _VehicleRow({required this.vehicle});
  final Vehicle vehicle;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final current = VehicleInput(
      brand: vehicle.brand,
      model: vehicle.model,
      color: vehicle.color,
      colorHex: vehicle.colorHex,
    );
    final input = await showModalBottomSheet<VehicleInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehicleSelectorSheet(current: current),
    );
    if (input == null || !context.mounted) return;
    try {
      await ref.read(vehiclesRepositoryProvider).updateVehicle(
            id: vehicle.id,
            brand: input.brand,
            model: input.model,
            color: input.color,
            colorHex: input.colorHex,
          );
      ref.invalidate(vehiclesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text(
            '¿Eliminás ${vehicle.brand} ${vehicle.model}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(vehiclesRepositoryProvider)
          .deleteVehicle(vehicle.id);
      ref.invalidate(vehiclesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _edit(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Color(vehicle.colorHex),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${vehicle.brand} ${vehicle.model}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(vehicle.color,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _delete(context, ref),
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Color(0xFFEF4444)),
              visualDensity: VisualDensity.compact,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}

// (Vehicle selector sheet moved to lib/shared/widgets/vehicle_selector_sheet.dart)

// ── Sheet: Verificación de teléfono ───────────────────────────────────────────

class _PhoneVerificationSheet extends ConsumerStatefulWidget {
  const _PhoneVerificationSheet({this.currentPhone});
  final String? currentPhone;

  @override
  ConsumerState<_PhoneVerificationSheet> createState() =>
      _PhoneVerificationSheetState();
}

class _PhoneVerificationSheetState
    extends ConsumerState<_PhoneVerificationSheet> {
  late final _phoneController =
      TextEditingController(text: widget.currentPhone ?? '');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Ingresá un número de teléfono');
      return;
    }
    if (phone.length < 8) {
      setState(() => _error = 'El número parece muy corto');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(profileRepositoryProvider).updatePhone(phone);
      ref.invalidate(profileProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Error al guardar el teléfono'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verificar teléfono',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ingresá tu número para que los pasajeros y conductores puedan contactarte.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            _EditField(
              label: 'Número de teléfono',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar teléfono', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
