import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/presentation/state/auth_session.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SessionAppBarTitle extends StatelessWidget {
  const SessionAppBarTitle({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final username = context.watch<AuthSession>().username ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          username,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        child,
      ],
    );
  }
}

class LogoutActionButton extends StatelessWidget {
  const LogoutActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sair',
      onPressed: () async {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);

        try {
          await ServiceLocator.instance.sessionRepository.clearSession();
        } catch (_) {
          if (!messenger.mounted) {
            return;
          }

          messenger.showSnackBar(
            const SnackBar(
              content: Text('Nao foi possivel encerrar a sessao.'),
            ),
          );
          return;
        }

        ServiceLocator.instance.authSession.logout();
        if (!navigator.mounted) {
          return;
        }

        navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      },
      icon: const Icon(Icons.logout, size: 48),
    );
  }
}
