import 'package:flutter/material.dart';

import 'core/di/service_locator.dart';
import 'presentation/app.dart';

void main() {
  ServiceLocator.instance.setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppRoot();
  }
}
