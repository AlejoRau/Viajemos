import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/formatters/date_formatter.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';

// ── Modelo de búsqueda reciente ───────────────────────────────────────────────

class _RecentSearch {
  const _RecentSearch({
    required this.origin,
    this.destination,
    this.dateFrom,
    this.dateTo,
    this.maxPrice,
  });
  final String origin;
  final String? destination;
  final String? dateFrom;
  final String? dateTo;
  final String? maxPrice;

  String get label => destination != null ? '$origin → $destination' : origin;
}

// Mock — reemplazar con datos reales de search_history en Supabase
final _mockRecentSearches = [
  const _RecentSearch(origin: 'Palermo', destination: 'La Plata', dateFrom: '15/04', dateTo: '16/04', maxPrice: '8000'),
  const _RecentSearch(origin: 'Rosario', destination: 'San Nicolás', dateFrom: '20/04', maxPrice: '5000'),
  const _RecentSearch(origin: 'Córdoba', destination: 'Buenos Aires'),
];

// ── Pantalla ──────────────────────────────────────────────────────────────────

class SearchTripsScreen extends StatelessWidget {
  const SearchTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: const Color(0xFF1E293B),
          onPressed: () => context.go('/passenger'),
        ),
        title: const Text(
          'Buscar Viaje',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: _FilterCard(),
      ),
    );
  }
}

// ── Tarjeta de filtros ────────────────────────────────────────────────────────

class _FilterCard extends StatefulWidget {
  const _FilterCard();

  @override
  State<_FilterCard> createState() => _FilterCardState();
}

class _FilterCardState extends State<_FilterCard> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  final _priceController = TextEditingController();
  final _originFocusNode = FocusNode();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _originFocusNode.addListener(() {
      if (!_originFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showHistory = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _priceController.dispose();
    _originFocusNode.dispose();
    super.dispose();
  }

  void _applyRecentSearch(_RecentSearch s) {
    setState(() {
      _fromController.text = s.origin;
      _toController.text = s.destination ?? '';
      _fromDateController.text = s.dateFrom ?? '';
      _toDateController.text = s.dateTo ?? '';
      _priceController.text = s.maxPrice ?? '';
      _showHistory = false;
    });
    _originFocusNode.unfocus();
  }

  void _swapOriginDestination() {
    setState(() {
      final tmp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ORIGEN
          _buildInputLabel('ORIGEN'),
          _buildOriginField(),
          if (_showHistory && _mockRecentSearches.isNotEmpty) _buildHistoryDropdown(),

          const SizedBox(height: 12),

          // DESTINO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInputLabel('DESTINO'),
              const Text('(Opcional)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
          _buildTextField('¿A dónde vas?', Icons.location_on, _toController),
          const SizedBox(height: 20),

          // Fechas
          Row(
            children: [
              Expanded(child: _buildDateInput('DESDE', _fromDateController)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateInput('HASTA', _toDateController)),
            ],
          ),
          const SizedBox(height: 20),

          // Precio
          _buildInputLabel('PRECIO MÁXIMO (ARS)'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Ej: 15000',
                prefixIcon: Icon(Icons.attach_money, color: Color(0xFF1A73E8), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Buscar
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                final origin = _fromController.text.trim();
                if (origin.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Ingresá al menos el origen')),
                  );
                  return;
                }
                context.push('/passenger/search-results', extra: {
                  'origin': origin,
                  'destination': _toController.text.trim().isEmpty
                      ? null
                      : _toController.text.trim(),
                  'dateFrom': _fromDateController.text.trim().isEmpty
                      ? null
                      : _fromDateController.text.trim(),
                  'dateTo': _toDateController.text.trim().isEmpty
                      ? null
                      : _toDateController.text.trim(),
                  'maxPrice': _priceController.text.trim().isEmpty
                      ? null
                      : _priceController.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: const Text(
                'Buscar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginField() {
    return CityAutocompleteField(
      controller: _fromController,
      focusNode: _originFocusNode,
      hint: '¿Desde dónde salís?',
      icon: Icons.search,
      iconColor: const Color(0xFF1A73E8),
      onTap: () => setState(() => _showHistory = true),
      suffix: GestureDetector(
        onTap: _swapOriginDestination,
        child: const Icon(Icons.swap_vert, color: Color(0xFF94A3B8), size: 20),
      ),
    );
  }

  Widget _buildHistoryDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < _mockRecentSearches.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
            InkWell(
              onTap: () => _applyRecentSearch(_mockRecentSearches[i]),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _mockRecentSearches[i].label,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (_mockRecentSearches[i].dateFrom != null)
                      Text(
                        _mockRecentSearches[i].dateFrom!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller) {
    return CityAutocompleteField(
      controller: controller,
      hint: hint,
      icon: icon,
      iconColor: const Color(0xFF1A73E8),
    );
  }

  Widget _buildDateInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [DayMonthFormatter()],
            decoration: const InputDecoration(
              hintText: 'DD/MM',
              suffixIcon: Icon(Icons.calendar_month, color: Color(0xFF64748B), size: 18),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
