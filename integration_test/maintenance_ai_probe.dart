import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_ai/firebase_ai.dart';
import 'package:healthmate/features/chatbot/data/knowledge_service.dart';
// Opt-in bounded QA test. Only fixed knowledge and a synthetic image are sent;
// no Auth registration, Firestore writes or user health data are involved.
import 'dart:convert';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:healthmate/core/config/firebase_bootstrap.dart';
import 'package:healthmate/features/chatbot/data/firebase_knowledge_service.dart';
import 'package:healthmate/features/chatbot/models/chat_models.dart';
import 'package:healthmate/features/food_scanner/data/firebase_food_scanner_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('HealthMate QA probe'))),
    ),
  );
  var failed = false;
  final clock = Stopwatch()..start();
  try {
    await initializeFirebase().timeout(const Duration(seconds: 15));
    debugPrint('HM_QA bootstrap=ok elapsedMs=${clock.elapsedMilliseconds}');
    final token = await FirebaseAppCheck.instance
        .getToken(false)
        .timeout(const Duration(seconds: 15));
    if (token == null || token.isEmpty) throw StateError('no-token');
    debugPrint('HM_QA appcheck=ok elapsedMs=${clock.elapsedMilliseconds}');
  } catch (_) {
    debugPrint('HM_QA appcheck=blocked elapsedMs=${clock.elapsedMilliseconds}');
    failed = true;
    debugPrint('HM_QA DONE failed=true');
    return;
  }
  if (const bool.fromEnvironment('HEALTHMATE_QA_NETWORK_DIAGNOSTICS')) {
    try {
      final headers =
          await const MethodChannel('plugins.flutter.io/firebase_ai')
              .invokeMapMethod<String, String>('getPlatformHeaders')
              .timeout(const Duration(seconds: 10));
      debugPrint('HM_QA platformHeaders=ok count=${headers?.length ?? 0}');
    } catch (e) {
      debugPrint('HM_QA platformHeaders=failed type=${e.runtimeType}');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client
          .getUrl(Uri.parse('https://firebasevertexai.googleapis.com'))
          .timeout(const Duration(seconds: 12));
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      debugPrint('HM_QA aiEndpoint=reachable status=${response.statusCode}');
      await response.drain<void>().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('HM_QA aiEndpoint=failed type=${e.runtimeType}');
    } finally {
      client.close(force: true);
    }
  }
  clock.reset();
  var chunks = 0;
  try {
    final answer = StringBuffer();
    final transport = _ProbeTransport();
    final model = const bool.fromEnvironment('HEALTHMATE_QA_TRANSPORT')
        ? FirebaseAI.googleAI().generativeModel(
            model: FirebaseKnowledgeService.modelName,
            systemInstruction: Content.system(KnowledgePrompt.system),
            generationConfig: GenerationConfig(
              temperature: .2,
              maxOutputTokens: 2048,
              thinkingConfig: ThinkingConfig.withThinkingLevel(
                ThinkingLevel.low,
              ),
            ),
            httpClient: transport,
          )
        : null;
    await FirebaseKnowledgeService(model: model)
        .explain(KnowledgeTopic.balancedMeals)
        .forEach((chunk) {
          chunks++;
          answer.write(chunk);
          if (chunks == 1) {
            debugPrint('HM_QA firstChunkMs=${clock.elapsedMilliseconds}');
          }
        })
        .timeout(const Duration(seconds: 45));
    if (answer.isEmpty) throw StateError('empty');
    debugPrint(
      'HM_QA knowledge=ok chunks=$chunks elapsedMs=${clock.elapsedMilliseconds}',
    );
  } catch (error) {
    debugPrint(
      'HM_QA knowledge=failed type=${error.runtimeType} chunks=$chunks elapsedMs=${clock.elapsedMilliseconds}',
    );
    failed = true;
  }
  clock.reset();
  try {
    // A valid generated 1x1 red PNG; parser/service smoke, not food accuracy.
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
    );
    final result = await FirebaseFoodScannerService()
        .analyze(bytes: bytes, mimeType: 'image/png')
        .timeout(const Duration(seconds: 45));
    if (result.dishName.isEmpty) throw StateError('empty');
    debugPrint(
      'HM_QA scannerService=ok elapsedMs=${clock.elapsedMilliseconds}',
    );
  } catch (error) {
    debugPrint(
      'HM_QA scannerService=failed type=${error.runtimeType} elapsedMs=${clock.elapsedMilliseconds}',
    );
    failed = true;
  }
  debugPrint('HM_QA DONE failed=$failed');
}

class _ProbeTransport extends http.BaseClient {
  final _client = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    debugPrint('HM_QA transport=send');
    final response = await _client.send(request);
    debugPrint('HM_QA transport=status_${response.statusCode}');
    return response;
  }

  @override
  void close() => _client.close();
}
