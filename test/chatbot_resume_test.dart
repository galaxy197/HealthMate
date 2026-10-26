import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/chatbot/models/chat_models.dart';
import 'package:healthmate/features/chatbot/providers/chat_providers.dart';
import 'package:healthmate/features/chatbot/providers/chat_resume_provider.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_chat_repository.dart';
import 'support/test_app.dart';

final now = DateTime(2026, 10, 25, 12);
const flags = AppFeatureFlags(chatbotEnabled: true);

void main() {
  testWidgets(
    'returning to chat restores completed messages, selected older chat and explicit new chat',
    (t) async {
      final repo = FakeChatRepository();
      final ai = FakeKnowledgeService();
      final c = await pumpApp(
        t,
        featureFlags: flags,
        chatRepository: repo,
        knowledgeService: ai,
      );
      Future<void> visit(String route) async {
        c.read(appRouterProvider).go(route);
        await t.pumpAndSettle();
      }

      await visit(AppRoutes.chat);
      await c.read(chatControllerProvider.notifier).send('Nước đã ghi', now);
      await t.pumpAndSettle();
      final firstId = c.read(chatControllerProvider).sessionId;
      final text = c.read(chatControllerProvider).messages.last.text;
      await visit(AppRoutes.dashboard);
      await visit(AppRoutes.chat);
      expect(c.read(chatControllerProvider).sessionId, firstId);
      expect(c.read(chatControllerProvider).messages.last.text, text);
      expect(ai.topics, isEmpty);
      expect(repo.saveCalls, 1);

      c.read(chatControllerProvider.notifier).newSession();
      await visit(AppRoutes.dashboard);
      await visit(AppRoutes.chat);
      expect(c.read(chatControllerProvider).sessionId, isNull);
      expect(c.read(chatControllerProvider).messages, isEmpty);
      await c
          .read(chatControllerProvider.notifier)
          .send('Vận động đã ghi', now);
      await t.pumpAndSettle();
      expect(c.read(chatControllerProvider).sessionId, isNot(firstId));
      await c.read(chatControllerProvider.notifier).openSession(firstId!);
      await visit(AppRoutes.dashboard);
      await visit(AppRoutes.chat);
      expect(c.read(chatControllerProvider).sessionId, firstId);
      expect(c.read(chatControllerProvider).messages.last.text, text);
      expect(repo.saveCalls, 2);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'a cold entry loads the most recent saved conversation without AI',
    (t) async {
      final repo = FakeChatRepository();
      await repo.saveTurn(
        'test-uid',
        'saved-session',
        const ChatTurn(
          id: 'aaaaaaaaaaaaaaaaaaaa',
          question: 'Nước đã ghi',
          answer: 'Nhật ký đã lưu',
          source: ChatSource.journal,
        ),
      );
      final c = await pumpApp(t, featureFlags: flags, chatRepository: repo);
      c.read(appRouterProvider).go(AppRoutes.chat);
      await t.pumpAndSettle();
      expect(c.read(chatControllerProvider).sessionId, 'saved-session');
      expect(
        c.read(chatControllerProvider).messages.last.text,
        'Nhật ký đã lưu',
      );
      expect(repo.saveCalls, 1);
    },
  );

  testWidgets(
    'history load failure does not replace the selection and refresh restores it',
    (t) async {
      final repo = FakeChatRepository();
      final c = await pumpApp(t, featureFlags: flags, chatRepository: repo);
      c.read(appRouterProvider).go(AppRoutes.chat);
      await t.pumpAndSettle();
      await c.read(chatControllerProvider.notifier).send('Nước đã ghi', now);
      final id = c.read(chatControllerProvider).sessionId;
      c.read(appRouterProvider).go(AppRoutes.dashboard);
      await t.pumpAndSettle();
      repo.failLoad = true;
      c.read(appRouterProvider).go(AppRoutes.chat);
      await t.pumpAndSettle();
      expect(c.read(chatControllerProvider).error, isNotNull);
      expect(c.read(chatResumeProvider).sessionId, id);
      repo.failLoad = false;
      await c.read(chatControllerProvider.notifier).loadSessions();
      await t.pumpAndSettle();
      expect(c.read(chatControllerProvider).sessionId, id);
      expect(c.read(chatControllerProvider).messages.length, 2);
    },
  );

  testWidgets(
    'a save completing off-tab cannot override a newer blank selection',
    (t) async {
      final repo = FakeChatRepository();
      final c = await pumpApp(t, featureFlags: flags, chatRepository: repo);
      c.read(appRouterProvider).go(AppRoutes.chat);
      await t.pumpAndSettle();
      repo.pendingSave = Completer<void>();
      final send = c
          .read(chatControllerProvider.notifier)
          .send('Nước đã ghi', now);
      await t.pump();
      expect(c.read(chatControllerProvider).phase, ChatPhase.saving);
      c.read(appRouterProvider).go(AppRoutes.dashboard);
      await t.pumpAndSettle();
      c.read(appRouterProvider).go(AppRoutes.chat);
      await t.pumpAndSettle();
      c.read(chatControllerProvider.notifier).newSession();
      repo.pendingSave!.complete();
      await send;
      await t.pumpAndSettle();
      expect(c.read(chatResumeProvider).selected, true);
      expect(c.read(chatResumeProvider).sessionId, isNull);
      expect(c.read(chatControllerProvider).messages, isEmpty);
    },
  );

  testWidgets(
    'UID changes clear selection and reject late selections from the old UID',
    (t) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final c = await pumpApp(t, featureFlags: flags, repository: auth);
      c.read(appRouterProvider).go(AppRoutes.chat);
      await t.pumpAndSettle();
      final resume = c.read(chatResumeProvider.notifier);
      resume.select('test-uid', 'alice-session');
      final revision = c.read(chatResumeProvider).revision;
      auth.emitUser(
        const AuthUser(
          uid: 'bob',
          email: 'bob@example.com',
          emailVerified: true,
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(c.read(chatResumeProvider).uid, 'bob');
      expect(c.read(chatResumeProvider).sessionId, isNull);
      resume.select('test-uid', 'alice-session', expectedRevision: revision);
      expect(c.read(chatResumeProvider).sessionId, isNull);
      expect(c.read(chatControllerProvider).messages, isEmpty);
      expect(t.takeException(), isNull);
    },
  );
}
