import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_settings.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  // The welcome flow (and its one-time location prompt) is first-run only.
  runApp(SkyCastApp(showOnboarding: !AppSettings.instance.onboarded));
}
