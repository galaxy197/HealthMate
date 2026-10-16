import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/app.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/chatbot/providers/chat_providers.dart';
import 'package:healthmate/features/food_scanner/data/food_image_picker.dart';
import 'package:healthmate/features/food_scanner/data/food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/providers/food_scanner_providers.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/dashboard/providers/dashboard_providers.dart';
import 'package:healthmate/features/goals/providers/goals_providers.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';
import 'package:healthmate/shared/providers/theme_mode_provider.dart';
import 'package:healthmate/shared/providers/local_clock_provider.dart';

import 'fake_account_data_repository.dart';
import 'fake_chat_repository.dart';
import 'fake_activity_repository.dart';
import 'fake_goals_repository.dart';
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
  FakeChatRepository? chatRepository,
  FakeKnowledgeService? knowledgeService,
  FoodImagePicker? foodImagePicker,
  FoodScannerService? foodScannerService,
  FakeHealthProfileRepository? profileRepository,
  FakeNutritionRepository? nutritionRepository,
  FakeWaterRepository? waterRepository,
  FakeActivityRepository? activityRepository,
  FakeGoalsRepository? goalsRepository,
  FakeAccountDataRepository? accountDataRepository,
  FakeThemePreferenceStore? themePreferenceStore,
  ThemeMode initialThemeMode = ThemeMode.system,
  DateTime? dashboardNow,
  DateTime Function()? dashboardNowSource,
  DateTime Function()? goalsNow,
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
  final goals = goalsRepository ?? FakeGoalsRepository();
  final accountData = accountDataRepository ?? FakeAccountDataRepository();
  final themeStore = themePreferenceStore ?? FakeThemePreferenceStore();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      if (foodImagePicker != null)
        foodImagePickerProvider.overrideWithValue(foodImagePicker),
      if (foodScannerService != null)
        foodScannerServiceProvider.overrideWithValue(foodScannerService),
      chatRepositoryProvider.overrideWithValue(
        chatRepository ?? FakeChatRepository(),
      ),
      knowledgeServiceProvider.overrideWithValue(
        knowledgeService ?? FakeKnowledgeService(),
      ),
      healthProfileRepositoryProvider.overrideWithValue(healthProfile),
      nutritionRepositoryProvider.overrideWithValue(nutrition),
      waterRepositoryProvider.overrideWithValue(water),
      activityRepositoryProvider.overrideWithValue(activity),
      goalsRepositoryProvider.overrideWithValue(goals),
      if (goalsNow != null)
        goalsClockProvider.overrideWith((ref) => goalsNow())
      else
        goalsClockProvider.overrideWithValue(dashboardNow ?? DateTime.now()),
      accountDataRepositoryProvider.overrideWithValue(accountData),
      themePreferenceStoreProvider.overrideWithValue(themeStore),
      initialThemeModeProvider.overrideWithValue(initialThemeMode),
      currentLocalTimeProvider.overrideWithValue(
        dashboardNowSource ?? () => dashboardNow ?? DateTime.now(),
      ),
      if (dashboardNowSource != null)
        dashboardClockProvider.overrideWith((ref) => dashboardNowSource())
      else
        dashboardClockProvider.overrideWithValue(
          dashboardNow ?? DateTime.now(),
        ),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await auth.dispose();
    await healthProfile.dispose();
    await nutrition.dispose();
    await water.dispose();
    await activity.dispose();
    await goals.dispose();
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
