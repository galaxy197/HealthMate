import 'package:mobile_scanner/mobile_scanner.dart';

/// Service quản lý barcode scanner
class BarcodeScannerService {
  MobileScannerController? _controller;

  MobileScannerController getController() {
    _controller ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    return _controller!;
  }

  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  Future<void> toggleTorch() async {
    final controller = _controller;
    if (controller != null) {
      await controller.toggleTorch();
    }
  }

  Future<void> switchCamera() async {
    final controller = _controller;
    if (controller != null) {
      await controller.switchCamera();
    }
  }

  bool get hasTorch {
    final controller = _controller;
    return controller != null && controller.torchState.value == TorchState.on;
  }
}
