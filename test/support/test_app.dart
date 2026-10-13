import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/app.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';
import 'package:healthmate/shared/providers/theme_mode_provider.dart';

import 'fake_account_data_repository.dart';
import 'fake_activity_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_health_profile_repository.dart';
import 'fake_nutrition_repository.dart';
import 'fake_water_repository.dart';
import 'fake_theme_preference_store.dart';

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  FakeAuthRepository? repository,
  FakeHealthProfileRepository? profileRepository,
  FakeNutritionRepository? nutritionRepository,
  FakeWaterRepository? waterRepository,
  FakeActivityRepository? activityRepository,
  FakeAccountDataRepository? accountDataRepository,
  FakeThemePreferenceStore? themePreferenceStore,
  ThemeMode initialThemeMode = ThemeMode.system,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final auth =
      repository ?? FakeAuthRepository(user: FakeAuthRepository.testUser);
  final healthProfile =
      profileRepository ??
      FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      );
  final nutrition = nutritionRepository ?? FakeNutritionRepository();
  final water = waterRepository ?? FakeWaterRepository();
  final activity = activityRepository ?? FakeActivityRepository();
  final accountData = accountDataRepository ?? FakeAccountDataRepository();
  final themeStore = themePreferenceStore ?? FakeThemePreferenceStore();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      healthProfileRepositoryProvider.overrideWithValue(healthProfile),
      nutritionRepositoryProvider.overrideWithValue(nutrition),
      waterRepositoryProvider.overrideWithValue(water),
      activityRepositoryProvider.overrideWithValue(activity),
      accountDataRepositoryProvider.overrideWithValue(accountData),
      themePreferenceStoreProvider.overrideWithValue(themeStore),
      initialThemeModeProvider.overrideWithValue(initialThemeMode),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await auth.dispose();
    await healthProfile.dispose();
    await nutrition.dispose();
    await water.dispose();
    await activity.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const HealthMateApp(),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return container;
}
