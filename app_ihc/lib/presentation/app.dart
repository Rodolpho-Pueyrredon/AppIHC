import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/presentation/navigation/app_router.dart';
import 'package:flutter/material.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App IHC MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: AppRoutes.scanner,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
