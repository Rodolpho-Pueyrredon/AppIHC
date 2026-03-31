import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
import 'package:app_ihc/presentation/screens/detail_edit_screen.dart';
import 'package:app_ihc/presentation/screens/fake_login_screen.dart';
import 'package:app_ihc/presentation/screens/history_screen.dart';
import 'package:app_ihc/presentation/screens/scanner_screen.dart';
import 'package:flutter/material.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final isLoggedIn = ServiceLocator.instance.authSession.isLoggedIn;
    final routeName = settings.name ?? AppRoutes.login;

    if (!isLoggedIn && routeName != AppRoutes.login) {
      return MaterialPageRoute<void>(
        builder: (_) => const FakeLoginScreen(),
        settings: const RouteSettings(name: AppRoutes.login),
      );
    }

    switch (routeName) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          builder: (_) => const FakeLoginScreen(),
          settings: settings,
        );
      case AppRoutes.scanner:
        return MaterialPageRoute<void>(
          builder: (_) => const ScannerScreen(),
          settings: settings,
        );
      case AppRoutes.history:
        return MaterialPageRoute<void>(
          builder: (_) => const HistoryScreen(),
          settings: settings,
        );
      case AppRoutes.detailEdit:
        final args = settings.arguments is DetailEditArgs
            ? settings.arguments! as DetailEditArgs
            : const DetailEditArgs();

        return MaterialPageRoute<void>(
          builder: (_) => DetailEditScreen(args: args),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => isLoggedIn ? const ScannerScreen() : const FakeLoginScreen(),
          settings: settings,
        );
    }
  }
}
