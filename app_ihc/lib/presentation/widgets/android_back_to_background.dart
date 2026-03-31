import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AndroidBackToBackground extends StatelessWidget {
  const AndroidBackToBackground({
    super.key,
    required this.child,
  });

  static const _channel = MethodChannel('app_ihc/system_navigation');

  final Widget child;

  Future<void> _moveToBackground() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod<bool>('moveTaskToBack');
    } catch (_) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _moveToBackground();
      },
      child: child,
    );
  }
}
