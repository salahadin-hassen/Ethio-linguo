import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_controller.dart';
import 'app/app_services.dart';
import 'data/local/demo_course.dart';
import 'data/local/progress_store.dart';
import 'data/repositories/media_repository.dart';
import 'data/repositories/vocabulary_repository.dart';
import 'services/tutor/tutor_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Everything below is local: bundled course content + on-device progress.
  final store = await SharedPrefsProgressStore.create();
  final controller = await AppController.load(
    course: DemoCourse.course,
    store: store,
  );
  final services = AppServices(
    media: AssetMediaRepository(),
    vocabulary: await SharedPrefsVocabularyRepository.create(),
    // Engineer 3 replaces this with the live implementation (see
    // docs/INTEGRATION_CONTRACTS.md §7). It must stay the fallback.
    tutor: const UnavailableTutorService(),
  );
  runApp(LearningApp(controller: controller, services: services));
}
