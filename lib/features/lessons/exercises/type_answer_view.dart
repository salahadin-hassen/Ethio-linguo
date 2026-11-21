import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../logic/answer_validator.dart';

class TypeAnswerView extends StatelessWidget {
  const TypeAnswerView({
    super.key,
    required this.controller,
    required this.verdict,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final Verdict? verdict;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final edge = switch (verdict) {
      Verdict.correct => AppColors.teal,
      Verdict.almost => AppColors.gold,
      Verdict.incorrect => AppColors.coral,
      null => AppColors.outlineStrong,
    };
    return TextField(
      key: const ValueKey('type_answer_field'),
      controller: controller,
      enabled: verdict == null,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmitted(),
      minLines: 3,
      maxLines: 4,
      style: AppType.title,
      decoration: InputDecoration(
        hintText: 'Type in English',
        hintStyle: AppType.title.copyWith(color: AppColors.disabledText),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: edge, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: edge, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.periwinkle, width: 2.5),
        ),
      ),
    );
  }
}
