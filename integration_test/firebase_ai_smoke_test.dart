import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/firebase_bootstrap.dart';
import 'package:healthmate/features/food_scanner/data/firebase_food_scanner_service.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Firebase AI Logic accepts protected Android image requests', (
    tester,
  ) async {
    await initializeFirebase();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.white, BlendMode.src);
    canvas.drawCircle(
      const Offset(256, 280),
      150,
      Paint()..color = Colors.red.shade700,
    );
    canvas.drawRect(
      const Rect.fromLTWH(245, 70, 22, 95),
      Paint()..color = Colors.brown.shade700,
    );
    canvas.drawOval(
      const Rect.fromLTWH(270, 85, 110, 55),
      Paint()..color = Colors.green.shade700,
    );
    final image = await recorder.endRecording().toImage(512, 512);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(data, isNotNull);

    final result = await FirebaseFoodScannerService().analyze(
      bytes: data!.buffer.asUint8List(),
      mimeType: 'image/png',
    );
    expect(result.dishName, isNotEmpty);
    expect(result.description, isNotEmpty);
    expect(result.searchTerms, isNotEmpty);
  });
}
