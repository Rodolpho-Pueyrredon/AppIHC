import 'dart:async';
import 'dart:io';

import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/presentation/widgets/android_back_to_background.dart';
import 'package:flutter/material.dart';

class FakeLoginScreen extends StatefulWidget {
  const FakeLoginScreen({super.key});

  @override
  State<FakeLoginScreen> createState() => _FakeLoginScreenState();
}

class _FakeLoginScreenState extends State<FakeLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final username = _usernameController.text.trim();
      final isValidLogin = await ServiceLocator
          .instance
          .collaboratorLoginService
          .login(username: username, password: _passwordController.text);
      if (!isValidLogin) {
        _showLoginError('usuário ou senha inválidos');
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
        return;
      }

      final works = await ServiceLocator.instance.collaboratorWorksService
          .getWorksForCollaborator(username);
      await ServiceLocator.instance.sessionRepository.saveSessionWorks(works);
      await ServiceLocator.instance.sessionProductsSyncService
          .syncProductsFromSession();
      ServiceLocator.instance.authSession.login(username: username);

      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(context, AppRoutes.products);
    } on SocketException {
      _showLoginError('sem conexão com internet');
    } on TimeoutException {
      _showLoginError('sem conexão com internet');
    } catch (_) {
      _showLoginError('Nao foi possivel iniciar a sessao.');
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showLoginError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AndroidBackToBackground(
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Login',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Usuario'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite um usuario.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite uma senha.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: Text(_isSubmitting ? 'Entrando...' : 'Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
