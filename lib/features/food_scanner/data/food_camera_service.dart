import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'food_image_picker.dart';
import 'food_scanner_service.dart';
import 'firebase_food_scanner_service.dart';

abstract interface class FoodCameraSession {
  CameraController? get controller;
  Future<void> initialize();
  Future<FoodImage> capture();
  Future<void> dispose();
}

class DeviceFoodCameraSession implements FoodCameraSession {
  @override
  CameraController? controller;

  @override
  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const FoodScannerFailure(
        'Camera xem trước hỗ trợ Android. Bạn vẫn có thể chọn ảnh hoặc nhập tay.',
      );
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw const FoodScannerFailure('Không tìm thấy camera trên thiết bị.');
    }
    final camera =
        cameras
            .where((c) => c.lensDirection == CameraLensDirection.back)
            .firstOrNull ??
        cameras.first;
    final next = controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await next.initialize();
  }

  @override
  Future<FoodImage> capture() async {
    final current = controller;
    if (current == null || !current.value.isInitialized) {
      throw const FoodScannerFailure(
        'Camera chưa sẵn sàng. Hãy thử lại hoặc chọn ảnh.',
      );
    }
    final file = await current.takePicture();
    if (await file.length() > FoodScannerConfig.maxImageBytes) {
      throw const FoodScannerFailure('Ảnh lớn hơn 8 MB. Hãy chọn ảnh nhỏ hơn.');
    }
    return prepareFoodImage(await file.readAsBytes());
  }

  @override
  Future<void> dispose() async {
    final current = controller;
    controller = null;
    await current?.dispose();
  }
}

/// Serialize camera ownership, including handoff to the barcode scanner.
class FoodCameraService {
  FoodCameraService({FoodCameraSession Function()? createSession})
    : _createSession = createSession ?? DeviceFoodCameraSession.new;
  final FoodCameraSession Function() _createSession;
  FoodCameraSession? _current;
  Future<void> _pending = Future.value();

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _closeCurrent() async {
    final old = _current;
    _current = null;
    await old?.dispose();
  }

  Future<FoodCameraSession> open() => _enqueue(() async {
    await _closeCurrent();
    final next = _current = _createSession();
    try {
      await next.initialize();
      return next;
    } catch (_) {
      await _closeCurrent();
      rethrow;
    }
  });

  Future<FoodImage> capture(FoodCameraSession session) => _enqueue(() async {
    if (!identical(_current, session)) {
      throw const FoodScannerFailure('Camera đã tạm dừng. Hãy thử chụp lại.');
    }
    return session.capture();
  });

  Future<void> release([FoodCameraSession? session]) => _enqueue(() async {
    if (session == null || identical(session, _current)) await _closeCurrent();
  });
}

final foodCameraServiceProvider = Provider<FoodCameraService>((ref) {
  final service = FoodCameraService();
  ref.onDispose(
    () => unawaited(service.release().catchError((Object _, StackTrace _) {})),
  );
  return service;
});
