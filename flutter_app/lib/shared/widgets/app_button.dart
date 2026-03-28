import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, destructive, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [icon!, const SizedBox(width: 8), Text(label)],
              )
            : Text(label);

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(onPressed: onPressed, child: child);
      case AppButtonVariant.secondary:
        button = OutlinedButton(onPressed: onPressed, child: child);
      case AppButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.destructive,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            textStyle: AppTextStyles.button,
          ),
          child: child,
        );
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: child,
        );
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}

/// Small pill-shaped action button (Accept / Reject style)
class AppChipButton extends StatelessWidget {
  const AppChipButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          border: outlined ? Border.all(color: color) : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: outlined ? color : Colors.white,
          ),
        ),
      ),
    );
  }
}
