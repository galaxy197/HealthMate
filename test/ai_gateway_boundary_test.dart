import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/chatbot/data/cloudflare_chat_assistant.dart';
import 'package:healthmate/features/chatbot/data/firebase_knowledge_service.dart';
import 'package:healthmate/features/chatbot/models/assistant_request.dart';
import 'package:healthmate/features/chatbot/models/chat_models.dart';
import 'package:healthmate/features/food_scanner/data/firebase_food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/data/food_scanner_service.dart';
import 'package:healthmate/features/premium/data/firebase_premium_repository.dart';
import 'package:healthmate/features/premium/models/premium_models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class NoFirestore extends Fake implements FirebaseFirestore {}

void main() {
  test(
    'direct Firebase image path fails closed before SDK or image upload',
    () async {
      await expectLater(
        FirebaseFoodScannerService().analyze(
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/png',
        ),
        throwsA(
          isA<FoodScannerFailure>().having(
            (failure) => failure.code,
            'code',
            'gateway-not-configured',
          ),
        ),
      );
    },
  );

  test('Android knowledge no longer bypasses gateway via Firebase', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await expectLater(
      FirebaseKnowledgeService().explain(KnowledgeTopic.hydration).toList(),
      throwsA(
        isA<ChatFailure>().having(
          (failure) => failure.message,
          'message',
          contains('bảo vệ hạn mức'),
        ),
      ),
    );
  });

  test(
    'client cannot reserve trusted quota using the former consume method',
    () async {
      await expectLater(
        FirebasePremiumRepository(
          NoFirestore(),
        ).consume('alice', PremiumAiFeature.chat),
        throwsA(
          isA<PremiumFailure>().having(
            (failure) => failure.message,
            'message',
            contains('chỉ được cấp bởi dịch vụ'),
          ),
        ),
      );
    },
  );

  test('gateway day key resets exactly at Vietnam midnight', () {
    expect(
      PremiumDemoPlan.gatewayDayId(DateTime.parse('2026-10-30T16:59:59Z')),
      '2026-10-30',
    );
    expect(
      PremiumDemoPlan.gatewayDayId(DateTime.parse('2026-10-30T17:00:00Z')),
      '2026-10-31',
    );
  });

  test(
    'plan and answer share stable turn ID; ambiguous retry is never replayed',
    () async {
      const requestId = 'OpaqueTurn12345678900';
      final today = DateTime(2026, 10, 31);
      final conversation = AssistantConversation(
        question: 'Gợi ý hình thành thói quen',
        history: const [],
        today: today,
        selectedDate: today,
        requestId: requestId,
      );
      final phases = <String>[];
      var duplicate = false, reads = 0;
      final assistant = CloudflareChatAssistant(
        endpoint: Uri.parse('https://example.test/v1/chat'),
        credentials: (_) async => const ChatApiCredentials('auth', 'appcheck'),
        clientFactory: () => MockClient((request) async {
          expect(request.headers['x-healthmate-request-id'], requestId);
          expect(request.body, isNot(contains(requestId)));
          if (duplicate) return http.Response('{}', 409);
          final phase = jsonDecode(request.body)['phase'] as String;
          phases.add(phase);
          if (phase == 'plan') return http.Response('{"requests":[]}', 200);
          return http.Response.bytes(
            utf8.encode(
              'data: {"response":"Chọn một thói quen nhỏ."}\n\ndata: [DONE]\n\n',
            ),
            200,
          );
        }),
      );
      Stream<String> reply() => assistant.reply(
        conversation,
        uid: 'alice',
        isCurrent: () => true,
        readData: (_) async {
          reads++;
          return [];
        },
      );
      expect(await reply().join(), contains('thói quen nhỏ'));
      expect(phases, ['plan', 'answer']);
      duplicate = true;
      await expectLater(
        reply().join(),
        throwsA(
          isA<ChatFailure>().having(
            (failure) => failure.message,
            'message',
            contains('chưa xác định kết quả'),
          ),
        ),
      );
      expect(phases, ['plan', 'answer']);
      expect(reads, 1);
    },
  );
}
