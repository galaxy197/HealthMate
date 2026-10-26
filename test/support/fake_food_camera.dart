import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:healthmate/features/food_scanner/data/food_camera_service.dart';
import 'package:healthmate/features/food_scanner/data/food_image_picker.dart';

class FakeFoodCamera implements FoodCameraSession {
  int starts = 0, captures = 0, closes = 0;
  Object? error;
  Completer<void>? pendingStart;
  @override
  CameraController? get controller => null;
  @override
  Future<void> initialize() async {
    starts++;
    await pendingStart?.future;
    if (error != null) throw error!;
  }

  @override
  Future<FoodImage> capture() async {
    captures++;
    return FoodImage(
      bytes: Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
        ),
      ),
      mimeType: 'image/png',
    );
  }

  @override
  Future<void> dispose() async {
    closes++;
  }
}
