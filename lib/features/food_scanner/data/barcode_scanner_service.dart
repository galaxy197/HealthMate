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
    await _controller?.dispose();
    _controller = null;
  }

  Future<void> toggleTorch() async {
    await _controller?.toggleTorch();
  }

  Future<void> switchCamera() async {
    await _controller?.switchCamera();
  }

  bool get hasTorch => _controller?.torchState.value == TorchState.on;
}
