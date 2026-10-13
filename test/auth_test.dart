import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/router/auth_redirect.dart';
import 'package:healthmate/core/widgets/startup_error_app.dart';
import 'package:healthmate/features/auth/models/auth_failure.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/models/auth_validation.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';

import 'support/fake_auth_repository.dart';
import 'support/test_app.dart';

Future<void> fillLogin(
  WidgetTester tester, {
  String password = 'strong-password',
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('auth-email')),
    '  member@example.com  ',
  );
  await tester.enterText(find.byKey(const ValueKey('auth-password')), password);
}

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('auth-submit')));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('auth-submit')));
}

void main() {
  group('validation and safe messages', () {
    test(
      'validates email and only enforces new-password policy when registering',
      () {
        expect(AuthValidation.email(''), isNotNull);
        expect(AuthValidation.email('wrong@'), isNotNull);
        expect(AuthValidation.email('a b@example.com'), isNotNull);
        expect(AuthValidation.email(' user+tag@example.com '), isNull);
        expect(AuthValidation.password('', registering: false), isNotNull);
        expect(AuthValidation.password('short', registering: false), isNull);
        expect(AuthValidation.password('short', registering: true), isNotNull);
        expect(AuthValidation.password('      ', registering: true), isNotNull);
        expect(AuthValidation.confirmation('abc123', 'abc124'), isNotNull);
        expect(AuthValidation.confirmation('abc123', 'abc123'), isNull);
      },
    );

    test(
      'credential errors share a friendly message; unknown errors expose no SDK detail',
      () {
        expect(
          AuthFailure.fromCode('wrong-password').message,
          AuthFailure.fromCode('user-not-found').message,
        );
        expect(
          AuthFailure.fromCode('invalid-credential').message,
          'Email hoặc mật khẩu chưa đúng.',
        );
        expect(
          AuthFailure.fromCode('network-request-failed').message,
          contains('Kiểm tra mạng'),
        );
        expect(
          AuthFailure.fromCode('internal-sensitive-detail').message,
          isNot(contains('internal-sensitive-detail')),
        );
      },
    );
  });

  test(
    'redirect blocks private routes while loading and logged out, sanitizes destination',
    () {
      expect(
        Uri.parse(
          authRedirect(const AsyncLoading<AuthUser?>(), Uri.parse('/journal'))!,
        ).path,
        AppRoutes.session,
      );
      expect(
        Uri.parse(
          authRedirect(
            const AsyncData<AuthUser?>(null),
            Uri.parse('/profile'),
          )!,
        ).path,
        AppRoutes.auth,
      );
      expect(
        authRedirect(
          const AsyncData(FakeAuthRepository.testUser),
          Uri.parse('/auth?from=https://evil.example'),
        ),
        AppRoutes.dashboard,
      );
      expect(
        authRedirect(
          const AsyncData(FakeAuthRepository.testUser),
          Uri.parse('/auth?from=%2Fjournal'),
        ),
        AppRoutes.journal,
      );
      expect(
        authRedirect(
          const AsyncData(FakeAuthRepository.testUser),
          Uri.parse('/profile'),
        ),
        isNull,
      );
    },
  );

  testWidgets('signed-out user cannot open a private route', (tester) async {
    final container = await pumpApp(tester, repository: FakeAuthRepository());
    expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.text('Không gian cá nhân'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('form validation prevents any repository request', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, repository: auth);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập email.'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
    expect(auth.signInCalls, 0);
  });

  testWidgets(
    'login trims email, preserves password and resumes intended route',
    (tester) async {
      final auth = FakeAuthRepository();
      final container = await pumpApp(tester, repository: auth);
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      await fillLogin(tester, password: ' password with spaces ');
      await submit(tester);
      await tester.pumpAndSettle();
      expect(auth.lastEmail, 'member@example.com');
      expect(auth.lastPassword, ' password with spaces ');
      expect(find.text('Nhật ký của bạn'), findsOneWidget);
    },
  );

  testWidgets(
    'registration checks confirmation then creates account and opens dashboard',
    (tester) async {
      final auth = FakeAuthRepository();
      await pumpApp(tester, repository: auth);
      await tester.tap(find.byKey(const ValueKey('auth-toggle')));
      await tester.pumpAndSettle();
      await fillLogin(tester);
      await tester.enterText(
        find.byKey(const ValueKey('auth-confirmation')),
        'mismatch',
      );
      await submit(tester);
      await tester.pumpAndSettle();
      expect(auth.registerCalls, 0);
      expect(find.text('Hai mật khẩu chưa khớp.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('auth-confirmation')),
        'strong-password',
      );
      await submit(tester);
      await tester.pumpAndSettle();
      expect(auth.registerCalls, 1);
      expect(find.text('Từng bước nhỏ,\nsống khỏe hơn.'), findsOneWidget);
    },
  );

  testWidgets('in-flight request disables submission and mode switch', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..pending = Completer<void>();
    final container = await pumpApp(tester, repository: auth);
    await fillLogin(tester);
    await submit(tester);
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('auth-submit')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('auth-toggle')))
          .onPressed,
      isNull,
    );
    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'duplicate@example.com', password: 'password');
    expect(auth.signInCalls, 1);
    auth.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Từng bước nhỏ,\nsống khỏe hơn.'), findsOneWidget);
  });

  testWidgets('network error is shown, password stays masked, retry succeeds', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..failure = AuthFailure.fromCode('network-request-failed');
    await pumpApp(tester, repository: auth);
    await fillLogin(tester);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(find.text(auth.failure!.message), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('auth-password')),
              matching: find.byType(TextField),
            ),
          )
          .obscureText,
      isTrue,
    );
    auth.failure = null;
    await submit(tester);
    await tester.pumpAndSettle();
    expect(auth.signInCalls, 2);
    expect(find.text('Từng bước nhỏ,\nsống khỏe hơn.'), findsOneWidget);
  });

  testWidgets(
    'session stays private until first auth event and responds to external sign-out',
    (tester) async {
      final auth = FakeAuthRepository()..emitInitial = false;
      await pumpApp(tester, repository: auth, settle: false);
      await tester.pump();
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      auth.emitUser(FakeAuthRepository.testUser);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      auth.emitUser(null);
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
    },
  );

  testWidgets('session stream error has a working retry', (tester) async {
    final auth = FakeAuthRepository()
      ..sessionError = StateError('test-only stream failure');
    await pumpApp(tester, repository: auth);
    expect(find.text('Chưa thể mở phiên đăng nhập'), findsOneWidget);
    expect(find.textContaining('test-only'), findsNothing);
    auth.sessionError = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
  });

  testWidgets('failed sign-out keeps account visible and can be retried', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: FakeAuthRepository.testUser)
      ..failure = AuthFailure.fromCode('network-request-failed');
    final container = await pumpApp(tester, repository: auth);
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('member@example.com'), findsWidgets);
    expect(find.text(auth.failure!.message), findsOneWidget);
    auth.failure = null;
    await tester.tap(find.byKey(const ValueKey('sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
  });

  testWidgets('auth forms fit a small screen, large text and keyboard inset', (
    tester,
  ) async {
    await pumpApp(
      tester,
      repository: FakeAuthRepository(),
      size: const Size(320, 640),
      textScale: 2,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('auth-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth-toggle')));
    await tester.pumpAndSettle();
    await submit(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Vui lòng nhập lại mật khẩu.'), findsOneWidget);
  });

  testWidgets('startup failure provides a retry without creating auth UI', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      StartupErrorApp(
        onRetry: () async {
          retries++;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa thể khởi động HealthMate'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(retries, 1);
  });
}
