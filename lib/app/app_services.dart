import 'package:flutter/widgets.dart';

import '../data/repositories/media_repository.dart';
import '../data/repositories/vocabulary_repository.dart';
import '../services/tutor/tutor_service.dart';

/// Hackathon services, created once in main.dart and swapped in tests.
/// Owned by the integration lead: workstreams change IMPLEMENTATIONS passed in
/// main.dart, never this shape (see docs/INTEGRATION_CONTRACTS.md §5).
class AppServices {
  AppServices({
    required this.media,
    required this.vocabulary,
    required this.tutor,
  });

  /// Offline-safe defaults for tests and previews.
  factory AppServices.inMemory() => AppServices(
    media: const InMemoryMediaRepository([]),
    vocabulary: InMemoryVocabularyRepository(),
    tutor: const UnavailableTutorService(),
  );

  final MediaRepository media;
  final VocabularyRepository vocabulary;
  final TutorService tutor;
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ServicesScope>()!.services;

  @override
  bool updateShouldNotify(ServicesScope old) => old.services != services;
}
