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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _native = AppScope.read(context).progress.native;
  }

  static const _accents = {
    NativeLanguage.amharic: (AppColors.coral, 'አ'),
    NativeLanguage.oromo: (AppColors.teal, 'Q'),
  };

  Future<void> _continue() async {
    final native = _native;
    if (native == null || _saving) return;
    setState(() => _saving = true);
    await AppScope.read(context).chooseLanguages(native, _target);
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
