// Explicit local boundary probe. It must never initialize Firebase or invoke a
// provider: the former direct model routes are deliberately closed in Gói 5.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:healthmate/features/chatbot/data/firebase_knowledge_service.dart';
import 'package:healthmate/features/chatbot/models/chat_models.dart';
import 'package:healthmate/features/food_scanner/data/firebase_food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/data/food_scanner_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('HealthMate AI gateway boundary')),
      ),
    ),
  );
  var knowledgeBlocked = false, scannerBlocked = false;
  try {
    await FirebaseKnowledgeService()
        .explain(KnowledgeTopic.balancedMeals)
        .drain<void>();
  } on ChatFailure {
    knowledgeBlocked = true;
  }
  try {
    await FirebaseFoodScannerService().analyze(
      bytes: Uint8List.fromList([1]),
      mimeType: 'image/png',
    );
  } on FoodScannerFailure catch (failure) {
    scannerBlocked = failure.code == 'gateway-not-configured';
  }
  debugPrint(
    'HM_QA directKnowledgeBlocked=$knowledgeBlocked directScannerBlocked=$scannerBlocked',
  );
  debugPrint('HM_QA DONE failed=${!knowledgeBlocked || !scannerBlocked}');
}
