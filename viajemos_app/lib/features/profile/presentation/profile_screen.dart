import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/role_provider.dart';

// ── Mock data ─────────────────────────────────────────────────────────────────

const _mockUser = (
  firstName: 'Juan',
  lastName: 'Pérez',
  email: 'juan.perez@email.com',
  phone: '+54 9 11 1234-5678',
  birthDate: '15/03/1995',
  postalAddress: 'Av. Corrientes 1234, CABA',
  memberSince: 2024,
  rating: 4.8,
  tripsDriver: 47,
  tripsPassenger: 23,
  verified: true,
  bioDriver:
      'Conductor con 5 años de experiencia. Viajo frecuentemente entre Buenos Aires y Córdoba.',
  bioPassenger:
      'Me gusta viajar y conocer gente nueva. Siempre puntual y respetuoso.',
);

// ── Car data ──────────────────────────────────────────────────────────────────

class _CarColor {
  const _CarColor(this.name, this.hex);
  final String name;
  final int hex;
}

class _Vehicle {
  const _Vehicle(
      {required this.brand,
      required this.model,
      required this.color,
      required this.colorHex});
  final String brand;
  final String model;
  final String color;
  final int colorHex;
}

const _carBrands = <String, List<String>>{
  'Toyota': ['Corolla', 'Hilux', 'Etios', 'Yaris', 'SW4', 'RAV4'],
  'Ford': ['Focus', 'EcoSport', 'Ranger', 'Ka', 'Fiesta', 'Territory'],
  'Volkswagen': ['Gol', 'Polo', 'Vento', 'Passat', 'Tiguan', 'T-Cross'],
  'Chevrolet': ['Cruze', 'Onix', 'Tracker', 'S10', 'Montana'],
  'Renault': ['Kwid', 'Sandero', 'Logan', 'Duster', 'Kangoo'],
  'Peugeot': ['208', '308', '408', '2008', '3008'],
  'Fiat': ['Palio', 'Siena', 'Cronos', 'Argo', 'Toro'],
  'Honda': ['Civic', 'City', 'HR-V', 'CR-V', 'Fit'],
  'Nissan': ['Versa', 'Sentra', 'Kicks', 'X-Trail', 'Frontier'],
  'Hyundai': ['i20', 'Tucson', 'Santa Fe', 'Creta', 'HB20'],
};

const _carColors = [
  _CarColor('Blanco', 0xFFFFFFFF),
  _CarColor('Negro', 0xFF1A1A1A),
  _CarColor('Gris', 0xFF6B7280),
  _CarColor('Plateado', 0xFFCBD5E1),
  _CarColor('Rojo', 0xFFDC2626),
  _CarColor('Azul', 0xFF1A73E8),
  _CarColor('Verde', 0xFF15803D),
  _CarColor('Amarillo', 0xFFEAB308),
  _CarColor('Naranja', 0xFFEA580C),
  _CarColor('Marrón', 0xFF92400E),
  _CarColor('Beige', 0xFFD4B896),
  _CarColor('Bordó', 0xFF881337),
  _CarColor('Celeste', 0xFF0EA5E9),
  _CarColor('Dorado', 0xFFD97706),
  _CarColor('Violeta', 0xFF7C3AED),
];

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  void _showEditPersonalData() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditPersonalDataSheet(),
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
    final initials =
        '${_mockUser.firstName[0]}${_mockUser.lastName[0]}';
    final totalTrips =
        isDriver ? _mockUser.tripsDriver : _mockUser.tripsPassenger;

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
      body: TabBarView(
        controller: _tabController,
        children: [
          _InfoPersonalTab(
            isDriver: isDriver,
            initials: initials,
            totalTrips: totalTrips,
            instagramController: _instagramController,
            facebookController: _facebookController,
            onEditPersonalData: _showEditPersonalData,
          ),
          _CuentaTab(
            onOpinionsTap: _showOpinions,
            onLogout: () => context.go('/'),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Información Personal ───────────────────────────────────────────────

class _InfoPersonalTab extends StatelessWidget {
  const _InfoPersonalTab({
    required this.isDriver,
    required this.initials,
    required this.totalTrips,
    required this.instagramController,
    required this.facebookController,
    required this.onEditPersonalData,
  });

  final bool isDriver;
  final String initials;
  final int totalTrips;
  final TextEditingController instagramController;
  final TextEditingController facebookController;
  final VoidCallback onEditPersonalData;

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
                    initials,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${_mockUser.firstName} ${_mockUser.lastName}',
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
                      _mockUser.rating.toString(),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($totalTrips viajes)',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (_mockUser.verified) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✓ Perfil verificado',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
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
                  value: '$totalTrips',
                  label: isDriver ? 'Viajes conducidos' : 'Viajes realizados',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_today_rounded,
                  value: '${_mockUser.memberSince}',
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.pageBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sobre mí',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isDriver
                      ? _mockUser.bioDriver
                      : _mockUser.bioPassenger,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Redes sociales ────────────────────────────────────────────
          const _SectionHeading('Redes sociales'),
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

          // ── Mis autos (solo conductor) ────────────────────────────────
          if (isDriver) ...[
            const _VehiclesSection(),
            const SizedBox(height: 20),
          ],

          // ── Verificación ──────────────────────────────────────────────
          const _SectionHeading('Verificación'),
          const SizedBox(height: 10),
          _mockUser.verified
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    border: Border.all(
                        color: const Color(0xFFBBF7D0), width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded,
                          color: AppColors.green, size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Identidad verificada',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.green)),
                            SizedBox(height: 2),
                            Text('Tu identidad fue confirmada correctamente.',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    border: Border.all(
                        color: const Color(0xFFFECACA), width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_rounded,
                          color: Color(0xFFDC2626), size: 28),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Identidad no verificada',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFDC2626))),
                            SizedBox(height: 2),
                            Text('Verificá tu identidad para generar confianza.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFDC2626))),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text('Verificar',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626))),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Tab 2: Cuenta ─────────────────────────────────────────────────────────────

class _CuentaTab extends StatelessWidget {
  const _CuentaTab(
      {required this.onOpinionsTap, required this.onLogout});

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
            value: _mockUser.email,
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
            value: _mockUser.postalAddress,
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

class _EditPersonalDataSheet extends StatefulWidget {
  const _EditPersonalDataSheet();

  @override
  State<_EditPersonalDataSheet> createState() =>
      _EditPersonalDataSheetState();
}

class _EditPersonalDataSheetState extends State<_EditPersonalDataSheet> {
  final _firstNameController =
      TextEditingController(text: _mockUser.firstName);
  final _lastNameController =
      TextEditingController(text: _mockUser.lastName);
  final _emailController =
      TextEditingController(text: _mockUser.email);
  final _phoneController =
      TextEditingController(text: _mockUser.phone);
  final _bioController =
      TextEditingController(text: _mockUser.bioDriver);
  String _birthDate = _mockUser.birthDate;

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
        _birthDate =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
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
                      onPressed: () => Navigator.pop(context),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          const Text('@',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.camera_alt_outlined,
          color: Colors.white, size: 20),
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
          ),
        ),
      ),
    );
  }
}

// ── Sección vehículos ─────────────────────────────────────────────────────────

class _VehiclesSection extends StatefulWidget {
  const _VehiclesSection();

  @override
  State<_VehiclesSection> createState() => _VehiclesSectionState();
}

class _VehiclesSectionState extends State<_VehiclesSection> {
  final List<_Vehicle> _vehicles = [];

  Future<void> _openSelector() async {
    final vehicle = await showModalBottomSheet<_Vehicle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VehicleSelectorSheet(),
    );
    if (vehicle != null) setState(() => _vehicles.add(vehicle));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('Mis autos'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: AppColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final v in _vehicles) ...[
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(v.colorHex),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.border),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${v.brand} ${v.model}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ),
                    Text(v.color,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
              ],
              GestureDetector(
                onTap: _openSelector,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          size: 18, color: Colors.white),
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

// ── Vehicle selector sheet ────────────────────────────────────────────────────

enum _VehicleStep { brand, model, color }

class _VehicleSelectorSheet extends StatefulWidget {
  const _VehicleSelectorSheet();

  @override
  State<_VehicleSelectorSheet> createState() =>
      _VehicleSelectorSheetState();
}

class _VehicleSelectorSheetState extends State<_VehicleSelectorSheet> {
  _VehicleStep _step = _VehicleStep.brand;
  String _selectedBrand = '';
  String _selectedModel = '';
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredBrands {
    final brands = _carBrands.keys.toList();
    if (_query.isEmpty) return brands;
    return brands
        .where((b) => b.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  List<String> get _filteredModels {
    final models = _carBrands[_selectedBrand] ?? [];
    if (_query.isEmpty) return models;
    return models
        .where((m) => m.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  void _selectBrand(String brand) => setState(() {
        _selectedBrand = brand;
        _step = _VehicleStep.model;
        _query = '';
        _searchController.clear();
      });

  void _selectModel(String model) => setState(() {
        _selectedModel = model;
        _step = _VehicleStep.color;
        _query = '';
        _searchController.clear();
      });

  void _selectColor(_CarColor color) => Navigator.of(context).pop(
        _Vehicle(
            brand: _selectedBrand,
            model: _selectedModel,
            color: color.name,
            colorHex: color.hex),
      );

  void _goBack() => setState(() {
        if (_step == _VehicleStep.color) {
          _step = _VehicleStep.model;
        } else {
          _step = _VehicleStep.brand;
          _selectedBrand = '';
        }
        _query = '';
        _searchController.clear();
      });

  String get _title => switch (_step) {
        _VehicleStep.brand => 'Seleccioná la marca',
        _VehicleStep.model => _selectedBrand,
        _VehicleStep.color => '$_selectedBrand $_selectedModel',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (_step != _VehicleStep.brand) ...[
                  GestureDetector(
                    onTap: _goBack,
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 18, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(_title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_step != _VehicleStep.color) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: Icon(Icons.search,
                        size: 20, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    hintStyle:
                        TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: _step == _VehicleStep.color
                ? _buildColorGrid()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final items = _step == _VehicleStep.brand
        ? _filteredBrands
        : _filteredModels;
    if (items.isEmpty) {
      return const Center(
          child: Text('Sin resultados',
              style:
                  TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 20,
          endIndent: 20,
          color: Color(0xFFF1F5F9)),
      itemBuilder: (_, i) => ListTile(
        title: Text(items[i],
            style: const TextStyle(
                fontSize: 15, color: Color(0xFF1E293B))),
        trailing: const Icon(Icons.chevron_right,
            color: Color(0xFFCBD5E1)),
        onTap: () => _step == _VehicleStep.brand
            ? _selectBrand(items[i])
            : _selectModel(items[i]),
      ),
    );
  }

  Widget _buildColorGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _carColors.length,
      itemBuilder: (_, i) {
        final c = _carColors[i];
        return GestureDetector(
          onTap: () => _selectColor(c),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Color(c.hex),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFE2E8F0), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(c.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF475569))),
            ],
          ),
        );
      },
    );
  }
}
