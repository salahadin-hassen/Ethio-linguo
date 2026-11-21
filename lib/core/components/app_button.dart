import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'pressable.dart';

enum AppButtonVariant { primary, success, danger, secondary, dark, ghost }

/// The single button component used across the app.
/// Brand-colour fills always carry indigo text (WCAG AA >= 4.5:1).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = true,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (
      Color fill,
      Color shade,
      Color fg,
      BoxBorder? border,
    ) = switch (variant) {
      _ when !enabled => (
        AppColors.disabledFill,
        AppColors.outlineStrong,
        AppColors.disabledText,
        null,
      ),
      AppButtonVariant.primary => (
        AppColors.coral,
        AppColors.coralShade,
        AppColors.indigo,
        null,
      ),
      AppButtonVariant.success => (
        AppColors.teal,
        AppColors.tealShade,
        AppColors.indigo,
        null,
      ),
      AppButtonVariant.danger => (
        AppColors.coral,
        AppColors.coralShade,
        AppColors.indigo,
        null,
      ),
      AppButtonVariant.dark => (
        AppColors.indigo,
        AppColors.indigoShade,
        AppColors.ivory,
        null,
      ),
      AppButtonVariant.secondary => (
        AppColors.surface,
        AppColors.outlineStrong,
        AppColors.indigo,
        Border.all(color: AppColors.outlineStrong, width: 2),
      ),
      AppButtonVariant.ghost => (
        Colors.transparent,
        Colors.transparent,
        AppColors.periwinkleInk,
        null,
      ),
    };
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.label.copyWith(
              color: fg,
              letterSpacing: 0.8,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
    return Pressable(
      onTap: onPressed,
      color: fill,
      shade: shade,
      border: border,
      depth: variant == AppButtonVariant.ghost ? 0 : 4,
      borderRadius: BorderRadius.circular(16),
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: height - 4,
          minWidth: expand ? double.infinity : 0,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            widthFactor: expand ? null : 1,
            child: ExcludeSemantics(child: content),
          ),
        ),
      ),
    );
  }
}
