import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/components/app_button.dart';
import '../../core/components/entrance.dart';
import '../../core/components/speech_bubble.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/language.dart';
import '../mascot/mascot.dart';
import 'widgets/language_option_card.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  NativeLanguage? _native;
  TargetLanguage _target = TargetLanguage.english;
  LearnerLevel _level = LearnerLevel.beginner;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = AppScope.read(context).progress;
    _native = p.native;
    _level = p.level;
  }

  static const _accents = {
    NativeLanguage.amharic: (AppColors.coral, 'አ'),
    NativeLanguage.oromo: (AppColors.teal, 'Q'),
  };

  Future<void> _continue() async {
    final native = _native;
    if (native == null || _saving) return;
    setState(() => _saving = true);
    await AppScope.read(context)
        .chooseLanguages(native, _target, level: _level);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bubble = _native == null
        ? 'Which language do you speak?'
        : '${_native!.greeting}! Great choice.';
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop() ? const BackButton() : null,
        title: const Text('Your languages'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.xs,
                  Space.gutter,
                  Space.lg,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Mascot(
                        mood: _native == null
                            ? MascotMood.thinking
                            : MascotMood.happy,
                        size: 96,
                      ),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 36),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: SpeechBubble(
                              key: ValueKey(bubble),
                              text: bubble,
                              tail: BubbleTail.left,
                              style: AppType.label.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.md),
                  _Label('I speak', AppColors.coralInk),
                  for (final (i, lang) in NativeLanguage.values.indexed) ...[
                    Entrance(
                      delay: Duration(milliseconds: 80 * i),
                      child: LanguageOptionCard(
                        glyph: _accents[lang]!.$2,
                        title: lang.endonym,
                        subtitle: lang.englishName,
                        caption: lang.scriptLabel,
                        accent: _accents[lang]!.$1,
                        selected: _native == lang,
                        onTap: () => setState(() => _native = lang),
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                  ],
                  const SizedBox(height: Space.md),
                  _Label('I want to learn', AppColors.periwinkleInk),
                  for (final lang in TargetLanguage.values) ...[
                    LanguageOptionCard(
                      glyph: switch (lang) {
                        TargetLanguage.english => 'Aa',
                        TargetLanguage.french => 'Ff',
                        TargetLanguage.arabic => 'Ar',
                      },
                      title: lang.name,
                      subtitle: lang.available
                          ? 'Beginner course · Unit 1 ready'
                          : 'Planned course',
                      caption: lang.available
                          ? 'Explained in your language'
                          : 'Not available yet',
                      accent: lang.available
                          ? AppColors.periwinkle
                          : AppColors.disabledFill,
                      selected: lang.available && _target == lang,
                      badge: lang.available ? null : 'Soon',
                      onTap: lang.available
                          ? () => setState(() => _target = lang)
                          : null,
                    ),
                    const SizedBox(height: Space.sm),
                  ],
                  const SizedBox(height: Space.md),
                  _Label('My English level', AppColors.tealInk),
                  for (final level in LearnerLevel.values) ...[
                    _LevelOption(
                      level: level,
                      selected: _level == level,
                      onTap: () => setState(() => _level = level),
                    ),
                    const SizedBox(height: Space.xs),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.sm,
                Space.gutter,
                Space.md,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.outline, width: 1.5),
                ),
              ),
              child: AppButton(
                label: 'Continue',
                onPressed: _native == null || _saving ? null : _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.xs, left: 4),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AppType.overline.copyWith(color: color),
      ),
    ),
  );
}

class _LevelOption extends StatelessWidget {
  const _LevelOption({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final LearnerLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      key: ValueKey('level_${level.name}'),
      borderRadius: Radii.lgAll,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealTint : AppColors.surface,
          borderRadius: Radii.lgAll,
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.outline,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(level.title, style: AppType.titleSmall),
                  Text(
                    level.subtitle,
                    style: AppType.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.tealInk : AppColors.textMuted,
            ),
          ],
        ),
      ),
    ),
  );
}
