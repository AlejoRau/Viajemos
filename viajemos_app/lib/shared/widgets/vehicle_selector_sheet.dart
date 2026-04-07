import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ── Data ─────────────────────────────────────────────────────────────────────

class CarColorOption {
  const CarColorOption(this.name, this.hex);
  final String name;
  final int hex;
}

/// Lightweight struct returned by the sheet before the vehicle is persisted.
class VehicleInput {
  const VehicleInput({
    required this.brand,
    required this.model,
    required this.color,
    required this.colorHex,
  });
  final String brand;
  final String model;
  final String color;
  final int colorHex;
}

const kCarBrands = <String, List<String>>{
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

const kCarColors = <CarColorOption>[
  CarColorOption('Blanco', 0xFFFFFFFF),
  CarColorOption('Negro', 0xFF1A1A1A),
  CarColorOption('Gris', 0xFF6B7280),
  CarColorOption('Plateado', 0xFFCBD5E1),
  CarColorOption('Rojo', 0xFFDC2626),
  CarColorOption('Azul', 0xFF1A73E8),
  CarColorOption('Verde', 0xFF15803D),
  CarColorOption('Amarillo', 0xFFEAB308),
  CarColorOption('Naranja', 0xFFEA580C),
  CarColorOption('Marrón', 0xFF92400E),
  CarColorOption('Beige', 0xFFD4B896),
  CarColorOption('Bordó', 0xFF881337),
  CarColorOption('Celeste', 0xFF0EA5E9),
  CarColorOption('Dorado', 0xFFD97706),
  CarColorOption('Violeta', 0xFF7C3AED),
];

// ── Sheet ─────────────────────────────────────────────────────────────────────

enum _VehicleStep { brand, model, color }

class VehicleSelectorSheet extends StatefulWidget {
  /// Pass [current] when editing an existing vehicle so it shows at the top.
  const VehicleSelectorSheet({super.key, this.current});
  final VehicleInput? current;

  @override
  State<VehicleSelectorSheet> createState() => _VehicleSelectorSheetState();
}

class _VehicleSelectorSheetState extends State<VehicleSelectorSheet> {
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
    final brands = kCarBrands.keys.toList();
    if (_query.isEmpty) return brands;
    return brands
        .where((b) => b.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  List<String> get _filteredModels {
    final models = kCarBrands[_selectedBrand] ?? [];
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

  void _selectColor(CarColorOption color) => Navigator.of(context).pop(
        VehicleInput(
          brand: _selectedBrand,
          model: _selectedModel,
          color: color.name,
          colorHex: color.hex,
        ),
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
                borderRadius: BorderRadius.circular(2),
              ),
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
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon:
                        Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    hintStyle: TextStyle(color: Color(0xFF94A3B8)),
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
    final isBrand = _step == _VehicleStep.brand;
    final allItems = isBrand ? _filteredBrands : _filteredModels;
    final currentValue = isBrand
        ? widget.current?.brand
        : widget.current?.model;

    // Put the current selection at the top (only when not filtering)
    List<String> items;
    if (_query.isEmpty && currentValue != null && allItems.contains(currentValue)) {
      items = [
        currentValue,
        ...allItems.where((e) => e != currentValue),
      ];
    } else {
      items = allItems;
    }

    if (items.isEmpty) {
      return const Center(
        child: Text('Sin resultados',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(
          height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
      itemBuilder: (_, i) {
        final item = items[i];
        final isSelected = item == currentValue && _query.isEmpty;
        return ListTile(
          tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
          shape: i == 0 && isSelected
              ? const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)))
              : null,
          title: Text(
            item,
            style: TextStyle(
              fontSize: 15,
              color: isSelected
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF1E293B),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF1D4ED8), size: 20)
              : const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
          onTap: () => isBrand ? _selectBrand(item) : _selectModel(item),
        );
      },
    );
  }

  Widget _buildColorGrid() {
    final currentColorName = widget.current?.color;

    // Put selected color first
    List<CarColorOption> colors;
    if (currentColorName != null) {
      final current = kCarColors.firstWhere(
        (c) => c.name == currentColorName,
        orElse: () => kCarColors.first,
      );
      colors = [current, ...kCarColors.where((c) => c.name != currentColorName)];
    } else {
      colors = kCarColors;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: colors.length,
      itemBuilder: (_, i) {
        final c = colors[i];
        final isSelected = c.name == currentColorName;
        return GestureDetector(
          onTap: () => _selectColor(c),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Color(c.hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_rounded,
                        color: Colors.white, size: 22),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                c.name,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF475569),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
