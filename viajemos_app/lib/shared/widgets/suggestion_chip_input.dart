import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SuggestionChipInput extends StatefulWidget {
  const SuggestionChipInput({
    super.key,
    required this.label,
    required this.hint,
    required this.chips,
    required this.onAdd,
    required this.onRemove,
    this.suggestions = const [],
    this.asyncSearch,
    this.prefixIcon = Icons.add_road_rounded,
  });

  final String label;
  final String hint;
  /// Static suggestions filtered locally (used when [asyncSearch] is null).
  final List<String> suggestions;
  /// Async search function. When provided, replaces static filtering.
  /// Receives the typed query and returns matching strings.
  final Future<List<String>> Function(String query)? asyncSearch;
  final List<String> chips;
  final void Function(String value) onAdd;
  final void Function(int index) onRemove;
  final IconData prefixIcon;

  @override
  State<SuggestionChipInput> createState() => _SuggestionChipInputState();
}

class _SuggestionChipInputState extends State<SuggestionChipInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _filtered = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Small delay so tapping a suggestion registers before dismissing.
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _filtered = []);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      _debounce?.cancel();
      setState(() {
        _filtered = [];
        _loading = false;
      });
      return;
    }

    if (widget.asyncSearch != null) {
      setState(() => _loading = true);
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), () async {
        if (!mounted) return;
        final results = await widget.asyncSearch!(query);
        if (!mounted) return;
        setState(() {
          _loading = false;
          _filtered = results
              .where((s) => !widget.chips.contains(s))
              .take(6)
              .toList();
        });
      });
    } else {
      final q = query.toLowerCase();
      setState(() {
        _filtered = widget.suggestions
            .where(
                (s) => s.toLowerCase().contains(q) && !widget.chips.contains(s))
            .take(5)
            .toList();
      });
    }
  }

  void _select(String value) {
    widget.onAdd(value);
    _controller.clear();
    setState(() {
      _filtered = [];
      _loading = false;
    });
    _debounce?.cancel();
    _focusNode.requestFocus();
  }

  void _submitManual() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onAdd(text);
      _controller.clear();
      setState(() {
        _filtered = [];
        _loading = false;
      });
      _debounce?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDropdown = _loading || _filtered.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          onFieldSubmitted: (_) => _submitManual(),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon:
                Icon(widget.prefixIcon, color: AppColors.textSecondary),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textSecondary),
                    ),
                  )
                : null,
          ),
        ),

        // Suggestions dropdown
        if (showDropdown) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _loading && _filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < _filtered.length; i++) ...[
                          if (i > 0)
                            const Divider(
                                height: 1, indent: 16, endIndent: 16),
                          InkWell(
                            onTap: () => _select(_filtered[i]),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13),
                              child: Row(
                                children: [
                                  Icon(widget.prefixIcon,
                                      size: 16,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _filtered[i],
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textPrimary),
                                    ),
                                  ),
                                  const Icon(Icons.north_west,
                                      size: 14,
                                      color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],

        // Selected chips
        if (widget.chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (int i = 0; i < widget.chips.length; i++)
                Chip(
                  label: Text(widget.chips[i]),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => widget.onRemove(i),
                  backgroundColor: AppColors.primaryLight,
                  labelStyle: const TextStyle(
                      color: AppColors.primary, fontSize: 13),
                  deleteIconColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
