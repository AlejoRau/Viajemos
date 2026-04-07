import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/role_provider.dart';
import '../data/profile_provider.dart';
import '../domain/user_profile.dart';
import '../../../features/vehicles/data/vehicles_provider.dart';
import '../../../features/vehicles/domain/vehicle.dart';
import '../../../shared/widgets/vehicle_selector_sheet.dart';

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
  final _bioDriverController = TextEditingController();
  final _bioPassengerController = TextEditingController();
  bool _controllersInitialized = false;

  _SaveStatus _bioSaveStatus = _SaveStatus.idle;
  _SaveStatus _socialSaveStatus = _SaveStatus.idle;
  Timer? _bioDebounce;
  Timer? _socialDebounce;

  // Last saved text — listeners compare against these to ignore pure cursor moves.
  String _lastBioDriver = '';
  String _lastBioPassenger = '';
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
    _bioDebounce?.cancel();
    _socialDebounce?.cancel();
    _bioDriverController.removeListener(_onBioChanged);
    _bioPassengerController.removeListener(_onBioChanged);
    _instagramController.removeListener(_onSocialChanged);
    _facebookController.removeListener(_onSocialChanged);
    _tabController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _bioDriverController.dispose();
    _bioPassengerController.dispose();
    super.dispose();
  }

  void _initControllers(UserProfile profile) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    _bioDriverController.text = profile.bioDriver ?? '';
    _bioPassengerController.text = profile.bioPassenger ?? '';
    _instagramController.text = profile.instagram ?? '';
    _facebookController.text = profile.facebook ?? '';
    // Mirror initial values so listeners can detect real edits vs cursor moves.
    _lastBioDriver = _bioDriverController.text;
    _lastBioPassenger = _bioPassengerController.text;
    _lastInstagram = _instagramController.text;
    _lastFacebook = _facebookController.text;
    // Add listeners AFTER setting initial values.
    _bioDriverController.addListener(_onBioChanged);
    _bioPassengerController.addListener(_onBioChanged);
    _instagramController.addListener(_onSocialChanged);
    _facebookController.addListener(_onSocialChanged);
  }

  void _onBioChanged() {
    // Ignore cursor/selection changes — only act on actual text edits.
    if (_bioDriverController.text == _lastBioDriver &&
        _bioPassengerController.text == _lastBioPassenger) return;
    _lastBioDriver = _bioDriverController.text;
    _lastBioPassenger = _bioPassengerController.text;

    _bioDebounce?.cancel();
    if (_bioSaveStatus != _SaveStatus.saving) {
      setState(() => _bioSaveStatus = _SaveStatus.saving);
    }
    _bioDebounce = Timer(const Duration(milliseconds: 800), _saveBio);
  }

  void _onSocialChanged() {
    // Ignore cursor/selection changes — only act on actual text edits.
    if (_instagramController.text == _lastInstagram &&
        _facebookController.text == _lastFacebook) return;
    _lastInstagram = _instagramController.text;
    _lastFacebook = _facebookController.text;

    _socialDebounce?.cancel();
    if (_socialSaveStatus != _SaveStatus.saving) {
      setState(() => _socialSaveStatus = _SaveStatus.saving);
    }
    _socialDebounce = Timer(const Duration(milliseconds: 800), _saveSocial);
  }

  Future<void> _saveBio() async {
    try {
      await ref.read(profileRepositoryProvider).updateBio(
            bioDriver: _bioDriverController.text.trim().isEmpty
                ? null
                : _bioDriverController.text.trim(),
            bioPassenger: _bioPassengerController.text.trim().isEmpty
                ? null
                : _bioPassengerController.text.trim(),
          );
      if (!mounted) return;
      // Refresh the provider so navigating back shows up-to-date data.
      ref.invalidate(profileProvider);
      setState(() => _bioSaveStatus = _SaveStatus.saved);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _bioSaveStatus = _SaveStatus.idle);
      });
    } catch (e) {
      if (mounted) setState(() => _bioSaveStatus = _SaveStatus.idle);
    }
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
              instagramController: _instagramController,
              facebookController: _facebookController,
              bioController:
                  isDriver ? _bioDriverController : _bioPassengerController,
              onEditPersonalData: () => _showEditPersonalData(profile),
              bioSaveStatus: _bioSaveStatus,
              socialSaveStatus: _socialSaveStatus,
            ),
            _CuentaTab(
              email: profile.email,
              onOpinionsTap: _showOpinions,
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
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
    required this.instagramController,
    required this.facebookController,
    required this.bioController,
    required this.onEditPersonalData,
    required this.bioSaveStatus,
    required this.socialSaveStatus,
  });

  final bool isDriver;
  final UserProfile profile;
  final TextEditingController instagramController;
  final TextEditingController facebookController;
  final TextEditingController bioController;
  final VoidCallback onEditPersonalData;
  final _SaveStatus bioSaveStatus;
  final _SaveStatus socialSaveStatus;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    profile.initials,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 22, color: Color(0xFFFACC15)),
                    const SizedBox(width: 4),
                    Text(
                      profile.avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${isDriver ? profile.tripsDriver : profile.tripsPassenger} viajes)',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Stats ─────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: isDriver
                      ? Icons.directions_car_rounded
                      : Icons.airline_seat_recline_normal_rounded,
                  value:
                      '${isDriver ? profile.tripsDriver : profile.tripsPassenger}',
                  label: isDriver ? 'Viajes conducidos' : 'Viajes realizados',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_today_rounded,
                  value: '${profile.memberSince.year}',
                  label: 'Miembro desde',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Botones de edición ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onEditPersonalData,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Editar datos personales'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
              label: const Text('Editar foto de perfil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(
                    color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Sobre mí ──────────────────────────────────────────────────
          Row(
            children: [
              const _SectionHeading('Sobre mí'),
              const SizedBox(width: 8),
              _AutoSaveIndicator(bioSaveStatus),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 130),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.pageBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: bioController,
              minLines: 4,
              maxLines: null,
              cursorColor: AppColors.textPrimary,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Contá algo sobre vos...',
                hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Redes sociales ────────────────────────────────────────────
          Row(
            children: [
              const _SectionHeading('Redes sociales'),
              const SizedBox(width: 8),
              _AutoSaveIndicator(socialSaveStatus),
            ],
          ),
          const SizedBox(height: 12),
          _SocialRow(
            controller: instagramController,
            hint: 'tu_usuario',
            icon: _InstagramIcon(),
            label: 'Instagram',
          ),
          const SizedBox(height: 10),
          _SocialRow(
            controller: facebookController,
            hint: 'tu_usuario',
            icon: _FacebookIcon(),
            label: 'Facebook',
          ),
          const SizedBox(height: 20),

          // ── Autos ─────────────────────────────────────────────────────
          const _VehiclesSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Tab 2: Cuenta ─────────────────────────────────────────────────────────────

class _CuentaTab extends StatelessWidget {
  const _CuentaTab(
      {required this.email, required this.onOpinionsTap, required this.onLogout});

  final String email;
  final VoidCallback onOpinionsTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Datos de cuenta ───────────────────────────────────────────
          const _SectionHeading('Datos de cuenta'),
          const SizedBox(height: 12),
          _AccountRow(
            icon: Icons.mail_rounded,
            label: 'Email',
            value: email,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _AccountRow(
            icon: Icons.lock_outline_rounded,
            label: 'Contraseña',
            value: '••••••••',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _AccountRow(
            icon: Icons.home_outlined,
            label: 'Dirección postal',
            value: '',
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // ── Actividad ─────────────────────────────────────────────────
          const _SectionHeading('Actividad'),
          const SizedBox(height: 12),
          _AccountRow(
            icon: Icons.reviews_outlined,
            label: 'Opiniones',
            value: 'Recibidas y realizadas',
            onTap: onOpinionsTap,
          ),
          const SizedBox(height: 24),

          // ── Soporte ───────────────────────────────────────────────────
          const _SectionHeading('Soporte'),
          const SizedBox(height: 12),
          _AccountRow(
            icon: Icons.star_rate_outlined,
            label: 'Valorar la app',
            value: '',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _AccountRow(
            icon: Icons.help_outline_rounded,
            label: 'Ayuda',
            value: '',
            onTap: () {},
          ),
          const SizedBox(height: 32),

          // ── Cerrar sesión ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                foregroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
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
  late final _phoneController =
      TextEditingController(text: widget.profile.phone ?? '');
  final _bioController = TextEditingController();
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
    _phoneController.dispose();
    _bioController.dispose();
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
                  const SizedBox(height: 14),
                  _EditField(
                      label: 'Teléfono',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  _EditField(
                    label: 'Biografía',
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 300,
                  ),
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
                          phone: _phoneController.text.trim(),
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
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

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
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.border, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.label,
  });
  final TextEditingController controller;
  final String hint;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 14),
          const Text('@',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
          const SizedBox(width: 2),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: AppColors.textPrimary,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 15),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(top: 2),
                filled: false,
              ),
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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFEDA77),
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
            Color(0xFF515BD4),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: FaIcon(
          FontAwesomeIcons.instagram,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: FaIcon(
          FontAwesomeIcons.facebookF,
          color: Colors.white,
          size: 20,
        ),
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
