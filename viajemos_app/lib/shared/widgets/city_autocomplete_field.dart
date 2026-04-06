import 'package:flutter/material.dart';
import '../services/city_search_service.dart';

class CityAutocompleteField extends StatefulWidget {
  const CityAutocompleteField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.iconColor = const Color(0xFF94A3B8),
    this.suffix,
    this.onSelected,
    this.focusNode,
    this.onTap,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final Widget? suffix;
  final ValueChanged<String>? onSelected;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField>
    with WidgetsBindingObserver {
  late final FocusNode _focusNode;
  bool _ownsNode = false;

  OverlayEntry? _overlay;
  List<CitySuggestion> _suggestions = [];
  bool _loading = false;

  final _fieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsNode = true;
    }
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    if (_ownsNode) _focusNode.dispose();
    CitySearchService.instance.cancel();
    _removeOverlay();
    super.dispose();
  }

  /// Called whenever screen metrics change (keyboard show/hide, rotation).
  /// Forces the overlay to recompute its position.
  @override
  void didChangeMetrics() {
    if (_overlay != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _overlay?.markNeedsBuild();
      });
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _removeOverlay();
      });
    }
  }

  void _onTextChanged() {
    final query = widget.controller.text;
    if (query.isEmpty) {
      CitySearchService.instance.cancel();
      _setSuggestions([]);
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    CitySearchService.instance.debounce(const Duration(milliseconds: 350),
        () async {
      if (!mounted) return;
      final results = await CitySearchService.instance.search(query);
      if (!mounted) return;
      setState(() => _loading = false);
      _setSuggestions(results);
    });
  }

  void _setSuggestions(List<CitySuggestion> suggestions) {
    _suggestions = suggestions;
    if (suggestions.isEmpty) {
      _removeOverlay();
    } else if (_focusNode.hasFocus) {
      _showOrUpdateOverlay();
    }
  }

  void _showOrUpdateOverlay() {
    if (_overlay != null) {
      _overlay!.markNeedsBuild();
      return;
    }
    _overlay = OverlayEntry(builder: (_) => _buildDropdown());
    Overlay.of(context).insert(_overlay!);
    // Re-measure after first frame so position is accurate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _overlay?.markNeedsBuild();
    });
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _select(CitySuggestion s) {
    widget.controller.removeListener(_onTextChanged);
    widget.controller.text = s.displayName;
    widget.controller.selection =
        TextSelection.collapsed(offset: s.displayName.length);
    widget.controller.addListener(_onTextChanged);
    widget.onSelected?.call(s.displayName);
    _suggestions = [];
    _removeOverlay();
    _focusNode.unfocus();
  }

  Widget _buildDropdown() {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const SizedBox.shrink();

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    return Positioned(
      left: offset.dx,
      top: offset.dy + size.height + 4,
      width: size.width,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        shadowColor: Colors.black26,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: _loading && _suggestions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF94A3B8)),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFF1F5F9)),
                  itemBuilder: (_, i) {
                    final s = _suggestions[i];
                    return InkWell(
                      onTap: () => _select(s),
                      borderRadius: BorderRadius.vertical(
                        top: i == 0
                            ? const Radius.circular(14)
                            : Radius.zero,
                        bottom: i == _suggestions.length - 1
                            ? const Radius.circular(14)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        child: Row(
                          children: [
                            const Icon(Icons.location_city_rounded,
                                size: 16, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B)),
                                  ),
                                  if (s.displayName != s.name)
                                    Text(
                                      s.displayName,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _fieldKey,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        textCapitalization: TextCapitalization.words,
        onTap: widget.onTap,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon, color: widget.iconColor, size: 20),
          suffixIcon: widget.suffix ??
              (_loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF94A3B8)),
                      ),
                    )
                  : null),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          hintStyle:
              const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
        ),
      ),
    );
  }
}
