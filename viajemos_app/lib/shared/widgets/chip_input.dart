import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ChipInput extends StatelessWidget {
  const ChipInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.chips,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<String> chips;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(hintText: hint),
                onFieldSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (int i = 0; i < chips.length; i++)
                Chip(
                  label: Text(chips[i]),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => onRemove(i),
                  backgroundColor: AppColors.primaryLight,
                  labelStyle: const TextStyle(color: AppColors.primary, fontSize: 13),
                  deleteIconColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
