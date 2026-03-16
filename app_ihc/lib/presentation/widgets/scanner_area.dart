import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerArea extends StatefulWidget {
  const ScannerArea({
    super.key,
    required this.onCodeDetected,
    this.onScanError,
    this.onEmptyCode,
  });

  final ValueChanged<String> onCodeDetected;
  final ValueChanged<String>? onScanError;
  final VoidCallback? onEmptyCode;

  @override
  State<ScannerArea> createState() => _ScannerAreaState();
}

class _ScannerAreaState extends State<ScannerArea>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _hasDetected = false;
  bool _isStartingCamera = false;
  bool _isStoppingCamera = false;
  bool _isCameraStarted = false;
  String? _cameraError;
  bool _reportedBuilderError = false;

  bool get _supportsRealScanner {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_supportsRealScanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startCamera();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_supportsRealScanner) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _startCamera();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopCamera();
    }
  }

  bool _isAlreadyInitializedError(Object error) {
    return error.toString().contains('controllerAlreadyInitialized');
  }

  Future<void> _stopCamera() async {
    if (_isStoppingCamera || !_isCameraStarted) {
      return;
    }

    _isStoppingCamera = true;
    try {
      await _controller.stop();
    } catch (_) {
      // O estado local ainda precisa ser resetado para permitir nova tentativa.
    } finally {
      _isCameraStarted = false;
      _isStoppingCamera = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _startCamera() async {
    if (!mounted || _hasDetected || _isStartingCamera || _isStoppingCamera) {
      return;
    }

    if (_isCameraStarted) {
      return;
    }

    _isStartingCamera = true;
    setState(() {
      _cameraError = null;
      _reportedBuilderError = false;
    });

    try {
      await _controller.start();
      _isCameraStarted = true;
    } catch (e) {
      if (_isAlreadyInitializedError(e)) {
        _isCameraStarted = true;
        return;
      }

      final message = e.toString();
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraError = message;
      });
      _notifyScanError(message);
    } finally {
      _isStartingCamera = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasDetected) {
      return;
    }

    final rawValue =
        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (rawValue == null || rawValue.trim().isEmpty) {
      widget.onEmptyCode?.call();
      return;
    }

    _hasDetected = true;
    await _stopCamera();
    widget.onCodeDetected(rawValue.trim());
  }

  void _notifyScanError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onScanError?.call(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsRealScanner) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 260,
                child: Center(
                  child: Text('Scanner real disponivel no celular (Android/iOS).'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onEmptyCode,
                child: const Text('Scanner indisponivel nesta plataforma'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 200,
                child: Center(
                  child: Text('Nao foi possivel abrir a camera.'),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _startCamera,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          SizedBox(
            height: 420,
            width: double.infinity,
            child: MobileScanner(
              controller: _controller,
              fit: BoxFit.cover,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                if (_isAlreadyInitializedError(error)) {
                  _isCameraStarted = true;
                  return child ?? const SizedBox.expand();
                }

                if (!_reportedBuilderError) {
                  _reportedBuilderError = true;
                  _notifyScanError(error.toString());
                }
                return Center(
                  child: Text('Falha na camera: $error'),
                );
              },
            ),
          ),
          if (!_isCameraStarted && _cameraError == null)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black12,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          const Positioned.fill(child: _ScannerTargetOverlay()),
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'toggle_torch',
              onPressed: _controller.toggleTorch,
              child: const Icon(Icons.flash_on),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerTargetOverlay extends StatelessWidget {
  const _ScannerTargetOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(16),
            color: Colors.black.withAlpha(25),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(8),
          child: const Text(
            'Centralize o codigo no quadro',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
