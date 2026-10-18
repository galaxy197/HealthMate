import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import '../../../core/config/ai_access_policy.dart';
import '../../../core/config/app_feature_flags.dart';
import '../models/ai_food_suggestion.dart';
import '../data/food_image_picker.dart';

import '../data/firebase_food_scanner_service.dart';
import '../data/food_scanner_service.dart';

final foodImagePickerProvider = Provider<FoodImagePicker>(
  (ref) => DeviceFoodImagePicker(),
);

final foodScannerServiceProvider = Provider<FoodScannerService>(
  (ref) => _CheckedFoodScannerService(
    check: () {
      if (!ref.read(appFeatureFlagsProvider).foodScannerEnabled) {
        return const AiAccess(
          allowed: false,
          message: 'Quét món đang tạm tắt trong bản core.',
        );
      }
      return ref.read(aiAccessProvider);
    },
  ),
);

class _CheckedFoodScannerService implements FoodScannerService {
  _CheckedFoodScannerService({required this.check});
  final AiAccess Function() check;
  FoodScannerService? _delegate;

  @override
  Future<AiFoodSuggestion> analyze({
    required Uint8List bytes,
    required String mimeType,
  }) {
    final access = check();
    if (!access.allowed) throw FoodScannerFailure(access.message);
    return (_delegate ??= FirebaseFoodScannerService()).analyze(
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}
