import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/role_provider.dart';

// Mock data — reemplazar con datos de Supabase cuando esté listo
const _mockUser = (
  name: 'Juan Pérez',
  email: 'juan.perez@email.com',
  phone: '+54 9 11 1234-5678',
  memberSince: 2024,
  rating: 4.8,
  tripsDriver: 47,
  tripsPassenger: 23,
  verified: true,
  bioDriver:
      'Conductor con 5 años de experiencia. Viajo frecuentemente entre Buenos Aires y Córdoba.',
  bioPassenger: 'Me gusta viajar y conocer gente nueva. Siempre puntual y respetuoso.',
);

// ── Datos de vehículos ────────────────────────────────────────────────────────

class _CarColor {
  const _CarColor(this.name, this.hex);
  final String name;
  final int hex;
}

class _Vehicle {
  const _Vehicle({required this.brand, required this.model, required this.color, required this.colorHex});
  final String brand;
  final String model;
  final String color;
  final int colorHex;
}

const _carBrands = <String, List<String>>{
  'Toyota':        ['Corolla', 'Hilux', 'Etios', 'Yaris', 'SW4', 'RAV4', 'Land Cruiser', 'Camry', 'GR86'],
  'Ford':          ['Focus', 'EcoSport', 'Ranger', 'Ka', 'Fiesta', 'Territory', 'Maverick', 'F-150'],
  'Volkswagen':    ['Gol', 'Polo', 'Vento', 'Passat', 'Tiguan', 'T-Cross', 'Amarok', 'Golf', 'Taos'],
  'Chevrolet':     ['Cruze', 'Onix', 'Tracker', 'S10', 'Montana', 'Agile'],
  'Renault':       ['Kwid', 'Sandero', 'Logan', 'Duster', 'Kangoo', 'Symbol', 'Captur', 'Stepway'],
  'Peugeot':       ['208', '308', '408', '2008', '3008', '5008', 'Partner', 'Rifter'],
  'Fiat':          ['Palio', 'Siena', 'Cronos', 'Argo', 'Toro', 'Strada', 'Mobi'],
  'Honda':         ['Civic', 'City', 'HR-V', 'CR-V', 'Fit', 'WR-V'],
  'Nissan':        ['Versa', 'Sentra', 'Kicks', 'X-Trail', 'Frontier', 'March'],
  'Hyundai':       ['i20', 'Tucson', 'Santa Fe', 'Creta', 'HB20', 'Elantra'],
  'Kia':           ['Rio', 'Cerato', 'Sportage', 'Sorento', 'Seltos', 'Stinger'],
  'Citroën':       ['C3', 'C4', 'C5 X', 'Berlingo', 'C-Elysée'],
  'Mercedes-Benz': ['Clase A', 'Clase C', 'GLA', 'GLC', 'Sprinter'],
  'BMW':           ['Serie 1', 'Serie 3', 'X1', 'X3', 'X5'],
  'Audi':          ['A3', 'A4', 'Q3', 'Q5', 'Q7'],
  'Jeep':          ['Renegade', 'Compass', 'Cherokee', 'Wrangler', 'Grand Cherokee'],
  'Mitsubishi':    ['L200', 'ASX', 'Outlander', 'Eclipse Cross'],
  'Suzuki':        ['Swift', 'Vitara', 'S-Cross', 'Jimny'],
  'Subaru':        ['Impreza', 'Forester', 'Outback', 'XV'],
  'Ram':           ['700', '1500', '2500'],
};

const _carColors = [
  _CarColor('Blanco',    0xFFFFFFFF),
  _CarColor('Negro',     0xFF1A1A1A),
  _CarColor('Gris',      0xFF6B7280),
  _CarColor('Plateado',  0xFFCBD5E1),
  _CarColor('Rojo',      0xFFDC2626),
  _CarColor('Azul',      0xFF1A73E8),
  _CarColor('Verde',     0xFF15803D),
  _CarColor('Amarillo',  0xFFEAB308),
  _CarColor('Naranja',   0xFFEA580C),
  _CarColor('Marrón',    0xFF92400E),
  _CarColor('Beige',     0xFFD4B896),
  _CarColor('Bordó',     0xFF881337),
  _CarColor('Celeste',   0xFF0EA5E9),
  _CarColor('Dorado',    0xFFD97706),
  _CarColor('Violeta',   0xFF7C3AED),
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider); // '/driver' | '/passenger'
    final isDriver = role == '/driver';
    final initials = _mockUser.name
        .split(' ')
        .map((w) => w[0])
        .take(2)
        .join();
    final totalTrips = isDriver ? _mockUser.tripsDriver : _mockUser.tripsPassenger;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar & datos básicos ──────────────────────────────
            Center(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
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
                      Positioned(
                        bottom: 0,
                        right: -4,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.edit, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _mockUser.name,
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
                      const Icon(Icons.star_rounded, size: 22, color: Color(0xFFFACC15)),
                      const SizedBox(width: 4),
                      Text(
                        _mockUser.rating.toString(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($totalTrips viajes)',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (_mockUser.verified) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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

            // ── Stats ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: isDriver ? Icons.directions_car_rounded : Icons.airline_seat_recline_normal_rounded,
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

            // ── Sobre mí ────────────────────────────────────────────
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
                  Row(
                    children: [
                      const Text(
                        'Sobre mí',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Editar',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDriver ? _mockUser.bioDriver : _mockUser.bioPassenger,
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

            // ── Información de contacto ─────────────────────────────
            const _SectionHeading('Información de contacto'),
            const SizedBox(height: 10),
            _ContactRow(
              icon: Icons.mail_rounded,
              label: 'Email',
              value: _mockUser.email,
            ),
            const SizedBox(height: 10),
            _ContactRow(
              icon: Icons.phone_rounded,
              label: 'Teléfono',
              value: _mockUser.phone,
            ),
            const SizedBox(height: 20),

            // ── Mis autos ────────────────────────────────────────
            const _VehiclesSection(),
            const SizedBox(height: 20),

            // ── Verificación ────────────────────────────────────────
            const _SectionHeading('Verificación'),
            const SizedBox(height: 10),
            _mockUser.verified
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
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
                              Text(
                                'Identidad verificada',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.green,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tu identidad fue confirmada correctamente.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.green,
                                ),
                              ),
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
                      border:
                          Border.all(color: const Color(0xFFFECACA), width: 1.5),
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
                              Text(
                                'Todavía no tenés tu identidad verificada',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Verificá tu identidad para generar más confianza.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Verificar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 28),

            // ── Cerrar sesión ───────────────────────────────────────
            OutlinedButton(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: Color(0xFFEF4444), width: 2),
                foregroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('Cerrar sesión'),
            ),
            const SizedBox(height: 32),
          ],
        ),
        ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

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
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

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
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Sección Mis autos ─────────────────────────────────────────────────────────

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
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${v.brand} ${v.model}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    Text(v.color, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
                      child: const Icon(Icons.add, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Agregar vehículo',
                      style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
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

// ── Bottom sheet selector de vehículo ─────────────────────────────────────────

enum _VehicleStep { brand, model, color }

class _VehicleSelectorSheet extends StatefulWidget {
  const _VehicleSelectorSheet();

  @override
  State<_VehicleSelectorSheet> createState() => _VehicleSelectorSheetState();
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
    return brands.where((b) => b.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  List<String> get _filteredModels {
    final models = _carBrands[_selectedBrand] ?? [];
    if (_query.isEmpty) return models;
    return models.where((m) => m.toLowerCase().contains(_query.toLowerCase())).toList();
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
    _Vehicle(brand: _selectedBrand, model: _selectedModel, color: color.name, colorHex: color.hex),
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
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
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
                    child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(_title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_step != _VehicleStep.color) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: _step == _VehicleStep.color ? _buildColorGrid() : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final items = _step == _VehicleStep.brand ? _filteredBrands : _filteredModels;
    if (items.isEmpty) {
      return const Center(child: Text('Sin resultados', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
      itemBuilder: (_, i) => ListTile(
        title: Text(items[i], style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
        onTap: () => _step == _VehicleStep.brand ? _selectBrand(items[i]) : _selectModel(items[i]),
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
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Color(c.hex),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))],
                ),
              ),
              const SizedBox(height: 6),
              Text(c.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
            ],
          ),
        );
      },
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Editar',
              style: TextStyle(fontSize: 13, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
