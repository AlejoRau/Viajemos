import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/services/city_search_service.dart';
import '../../../shared/widgets/city_autocomplete_field.dart';

// Permite letras (incluyendo acentos y ñ), espacios y guiones.
final _cityInputFormatter = FilteringTextInputFormatter.allow(
  RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚäëïöüÄËÏÖÜñÑüÜ ',\-\.]"),
);

String _sanitizeCity(String raw) =>
    raw.trim().replaceAll(RegExp(r'\s{2,}'), ' ').substring(
        0, raw.trim().length.clamp(0, 80));

// ── Pantalla ──────────────────────────────────────────────────────────────────

class SearchTripsScreen extends StatelessWidget {
  const SearchTripsScreen({
    super.key,
    this.prefillOrigin,
    this.prefillDestination,
    this.prefillMaxPrice,
  });

  final String? prefillOrigin;
  final String? prefillDestination;
  final String? prefillMaxPrice;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _FilterCard(
          prefillOrigin: prefillOrigin,
          prefillDestination: prefillDestination,
          prefillMaxPrice: prefillMaxPrice,
        ),
      ),
    );
  }
}

// ── Tarjeta de filtros ────────────────────────────────────────────────────────

class _FilterCard extends StatefulWidget {
  const _FilterCard({
    this.prefillOrigin,
    this.prefillDestination,
    this.prefillMaxPrice,
  });

  final String? prefillOrigin;
  final String? prefillDestination;
  final String? prefillMaxPrice;

  @override
  State<_FilterCard> createState() => _FilterCardState();
}

class _FilterCardState extends State<_FilterCard> {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _priceController;

  DateTime? _fromDate;

  bool _onlyPets = false;
  bool _picksUp = false;
  bool _dropsOff = false;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.prefillOrigin ?? '');
    _toController = TextEditingController(text: widget.prefillDestination ?? '');
    _priceController = TextEditingController(text: widget.prefillMaxPrice ?? '');
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _fromDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Buscar a partir de',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
    );
    if (picked == null) return;
    setState(() => _fromDate = picked);
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
    final dateFrom = _fromDate != null ? _formatDate(_fromDate!) : null;
    final rawPrice = int.tryParse(_priceController.text.trim()) ?? 0;
    final maxPrice = rawPrice.clamp(0, 9999999);

    context.push('/passenger/search-results', extra: {
      'origin': origin,
      'destination': destination.isEmpty ? null : destination,
      'dateFrom': dateFrom,
      'maxPrice': maxPrice == 0 ? null : maxPrice.toString(),
      'onlyPets': _onlyPets,
      'picksUp': _picksUp,
      'dropsOff': _dropsOff,
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

          // Fecha a partir de
          _buildDateInput('A PARTIR DE', _fromDate),
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
          const SizedBox(height: 20),

          // Filtros previos a buscar
          _buildInputLabel('FILTROS'),
          Row(
            children: [
              Expanded(child: _buildToggle(
                'Mascotas',
                Icons.pets_rounded,
                _onlyPets,
                (v) => setState(() => _onlyPets = v),
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildToggle(
                'Pasa a buscarte',
                Icons.home_rounded,
                _picksUp,
                (v) => setState(() => _picksUp = v),
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildToggle(
                'Te deja en destino',
                Icons.where_to_vote_rounded,
                _dropsOff,
                (v) => setState(() => _dropsOff = v),
              )),
            ],
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

  Widget _buildDateInput(String label, DateTime? date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF64748B), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? _formatDate(date) : 'Cualquier fecha  (opcional)',
                    style: TextStyle(
                      fontSize: 13,
                      color: date != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                if (date != null)
                  GestureDetector(
                    onTap: () => setState(() => _fromDate = null),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(String label, IconData icon, bool active, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A73E8) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF1A73E8) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: active ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
