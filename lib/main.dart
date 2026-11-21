import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_controller.dart';
import 'data/local/demo_course.dart';
import 'data/local/progress_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Everything below is local: bundled course content + on-device progress.
  final store = await SharedPrefsProgressStore.create();
  final controller = await AppController.load(
    course: DemoCourse.course,
    store: store,
  );
  runApp(LearningApp(controller: controller));
}
