import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_strings.dart';

/// English label + optional support line in the learner's language.
class LabelWithSupport extends StatelessWidget {
  const LabelWithSupport(
    this.keyName, {
    super.key,
    this.style,
    this.supportStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final S keyName;
  final TextStyle? style;
  final TextStyle? supportStyle;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final native = s.native(keyName);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(s.en(keyName), style: style ?? AppType.label),
        if (native != null)
          Directionality(
            textDirection: s.direction,
            child: Text(
              native,
              style:
                  supportStyle ??
                  AppType.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }
}
