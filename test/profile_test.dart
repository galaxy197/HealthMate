import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/profile/models/profile_validation.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/test_app.dart';

void main() {
  group('profile validation and BMI', () {
    test('validates editable profile and metric values', () {
      expect(ProfileValidation.displayName('A'), isNotNull);
      expect(ProfileValidation.displayName(' An Nguyen '), isNull);
      expect(ProfileValidation.height(''), isNull);
      expect(ProfileValidation.height('79'), isNotNull);
      expect(ProfileValidation.height('170,5'), isNull);
      expect(ProfileValidation.weight('abc'), isNotNull);
      expect(ProfileValidation.weight('70.2'), isNull);
      expect(ProfileValidation.note('x' * 201), isNotNull);
    });

    test('calculates BMI only from valid height and weight', () {
      expect(
        ProfileValidation.bmi(heightCm: 170, weightKg: 70),
        closeTo(24.22, 0.01),
      );
      expect(ProfileValidation.bmi(heightCm: null, weightKg: 70), isNull);
      expect(ProfileValidation.bmi(heightCm: 170, weightKg: 10), isNull);
    });
  });

  testWidgets('updates profile and completes body metric CRUD', (tester) async {
    final repository = FakeHealthProfileRepository(
      profile: FakeHealthProfileRepository.testProfile,
    );
    final container = await pumpApp(tester, profileRepository: repository);
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Chưa có lần đo nào. Thêm cân nặng để bắt đầu theo dõi lịch sử.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('edit-profile')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-name')),
      'Nguyễn An',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-height')),
      '175,5',
    );
    await tester.tap(find.byKey(const ValueKey('save-profile')));
    await tester.pumpAndSettle();
    expect(repository.updateProfileCalls, 1);
    expect(find.text('Nguyễn An'), findsOneWidget);
    expect(find.text('Chiều cao: 175.5 cm'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('add-metric')));
    await tester.tap(find.byKey(const ValueKey('add-metric')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('metric-weight')), '70,2');
    await tester.enterText(
      find.byKey(const ValueKey('metric-note')),
      'Buổi sáng',
    );
    await tester.tap(find.byKey(const ValueKey('save-metric')));
    await tester.pumpAndSettle();
    expect(repository.addMetricCalls, 1);
    expect(find.text('70.2 kg'), findsOneWidget);
    expect(find.textContaining('BMI tham khảo:'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final editButton = find.byKey(const ValueKey('edit-metric-metric-1'));
    await tester.ensureVisible(editButton);
    await tester.tap(editButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('metric-weight')), '71.5');
    await tester.tap(find.byKey(const ValueKey('save-metric')));
    await tester.pumpAndSettle();
    expect(repository.updateMetricCalls, 1);
    expect(find.text('71.5 kg'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    final deleteButton = find.byKey(const ValueKey('delete-metric-metric-1'));
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-metric')));
    await tester.pumpAndSettle();
    expect(repository.deleteMetricCalls, 1);
    expect(find.text('71.5 kg'), findsNothing);
    expect(find.textContaining('Chưa có lần đo nào'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile bootstrap creates an empty profile once per session', (
    tester,
  ) async {
    final repository = FakeHealthProfileRepository();
    final container = await pumpApp(tester, profileRepository: repository);
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.text('Chưa đặt tên hiển thị'), findsOneWidget);
    expect(repository.ensureCalls, 1);
  });

  testWidgets(
    'sign-in transition bootstraps the profile without a screen visit',
    (tester) async {
      final auth = FakeAuthRepository();
      final repository = FakeHealthProfileRepository();
      await pumpApp(tester, repository: auth, profileRepository: repository);
      expect(repository.ensureCalls, 0);

      auth.emitUser(FakeAuthRepository.testUser);
      await tester.pumpAndSettle();
      expect(repository.ensureCalls, 1);
    },
  );
}
