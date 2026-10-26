import 'dart:typed_data';

import '../models/ai_food_suggestion.dart';

abstract interface class FoodScannerService {
  Future<AiFoodSuggestion> analyze({
    required Uint8List bytes,
    required String mimeType,
  });
}

class FoodScannerFailure implements Exception {
  const FoodScannerFailure(this.message, {this.code = 'unknown'});

  final String message;
  final String code;

  @override
  String toString() => message;
}
