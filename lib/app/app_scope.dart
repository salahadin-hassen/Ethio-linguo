import 'package:flutter/widgets.dart';

import 'app_controller.dart';

/// Exposes [AppController] to the widget tree and rebuilds dependents when it
/// notifies. Deliberately dependency-free (no provider/riverpod needed at
/// this scale).
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing to rebuilds (for callbacks).
  static AppController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
