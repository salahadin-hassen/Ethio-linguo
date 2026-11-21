import 'package:ethio_linguo/data/models/language.dart';
import 'package:ethio_linguo/features/home/home_shell.dart';
import 'package:ethio_linguo/features/language_selection/language_selection_screen.dart';
import 'package:ethio_linguo/features/onboarding/welcome_screen.dart';

import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('fresh install starts on the welcome screen', (t) async {
    await pumpApp(t);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('GET STARTED'), findsOneWidget);
    expect(find.text('ሰላም!'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('returning learner starts on home', (t) async {
    await pumpApp(t, progress: onboarded());
    expect(find.byType(HomeShell), findsOneWidget);
  });

  testWidgets('"already have an account" explains offline-only honestly', (
    t,
  ) async {
    await pumpApp(t);
    await t.tap(find.text('I ALREADY HAVE AN ACCOUNT'));
    await t.pump();
    expect(find.textContaining('saved on this device'), findsOneWidget);
  });

  testWidgets('onboarding → language selection → home, choice persisted', (
    t,
  ) async {
    final h = await pumpApp(t);
    await t.tap(find.text('GET STARTED'));
    await t.pumpAndSettle();
    expect(find.byType(LanguageSelectionScreen), findsOneWidget);

    // Continue is disabled until a native language is chosen.
    await t.tap(find.text('CONTINUE'));
    await t.pumpAndSettle();
    expect(find.byType(LanguageSelectionScreen), findsOneWidget);

    // Endonyms + English names are shown (not flags).
    expect(find.text('አማርኛ'), findsOneWidget);
    expect(find.text('Afaan Oromoo'), findsOneWidget);
    expect(find.text('Afaan Oromo'), findsOneWidget);

    await t.tap(find.text('Afaan Oromoo'));
    await t.pumpAndSettle();
    expect(find.text('Akkam! Great choice.'), findsOneWidget);
    // Unavailable target languages are not selectable.
    expect(find.text('Soon'), findsWidgets);

    await t.tap(find.text('CONTINUE'));
    await t.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.textContaining('Akkam!'), findsWidgets);
    expect(h.store.value!.onboarded, isTrue);
    expect(h.store.value!.native, NativeLanguage.oromo);
    expect(h.store.value!.target, TargetLanguage.english);
  });

  testWidgets('selection semantics expose selected state', (t) async {
    final handle = t.ensureSemantics();
    await pumpApp(t);
    await t.tap(find.text('GET STARTED'));
    await t.pumpAndSettle();
    await t.tap(find.text('አማርኛ'));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('^አማርኛ, Amharic')), findsOneWidget);
    final node = t.getSemantics(
      find.bySemanticsLabel(RegExp('^አማርኛ, Amharic')),
    );
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    handle.dispose();
  });
}
