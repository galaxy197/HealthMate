import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/support/data/support_repository.dart';
import 'package:healthmate/features/support/models/support_models.dart';
import 'package:healthmate/features/support/presentation/support_screen.dart';
import 'package:healthmate/features/support/providers/support_providers.dart';

const user = AuthUser(
  uid: 'alice',
  email: 'alice@example.com',
  emailVerified: true,
);
final now = DateTime.utc(2026, 10, 30, 14);
SupportTicket ticket({SupportStatus status = SupportStatus.resolved}) =>
    SupportTicket(
      id: 'AbCdEfGhIjKlMnOpQrSt',
      uid: 'alice',
      type: SupportType.bug,
      title: 'Không lưu được bữa sáng',
      description: 'Bấm lưu nhưng không thấy món.',
      status: status,
      createdAt: now,
      updatedAt: now,
      messageCount: 1,
    );

class FakeSupport implements SupportRepository {
  bool fail = false, listError = false;
  final created = <String>[], replied = <String>[];
  int ids = 0;
  int ticketWatches = 0;
  @override
  String newId() => '${++ids}'.padLeft(20, 'A');
  @override
  Stream<List<SupportTicket>> watchTickets(String uid) {
    ticketWatches++;
    return listError
        ? Stream.error(const SupportFailure('Mất kết nối thử nghiệm'))
        : Stream.value([]);
  }

  @override
  Stream<SupportTicket?> watchTicket(String uid, String id) =>
      Stream.value(ticket());
  @override
  Stream<List<SupportMessage>> watchMessages(String uid, String id) =>
      Stream.value([
        SupportMessage(
          id: 'reply',
          text: 'Bạn vui lòng cập nhật ứng dụng rồi thử lại.',
          isAdmin: true,
          createdAt: now,
          sequence: 1,
        ),
      ]);
  @override
  Future<void> create(
    String uid,
    String id,
    SupportType type,
    String title,
    String description,
  ) async {
    created.add(id);
    if (fail) throw const SupportFailure('Chưa xác nhận gửi yêu cầu');
  }

  @override
  Future<void> reply(
    String uid,
    String ticketId,
    String messageId,
    String text,
  ) async {
    replied.add(messageId);
    if (fail) throw const SupportFailure('Chưa xác nhận gửi tin nhắn');
  }
}

Future<void> open(
  WidgetTester tester,
  FakeSupport repository, {
  Widget? home,
  double scale = 1,
  Stream<AuthUser?>? auth,
}) async {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith((ref) => auth ?? Stream.value(user)),
        supportRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: home ?? const SupportScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> fillTicket(WidgetTester tester) async {
  await tapKey(tester, 'new-support-ticket');
  await tester.enterText(
    find.byKey(const ValueKey('support-title')),
    'Lỗi ghi nhận bữa sáng',
  );
  await tester.enterText(
    find.byKey(const ValueKey('support-description')),
    'Bấm lưu nhưng không thấy món.',
  );
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'hidden navigation branch releases support listeners and reconnects on return',
    (tester) async {
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      final repository = FakeSupport();
      await open(
        tester,
        repository,
        home: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (context, value, child) =>
              TickerMode(enabled: value, child: const SupportScreen()),
        ),
      );
      expect(repository.ticketWatches, 1);
      visible.value = false;
      await tester.pumpAndSettle();
      expect(find.text('Yêu cầu của bạn'), findsNothing);
      visible.value = true;
      await tester.pumpAndSettle();
      expect(repository.ticketWatches, 2);
    },
  );
  test(
    'support text trims, rejects empty and excessive Unicode character count',
    () {
      expect(supportText('  góp ý  ', 120, 'Tiêu đề'), 'góp ý');
      expect(
        () => supportText(' \n ', 120, 'Tiêu đề'),
        throwsA(isA<SupportFailure>()),
      );
      expect(supportText('😀' * 120, 120, 'Tiêu đề').runes.length, 120);
      expect(
        () => supportText('x' * 2001, 2000, 'Nội dung'),
        throwsA(isA<SupportFailure>()),
      );
    },
  );
  testWidgets(
    'empty list, create validation and cancel do not write; confirmed valid submit writes once',
    (tester) async {
      final repository = FakeSupport();
      await open(tester, repository);
      expect(find.textContaining('Chưa có yêu cầu'), findsOneWidget);
      await tapKey(tester, 'new-support-ticket');
      await tapKey(tester, 'send-support-ticket');
      expect(repository.created, isEmpty);
      expect(find.textContaining('Tiêu đề cần'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(repository.created, isEmpty);
      await fillTicket(tester);
      await tapKey(tester, 'send-support-ticket');
      expect(repository.created.length, 1);
      expect(find.text('Yêu cầu của bạn'), findsOneWidget);
    },
  );
  testWidgets(
    'uncertain create failure retains draft and transaction ID on retry',
    (tester) async {
      final repository = FakeSupport()..fail = true;
      await open(tester, repository);
      await fillTicket(tester);
      await tapKey(tester, 'send-support-ticket');
      expect(find.textContaining('Chưa xác nhận'), findsOneWidget);
      expect(find.text('Lỗi ghi nhận bữa sáng'), findsOneWidget);
      repository.fail = false;
      await tapKey(tester, 'send-support-ticket');
      expect(repository.created.length, 2);
      expect(repository.created[0], repository.created[1]);
    },
  );
  testWidgets(
    'admin answer and resolved state are visible, reply retry keeps ID and clears only after ACK',
    (tester) async {
      final repository = FakeSupport()..fail = true;
      await open(
        tester,
        repository,
        home: const SupportThreadScreen(ticketId: 'AbCdEfGhIjKlMnOpQrSt'),
      );
      expect(find.textContaining('Đã giải quyết'), findsOneWidget);
      expect(
        find.text('Bạn vui lòng cập nhật ứng dụng rồi thử lại.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('support-reply')));
      await tester.enterText(
        find.byKey(const ValueKey('support-reply')),
        'Mình đã thử nhưng vẫn lỗi.',
      );
      tester.testTextInput.hide();
      await tapKey(tester, 'send-support-reply');
      expect(repository.replied.length, 1);
      expect(find.textContaining('Chưa xác nhận gửi tin'), findsOneWidget);
      repository.fail = false;
      await tapKey(tester, 'send-support-reply');
      expect(repository.replied[0], repository.replied[1]);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('support-reply')))
            .controller!
            .text,
        '',
      );
    },
  );
  testWidgets(
    'failed list offers reload and recovers without fake empty data',
    (tester) async {
      final repository = FakeSupport()..listError = true;
      await open(tester, repository);
      expect(find.text('Mất kết nối thử nghiệm'), findsOneWidget);
      repository.listError = false;
      await tester.tap(find.text('Tải lại'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa có yêu cầu'), findsOneWidget);
    },
  );
  testWidgets('account switch hides the previous account draft', (
    tester,
  ) async {
    final auth = StreamController<AuthUser?>();
    addTearDown(auth.close);
    final repository = FakeSupport();
    await open(tester, repository, auth: auth.stream);
    auth.add(user);
    await tester.pumpAndSettle();
    await fillTicket(tester);
    auth.add(
      const AuthUser(uid: 'bob', email: 'bob@example.com', emailVerified: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lỗi ghi nhận bữa sáng'), findsNothing);
    expect(repository.created, isEmpty);
  });
  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('support screen and thread fit 320px at text scale $scale', (
      tester,
    ) async {
      await open(tester, FakeSupport(), scale: scale);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await open(
        tester,
        FakeSupport(),
        scale: scale,
        home: const SupportThreadScreen(ticketId: 'AbCdEfGhIjKlMnOpQrSt'),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
