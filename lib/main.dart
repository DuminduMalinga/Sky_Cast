import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_settings.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  runApp(const SkyCastApp(showOnboarding: true));
}
