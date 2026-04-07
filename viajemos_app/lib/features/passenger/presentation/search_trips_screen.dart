import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/formatters/date_formatter.dart';
import '../../../shared/services/city_search_service.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';

// ── Sanitización de inputs ────────────────────────────────────────────────────

// Permite letras (incluyendo acentos y ñ), espacios y guiones.
// Bloquea cualquier carácter que no tenga sentido en un nombre de ciudad.
final _cityInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚäëïöüÄËÏÖÜñÑüÜ ',\-\.]"),
);

String _sanitizeCity(String raw) =>
    raw.trim().replaceAll(RegExp(r'\s{2,}'), ' ').substring(
        0, raw.trim().length.clamp(0, 80));

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

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _swapOriginDestination() {
    setState(() {
      final tmp = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = tmp;
    });
  }

  void _onSearch() {
    final origin = _sanitizeCity(_fromController.text);
    if (origin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá al menos el origen')),
      );
      return;
    }

    final destination = _sanitizeCity(_toController.text);
    final dateFrom = _fromDateController.text.trim();
    final dateTo = _toDateController.text.trim();
    // Price is digits-only by formatter, still clamp to avoid absurd values.
    final rawPrice = int.tryParse(_priceController.text.trim()) ?? 0;
    final maxPrice = rawPrice.clamp(0, 9999999);

    context.push('/passenger/search-results', extra: {
      'origin': origin,
      'destination': destination.isEmpty ? null : destination,
      'dateFrom': dateFrom.isEmpty ? null : dateFrom,
      'dateTo': dateTo.isEmpty ? null : dateTo,
      'maxPrice': maxPrice == 0 ? null : maxPrice.toString(),
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

          const SizedBox(height: 12),

          // DESTINO
          _buildInputLabel('DESTINO'),
          _buildDestinationField(),
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              decoration: const InputDecoration(
                hintText: 'Ej: 15000  (opcional)',
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
              onPressed: _onSearch,
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
      hint: '¿Desde dónde salís?',
      icon: Icons.search,
      iconColor: const Color(0xFF1A73E8),
      defaultSuggestions: popularArgentineCities,
      citySearchSource: CitySearchSource.georef,
      inputFormatters: [_cityInputFormatter, LengthLimitingTextInputFormatter(80)],
      suffix: GestureDetector(
        onTap: _swapOriginDestination,
        child: const Icon(Icons.swap_vert, color: Color(0xFF94A3B8), size: 20),
      ),
    );
  }

  Widget _buildDestinationField() {
    return CityAutocompleteField(
      controller: _toController,
      hint: '¿A dónde vas?  (opcional)',
      icon: Icons.location_on,
      iconColor: const Color(0xFF1A73E8),
      defaultSuggestions: popularArgentineCities,
      citySearchSource: CitySearchSource.georef,
      inputFormatters: [_cityInputFormatter, LengthLimitingTextInputFormatter(80)],
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

  Widget _buildDateInput(String label, TextEditingController controller) {
    final isOptional = label == 'HASTA' || label == 'DESDE';
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
            decoration: InputDecoration(
              hintText: isOptional ? 'DD/MM  (opcional)' : 'DD/MM',
              suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF64748B), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
