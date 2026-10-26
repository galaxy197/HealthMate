import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:healthmate/features/food_scanner/data/firebase_food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/data/food_image_picker.dart';
import 'package:healthmate/features/food_scanner/models/ai_food_suggestion.dart';

void main() {
  test(
    'scanner chooses fast thinking without invalid minimal on Flash',
    () async {
      expect(
        FoodScannerConfig.thinkingLevelFor('gemini-3.5-flash-lite'),
        ThinkingLevel.minimal,
      );
      expect(
        FoodScannerConfig.thinkingLevelFor('gemini-3.8-flash'),
        ThinkingLevel.low,
      );
      final config = FirebaseFoodScannerService.generationConfig.toJson();
      expect(config['responseMimeType'], 'application/json');
      expect(config['thinkingConfig'], {'thinkingLevel': 'MINIMAL'});
      expect(config['responseSchema'], isNotNull);
      // Opt-in export contains only app-owned prompt/schema, never credentials.
      if (const bool.fromEnvironment('HEALTHMATE_EXPORT_SCANNER_REQUEST')) {
        File('build/scanner-request-config.json').writeAsStringSync(
          jsonEncode({
            'model': FoodScannerConfig.modelName,
            'generationConfig': config,
            'systemInstruction': FirebaseFoodScannerService.systemInstruction
                .toJson(),
          }),
        );
        const input = String.fromEnvironment('HEALTHMATE_SCANNER_PROBE_IMAGE');
        if (input.isNotEmpty) {
          final prepared = await prepareFoodImage(
            await File(input).readAsBytes(),
          );
          await File(
            'build/scanner-probe-image.png',
          ).writeAsBytes(prepared.bytes);
        }
      }
      if (const bool.fromEnvironment('HEALTHMATE_VERIFY_SCANNER_RESPONSE')) {
        final result = AiFoodSuggestion.fromJsonText(
          await File('build/scanner-live-result.json').readAsString(),
        );
        expect(result.isFood, isTrue);
        expect(result.estimatedNutritionPer100g?.isComplete, isTrue);
        expect(result.ingredients, isNotEmpty);
      }
    },
  );
  test(
    'scanner error mapping separates model, App Check, server and quota',
    () {
      expect(scannerFailureFor(TimeoutException('wait')).code, 'timeout');
      expect(
        scannerFailureFor(FirebaseAIException('models/test is not found')).code,
        'model-not-found',
      );
      expect(
        scannerFailureFor(
          FirebaseAIException('503 UNAVAILABLE: overloaded'),
        ).code,
        'service-unavailable',
      );
      expect(
        scannerFailureFor(
          FirebaseAIException('INVALID_ARGUMENT: responseSchema'),
        ).code,
        'invalid-request',
      );
      expect(
        scannerFailureFor(
          FirebaseException(
            plugin: 'app-check',
            code: 'app-check-token-invalid',
          ),
        ).code,
        'app-check',
      );
      expect(
        scannerFailureFor(QuotaExceeded('RESOURCE_EXHAUSTED quota')).code,
        'quota',
      );
      expect(
        scannerFailureFor(FirebaseAIException('403 PERMISSION_DENIED')).code,
        'permission-denied',
      );
    },
  );
  test(
    'scanner transport preserves request and status with explicit close',
    () async {
      var closed = false;
      final client = FoodScannerHttpClient(
        inner: _ClosableClient(
          MockClient((request) async {
            expect(request.url.host, 'firebasevertexai.googleapis.com');
            return http.Response('{"error":{"status":"UNAVAILABLE"}}', 503);
          }),
          () => closed = true,
        ),
      );
      final result = await client.get(
        Uri.https('firebasevertexai.googleapis.com', '/test'),
      );
      expect(result.statusCode, 503);
      client.close();
      expect(closed, isTrue);
    },
  );
}

class _ClosableClient extends http.BaseClient {
  _ClosableClient(this.inner, this.onClose);
  final http.Client inner;
  final void Function() onClose;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      inner.send(request);
  @override
  void close() {
    inner.close();
    onClose();
  }
}
