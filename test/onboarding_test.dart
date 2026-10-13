import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/profile/models/body_metric.dart';
import 'package:healthmate/features/profile/models/health_goal.dart';
import 'package:healthmate/features/profile/models/profile_failure.dart';
import 'package:healthmate/features/profile/models/profile_validation.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';

import 'support/fake_health_profile_repository.dart';
import 'support/test_app.dart';

UserProfile legacyProfile({
  String displayName = 'Nguyễn An',
  double? heightCm = 170,
  DateTime? birthDate,
  HealthGoal? healthGoal,
  DateTime? completedAt,
}) => UserProfile(
  uid: 'test-uid',
  displayName: displayName,
  email: 'member@example.com',
  heightCm: heightCm,
  birthDate: birthDate,
  healthGoal: healthGoal,
  targetWeightKg: null,
  onboardingCompletedAt: completedAt,
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
  schemaVersion: 1,
);

BodyMetric currentWeight(double weightKg) => BodyMetric(
  id: 'existing-weight',
  weightKg: weightKg,
  measuredAt: DateTime(2026, 10, 1),
  note: '',
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
);

Future<void> tapOnboardingButton(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> reachGoalStep(WidgetTester tester) async {
  await tapOnboardingButton(tester, 'onboarding-next');
  expect(find.byKey(const ValueKey('onboarding-goal-step')), findsOneWidget);
}

Future<void> reachReviewForWeightLoss(WidgetTester tester) async {
  await reachGoalStep(tester);
  await tester.tap(find.byKey(const ValueKey('onboarding-goal-lose_weight')));
  await tapOnboardingButton(tester, 'onboarding-next');
  expect(find.byKey(const ValueKey('onboarding-target-step')), findsOneWidget);
  await tester.enterText(
    find.byKey(const ValueKey('onboarding-target-weight')),
    '62.5',
  );
  await tapOnboardingButton(tester, 'onboarding-next');
  expect(find.byKey(const ValueKey('onboarding-review-step')), findsOneWidget);
}

void main() {
  test('validates onboarding-specific profile values', () {
    final today = DateTime(2026, 10, 13);
    expect(ProfileValidation.requiredHeight(''), isNotNull);
    expect(ProfileValidation.birthDate(null, today: today), isNotNull);
    expect(
      ProfileValidation.birthDate(DateTime(2015, 10, 14), today: today),
      isNotNull,
    );
    expect(
      ProfileValidation.birthDate(DateTime(2000, 1, 15), today: today),
      isNull,
    );
    expect(
      ProfileValidation.targetWeight('', HealthGoal.loseWeight),
      isNotNull,
    );
    expect(
      ProfileValidation.targetWeight('', HealthGoal.healthierHabits),
      isNull,
    );
  });

  testWidgets('new user without setup is sent to onboarding', (tester) async {
    final repository = FakeHealthProfileRepository(
      profile: FakeHealthProfileRepository.incompleteProfile,
    );
    final container = await pumpApp(tester, profileRepository: repository);

    expect(find.text('Thiết lập sức khỏe ban đầu'), findsOneWidget);
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      AppRoutes.onboarding,
    );
    expect(repository.ensureCalls, 1);
  });

  testWidgets('completed user opens the requested app route', (tester) async {
    final container = await pumpApp(tester);
    expect(find.text('Từng bước nhỏ,\nsống khỏe hơn.'), findsOneWidget);
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      AppRoutes.dashboard,
    );
  });

  testWidgets(
    'legacy profile missing onboarding data is guided to complete it',
    (tester) async {
      final repository = FakeHealthProfileRepository(
        profile: legacyProfile(),
        metrics: [currentWeight(70)],
      );
      await pumpApp(tester, profileRepository: repository);

      expect(find.text('Thiết lập sức khỏe ban đầu'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('onboarding-name')),
            )
            .controller!
            .text,
        'Nguyễn An',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('onboarding-weight')),
            )
            .controller!
            .text,
        '70.0',
      );
    },
  );

  testWidgets('required physical information is validated before continuing', (
    tester,
  ) async {
    final repository = FakeHealthProfileRepository(
      profile: FakeHealthProfileRepository.incompleteProfile,
    );
    await pumpApp(tester, profileRepository: repository);

    await tapOnboardingButton(tester, 'onboarding-next');
    expect(find.text('Tên hiển thị cần ít nhất 2 ký tự.'), findsOneWidget);
    expect(find.text('Vui lòng chọn ngày sinh.'), findsOneWidget);
    expect(find.text('Vui lòng nhập chiều cao.'), findsOneWidget);
    expect(find.text('Cân nặng phải là một số hợp lệ.'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-body-step')), findsOneWidget);
    expect(repository.completeOnboardingCalls, 0);
  });

  testWidgets('back navigation preserves data entered in earlier steps', (
    tester,
  ) async {
    final repository = FakeHealthProfileRepository(
      profile: legacyProfile(birthDate: DateTime(2000, 1, 15)),
      metrics: [currentWeight(70)],
    );
    await pumpApp(tester, profileRepository: repository);

    await reachGoalStep(tester);
    await tapOnboardingButton(tester, 'onboarding-back');
    expect(find.byKey(const ValueKey('onboarding-body-step')), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('onboarding-name')))
          .controller!
          .text,
      'Nguyễn An',
    );
  });

  testWidgets('completion saves profile and weight then opens dashboard', (
    tester,
  ) async {
    final repository = FakeHealthProfileRepository(
      profile: legacyProfile(birthDate: DateTime(2000, 1, 15)),
      metrics: [currentWeight(70)],
    );
    final container = await pumpApp(tester, profileRepository: repository);

    await reachReviewForWeightLoss(tester);
    expect(find.text('Giảm cân'), findsOneWidget);
    expect(find.text('62.5 kg'), findsOneWidget);
    await tapOnboardingButton(tester, 'onboarding-complete');

    expect(repository.completeOnboardingCalls, 1);
    expect(repository.lastOnboardingDraft?.currentWeightKg, 70);
    expect(repository.lastOnboardingDraft?.targetWeightKg, 62.5);
    expect(repository.currentProfile?.isOnboardingComplete, isTrue);
    expect(
      repository.metrics
          .where((metric) => metric.id == 'onboarding-current')
          .single
          .weightKg,
      70,
    );
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      AppRoutes.dashboard,
    );
    expect(find.text('Từng bước nhỏ,\nsống khỏe hơn.'), findsOneWidget);
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    expect(find.text('Mục tiêu: Giảm cân'), findsOneWidget);
    expect(find.text('Cân nặng mục tiêu: 62.5 kg'), findsOneWidget);
  });

  testWidgets('save failure stays on review and can be retried', (
    tester,
  ) async {
    final repository = FakeHealthProfileRepository(
      profile: legacyProfile(birthDate: DateTime(2000, 1, 15)),
      metrics: [currentWeight(70)],
    );
    await pumpApp(tester, profileRepository: repository);
    await reachReviewForWeightLoss(tester);
    repository.failure = const ProfileFailure('Không thể lưu thử nghiệm.');

    await tapOnboardingButton(tester, 'onboarding-complete');
    expect(find.text('Không thể lưu thử nghiệm.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-review-step')),
      findsOneWidget,
    );
    expect(repository.completeOnboardingCalls, 1);

    repository.failure = null;
    await tapOnboardingButton(tester, 'onboarding-complete');
    expect(repository.completeOnboardingCalls, 2);
    expect(find.text('Từng bước nhỏ,\nsống khỏe hơn.'), findsOneWidget);
  });

  testWidgets('save action is disabled while the transaction is pending', (
    tester,
  ) async {
    final repository = FakeHealthProfileRepository(
      profile: legacyProfile(birthDate: DateTime(2000, 1, 15)),
      metrics: [currentWeight(70)],
    );
    await pumpApp(tester, profileRepository: repository);
    await reachReviewForWeightLoss(tester);
    repository.pending = Completer<void>();

    final buttonFinder = find.byKey(const ValueKey('onboarding-complete'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.tap(buttonFinder);
    await tester.pump();

    expect(tester.widget<FilledButton>(buttonFinder).onPressed, isNull);
    expect(repository.completeOnboardingCalls, 1);
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Từng bước nhỏ,\nsống khỏe hơn.'), findsOneWidget);
  });
}
