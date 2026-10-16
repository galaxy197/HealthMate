import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'food_scanner_service.dart';
import 'firebase_food_scanner_service.dart';

class FoodImage {
  const FoodImage({required this.bytes, required this.mimeType});
  final Uint8List bytes;
  final String mimeType;
}

abstract interface class FoodImagePicker {
  Future<FoodImage?> pick(ImageSource source);
}

class DeviceFoodImagePicker implements FoodImagePicker {
  @override
  Future<FoodImage?> pick(ImageSource source) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const FoodScannerFailure(
        'Quét ảnh hiện hỗ trợ bản Android. Bạn vẫn có thể nhập món thủ công.',
      );
    }
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
        requestFullMetadata: false,
      );
      if (image == null) return null;
      // Check size before loading bytes into the Dart heap.
      if (await image.length() > FoodScannerConfig.maxImageBytes) {
        throw const FoodScannerFailure('Ảnh lớn hơn 8 MB. Hãy chọn ảnh khác.');
      }
      final bytes = await image.readAsBytes();
      final mime = lookupMimeType(
        image.name,
        headerBytes: bytes.take(16).toList(),
      );
      if (bytes.isEmpty ||
          bytes.length > FoodScannerConfig.maxImageBytes ||
          !const {'image/jpeg', 'image/png', 'image/webp'}.contains(mime)) {
        throw const FoodScannerFailure(
          'Ảnh trống, quá lớn hoặc định dạng chưa được hỗ trợ.',
        );
      }
      return prepareFoodImage(bytes);
    } on FoodScannerFailure {
      rethrow;
    } catch (_) {
      throw const FoodScannerFailure(
        'Chưa mở được ảnh. Kiểm tra quyền camera/thư viện rồi thử lại hoặc nhập thủ công.',
      );
    }
  }
}

/// Decode and re-encode pixels so original EXIF/GPS and ancillary metadata are
/// never copied into the AI payload. Device picker temporary files stay local.
Future<FoodImage> prepareFoodImage(Uint8List source) async {
  if (source.isEmpty || source.length > FoodScannerConfig.maxImageBytes) {
    throw const FoodScannerFailure('Ảnh trống hoặc lớn hơn 8 MB.');
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(source);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width * descriptor.height > 100000000) {
      throw const FoodScannerFailure(
        'Độ phân giải ảnh quá lớn. Hãy chọn ảnh nhỏ hơn.',
      );
    }
    final scale = math.min(
      1.0,
      1600 / math.max(descriptor.width, descriptor.height),
    );
    codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (descriptor.width * scale).round()),
      targetHeight: math.max(1, (descriptor.height * scale).round()),
    );
    image = (await codec.getNextFrame()).image;
    final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
    if (encoded == null ||
        encoded.lengthInBytes > FoodScannerConfig.maxImageBytes) {
      throw const FoodScannerFailure(
        'Ảnh sau xử lý lớn hơn 8 MB. Hãy chọn ảnh nhỏ hơn.',
      );
    }
    return FoodImage(
      bytes: encoded.buffer.asUint8List(
        encoded.offsetInBytes,
        encoded.lengthInBytes,
      ),
      mimeType: 'image/png',
    );
  } on FoodScannerFailure {
    rethrow;
  } catch (_) {
    throw const FoodScannerFailure(
      'Không đọc được nội dung ảnh. Hãy chọn ảnh khác hoặc nhập thủ công.',
    );
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}
