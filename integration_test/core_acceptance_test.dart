// Opt-in Android acceptance against the local demo backend only. Never call the
// production main/bootstrap, use a real account, or use the default Firebase app.
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:healthmate/app.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:healthmate/core/utils/local_date_key.dart';
import 'package:healthmate/features/auth/data/firebase_auth_repository.dart';
import 'package:healthmate/features/auth/data/firebase_account_data_repository.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/chatbot/providers/chat_providers.dart';
import 'package:healthmate/features/food_scanner/providers/food_scanner_providers.dart';
import 'package:healthmate/features/food_library/data/firebase_favorite_food_repository.dart';
import 'package:healthmate/features/food_library/data/firebase_food_library_repository.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';
import 'package:healthmate/features/food_library/providers/favorite_food_providers.dart';
import 'package:healthmate/features/food_library/providers/food_library_providers.dart';
import 'package:healthmate/features/nutrition/data/firebase_nutrition_repository.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition_targets/data/firebase_nutrition_target_repository.dart';
import 'package:healthmate/features/nutrition_targets/models/nutrition_target.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/profile/data/firebase_health_profile_repository.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/water/data/firebase_water_repository.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';
import 'package:healthmate/features/activity/data/firebase_activity_repository.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/goals/data/firebase_goals_repository.dart';
import 'package:healthmate/features/goals/providers/goals_providers.dart';

const _project = 'demo-healthmate-rules';
const _host = '10.0.2.2';
const _password = 'Synthetic-C6-only-123!';
const _catalogId = 'c6-synthetic-rice';
final _today = localDateOnly(DateTime.now());
final _yesterday = DateTime(_today.year, _today.month, _today.day - 1);
Finder keyed(String key) => find.byKey(ValueKey(key));

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  bool absent = false,
}) async {
  final until = DateTime.now().add(const Duration(seconds: 35));
  while ((finder.evaluate().isEmpty) != absent) {
    if (DateTime.now().isAfter(until)) {
      fail('Timed out waiting for ${absent ? "absence of " : ""}$finder');
    }
    await tester.pump(const Duration(milliseconds: 150));
  }
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  // ListView constructs fields lazily. Scroll only the current vertical form.
  for (var attempt = 0; finder.evaluate().isEmpty && attempt < 25; attempt++) {
    final scroll = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .last;
    await tester.drag(scroll, const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 150));
  }
  expect(finder, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(finder), alignment: .3);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  // Wait for the native IME resize before scrolling to a separate action.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 500));
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> enter(WidgetTester tester, String key, String value) async {
  final finder = keyed(key);
  await reveal(tester, finder);
  await tester.enterText(finder, value);
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> pickDate(WidgetTester tester, DateTime date) async {
  await waitFor(tester, find.byType(DatePickerDialog));
  final context = tester.element(find.byType(DatePickerDialog));
  final tooltip = MaterialLocalizations.of(context).inputDateModeButtonLabel;
  await tap(tester, find.byTooltip(tooltip));
  final input = find.descendant(
    of: find.byType(DatePickerDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(
    input,
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
  );
  final confirm =
      tester
          .widget<DatePickerDialog>(find.byType(DatePickerDialog))
          .confirmText ??
      MaterialLocalizations.of(context).okButtonLabel;
  await tap(tester, find.widgetWithText(TextButton, confirm));
  await waitFor(tester, find.byType(DatePickerDialog), absent: true);
}

Future<void> register(WidgetTester tester, String email) async {
  await waitFor(tester, keyed('auth-toggle'));
  await tap(tester, keyed('auth-toggle'));
  await enter(tester, 'auth-email', email);
  await enter(tester, 'auth-password', _password);
  await enter(tester, 'auth-confirmation', _password);
  await tap(tester, keyed('auth-submit'));
  await waitFor(tester, keyed('onboarding-name'));
}

Future<void> onboard(WidgetTester tester, String name) async {
  await enter(tester, 'onboarding-name', name);
  await tap(tester, keyed('onboarding-birth-date'));
  await pickDate(tester, DateTime(2000, 1, 15));
  await enter(tester, 'onboarding-height', '170');
  await enter(tester, 'onboarding-weight', '70');
  await tap(tester, keyed('onboarding-next'));
  await tap(tester, keyed('onboarding-goal-maintain_weight'));
  await tap(tester, keyed('onboarding-next'));
  await tap(tester, keyed('onboarding-next'));
  await tap(tester, keyed('onboarding-complete'));
  // Auth restores the protected destination (Profile after signing out there).
  // First verify that onboarding exits into the real app shell, then open Home.
  await waitFor(tester, keyed('nav-dashboard'));
  await tap(tester, keyed('nav-dashboard'));
  await waitFor(tester, keyed('dashboard-screen'));
}

Future<void> seedCatalog() async {
  // Guarded static localhost/demo endpoint; the application cannot write catalog.
  final response = await http.patch(
    Uri.parse(
      'http://$_host:8080/v1/projects/$_project/databases/(default)/documents/food_catalog/$_catalogId',
    ),
    headers: {
      'Authorization': 'Bearer owner',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'fields': {
        'name': {'stringValue': 'Cơm fixture C6'},
        'category': {'stringValue': 'Synthetic QA'},
        'servingBasis': {'stringValue': 'per_100g'},
        'unit': {'stringValue': 'g'},
        'kcalPer100g': {'doubleValue': 130},
        'proteinGPer100g': {'doubleValue': 3},
        'carbsGPer100g': {'doubleValue': 28},
        'fatGPer100g': {'doubleValue': .3},
        'sourceLabel': {
          'stringValue': 'Synthetic emulator fixture, not nutrition reference',
        },
        'isEstimated': {'booleanValue': true},
      },
    }),
  );
  expect(response.statusCode, 200);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!const bool.fromEnvironment('HEALTHMATE_CORE_EMULATOR_TESTS') ||
      !Platform.isAndroid ||
      !_project.startsWith('demo-') ||
      const bool.fromEnvironment('HEALTHMATE_ENABLE_CHATBOT') ||
      const bool.fromEnvironment('HEALTHMATE_ENABLE_FOOD_SCANNER')) {
    throw StateError(
      'Use the Android QA runner with the fixed demo backend and AI disabled.',
    );
  }

  testWidgets(
    'C6 Android core acceptance with real Firebase repositories',
    (tester) async {
      final app = await Firebase.initializeApp(
        name: 'healthmate-core-c6-qa',
        options: const FirebaseOptions(
          apiKey: 'emulator-only-fake-api-key',
          appId: '1:1234567890:android:0123456789abcdef',
          messagingSenderId: '1234567890',
          projectId: _project,
        ),
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.useAuthEmulator(_host, 9099, automaticHostMapping: false);
      final db = FirebaseFirestore.instanceFor(app: app);
      db.settings = const Settings(persistenceEnabled: false);
      db.useFirestoreEmulator(_host, 8080, automaticHostMapping: false);
      await auth.signOut(); // Named QA app only, never the default app/session.
      final nutrition = FirebaseNutritionRepository(db);
      final profile = FirebaseHealthProfileRepository(db);
      final targets = FirebaseNutritionTargetRepository(db);
      final library = FirebaseFoodLibraryRepository(db);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FirebaseAuthRepository(auth),
          ),
          accountDataRepositoryProvider.overrideWithValue(
            FirebaseAccountDataRepository(db),
          ),
          healthProfileRepositoryProvider.overrideWithValue(profile),
          nutritionRepositoryProvider.overrideWithValue(nutrition),
          nutritionTargetRepositoryProvider.overrideWithValue(targets),
          foodLibraryRepositoryProvider.overrideWithValue(library),
          favoriteFoodRepositoryProvider.overrideWithValue(
            FirebaseFavoriteFoodRepository(db),
          ),
          waterRepositoryProvider.overrideWithValue(
            FirebaseWaterRepository(db),
          ),
          activityRepositoryProvider.overrideWithValue(
            FirebaseActivityRepository(db),
          ),
          goalsRepositoryProvider.overrideWithValue(
            FirebaseGoalsRepository(db),
          ),
        ],
      );
      addTearDown(() async {
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 500));
        container.dispose();
        await db.enableNetwork();
        await db.terminate();
        await auth.signOut();
        await app.delete();
      });
      await seedCatalog();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HealthMateApp(),
        ),
      );
      final suffix = DateTime.now().microsecondsSinceEpoch;
      final emailA = 'c6-alice-$suffix@example.com',
          emailB = 'c6-bob-$suffix@example.com';
      Future<void> checkpoint(String label) async {
        debugPrint('C6_CHECKPOINT $label');
        expect(tester.takeException(), isNull);
      }

      var surfaceConverted = false;
      Future<void> capture(String name) async {
        if (!surfaceConverted) {
          await binding.convertFlutterSurfaceToImage();
          surfaceConverted = true;
        }
        await tester.pump();
        final bytes = await binding.takeScreenshot(name);
        expect(bytes, isNotEmpty);
      }

      Future<void> profileRoot() async {
        await tap(tester, keyed('nav-profile'));
        if (keyed('open-food-library').evaluate().isEmpty) {
          // A tab remembers its library route; a second tap returns to its root.
          await tap(tester, keyed('nav-profile'));
        }
      }

      await register(tester, emailA);
      await onboard(tester, 'C6 QA Alice');
      final alice = auth.currentUser!.uid;
      expect(
        (await profile.watchProfile(alice).first)!.isOnboardingComplete,
        isTrue,
      );
      await checkpoint('01-auth-onboarding');
      // Precondition: an existing historical target, never backdated via product UI.
      await FirebaseNutritionTargetRepository(db, now: () => _yesterday).save(
        alice,
        NutritionTarget(
          effectiveFromDateKey: localDateKey(_yesterday),
          kcalTarget: 1800,
        ),
      );
      container.invalidate(nutritionTargetProvider);
      await tap(tester, keyed('edit-nutrition-target-${localDateKey(_today)}'));
      await enter(tester, 'target-kcal', '2000');
      await tap(tester, keyed('save-target'));
      await waitFor(tester, keyed('target-kcal'), absent: true);
      expect(
        (await targets.loadForDay(alice, localDateKey(_today)))!.kcalTarget,
        2000,
      );
      expect(
        (await targets.loadForDay(alice, localDateKey(_yesterday)))!.kcalTarget,
        1800,
      );
      await checkpoint('02-target-history');

      await tap(tester, keyed('nav-journal'));
      await waitFor(tester, keyed('add-meal-lunch'));
      await tap(tester, keyed('add-meal-lunch'));
      await waitFor(tester, keyed('catalog-food-$_catalogId'));
      await tap(tester, find.byTooltip('Thêm Cơm fixture C6'));
      await enter(tester, 'meal-grams', '150');
      await tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      var todayMeals = await nutrition.loadRange(
        alice,
        _today,
        DateTime(_today.year, _today.month, _today.day + 1),
      );
      expect(todayMeals.single.totals.kcal, 195);
      await checkpoint('03-add-meal');

      Future<void> mealMenu(String label) async {
        await tap(tester, find.byType(PopupMenuButton<String>).first);
        await tap(tester, find.text(label).last);
      }

      await mealMenu('Sửa');
      await waitFor(tester, keyed('selected-meal-item-0'));
      await tap(tester, find.byTooltip('Sửa khẩu phần'));
      await enter(tester, 'meal-grams', '200');
      await tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      todayMeals = await nutrition.loadRange(
        alice,
        _today,
        DateTime(_today.year, _today.month, _today.day + 1),
      );
      expect(todayMeals.single.totals.kcal, 260);
      final sourceId = todayMeals.single.id;
      await mealMenu('Nhân bản bữa');
      await tap(
        tester,
        find.widgetWithIcon(OutlinedButton, Icons.calendar_today_outlined).last,
      );
      await pickDate(tester, _yesterday);
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      final copies = await nutrition.loadRange(alice, _yesterday, _today);
      expect(copies.single.items.single.grams, 200);
      expect(copies.single.totals.kcal, 260);
      expect(copies.single.id, isNot(sourceId));
      await tap(tester, keyed('journal-previous-day'));
      await waitFor(
        tester,
        find.textContaining('Năng lượng đã ghi / mục tiêu: 260 / 1800'),
      );
      await capture('c6-01-journal-history');
      await checkpoint('04-edit-copy-selected-day');

      Future<void> quick(String action) async {
        await tap(tester, keyed('quick-add-menu'));
        await tap(tester, keyed('quick-action-$action'));
      }

      await quick('water');
      await enter(tester, 'water-amount', '350');
      await tap(tester, keyed('save-water'));
      await waitFor(tester, keyed('water-amount'), absent: true);
      await quick('activity');
      await enter(tester, 'activity-duration', '25');
      await tap(tester, keyed('save-activity'));
      await waitFor(tester, keyed('activity-duration'), absent: true);
      await quick('weight');
      await enter(tester, 'metric-weight', '69,5');
      await tap(tester, keyed('save-metric'));
      await waitFor(tester, keyed('metric-weight'), absent: true);
      expect(
        (await profile.watchLatestBodyMetric(alice, _today).first)
            .single
            .weightKg,
        69.5,
      );
      await tap(tester, keyed('nav-progress'));
      await waitFor(
        tester,
        find.textContaining('Nước: 350 ml · Vận động: 25 phút'),
      );
      await capture('c6-02-progress');
      await checkpoint('05-water-activity-weight-progress');

      // Library CRUD is exercised through actual forms and real server reads.
      await profileRoot();
      await tap(tester, keyed('open-food-library'));
      await tap(tester, keyed('create-custom'));
      for (final entry in {
        'library-name': 'C6 món riêng',
        'library-kcal': '200',
        'library-protein': '10',
        'library-carbs': '30',
        'library-fat': '4',
        'library-default-grams': '100',
      }.entries) {
        await enter(tester, entry.key, entry.value);
      }
      await tap(tester, keyed('library-save'));
      await waitFor(tester, keyed('library-kcal'), absent: true);
      final foodDoc =
          (await db
                  .collection('users/$alice/custom_foods')
                  .get(const GetOptions(source: Source.server)))
              .docs
              .single;
      final foodId = foodDoc.id;
      await tap(tester, find.widgetWithText(ChoiceChip, 'Công thức'));
      await tap(tester, keyed('create-recipe'));
      await enter(tester, 'recipe-name', 'C6 công thức');
      await enter(tester, 'recipe-yield', '80');
      await enter(tester, 'recipe-servings', '2');
      await tap(tester, keyed('add-ingredient'));
      await tap(tester, find.widgetWithText(ChoiceChip, 'Món của tôi').last);
      await waitFor(tester, find.text('C6 món riêng').last);
      await tap(tester, find.text('C6 món riêng').last);
      await enter(tester, 'meal-grams', '100');
      await tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await tap(tester, keyed('library-save'));
      await waitFor(tester, keyed('recipe-name'), absent: true);
      final recipeDoc =
          (await db
                  .collection('users/$alice/recipes')
                  .get(const GetOptions(source: Source.server)))
              .docs
              .single;
      final recipeId = recipeDoc.id;
      expect(
        (await library.load(
          alice,
          FoodSourceKind.recipe,
          recipeId,
        ))!.asFood().per100g.kcal,
        250,
      );
      await checkpoint('06-create-personal-and-recipe');

      await quick('meal');
      await tap(tester, keyed('food-source-recipes'));
      await waitFor(tester, keyed('choose-recipe-$recipeId'));
      await tap(tester, keyed('choose-recipe-$recipeId'));
      await tap(tester, keyed('portion-unit'));
      await enter(tester, 'meal-grams', '0,5');
      await tap(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      await tap(tester, keyed('save-meal'));
      await waitFor(tester, find.byType(MealFormDialog), absent: true);
      todayMeals = await nutrition.loadRange(
        alice,
        _today,
        DateTime(_today.year, _today.month, _today.day + 1),
      );
      final recipeMeal = todayMeals.singleWhere(
        (m) => m.items.single.foodId.startsWith('recipe:'),
      );
      expect(recipeMeal.items.single.grams, 20);
      expect(recipeMeal.totals.kcal, 50);

      await profileRoot();
      await tap(tester, keyed('open-food-library'));
      await tap(tester, keyed('edit-custom-$foodId'));
      await enter(tester, 'library-kcal', '300');
      await tap(tester, keyed('library-save'));
      await waitFor(tester, keyed('library-kcal'), absent: true);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Công thức'));
      await tap(tester, keyed('edit-recipe-$recipeId'));
      await enter(tester, 'recipe-yield', '160');
      await tap(tester, keyed('library-save'));
      await waitFor(tester, keyed('recipe-name'), absent: true);
      await tap(tester, keyed('delete-recipe-$recipeId'));
      await tap(tester, find.widgetWithText(FilledButton, 'Xóa'));
      await waitFor(tester, keyed('delete-recipe-$recipeId'), absent: true);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Món của tôi'));
      await tap(tester, keyed('delete-custom-$foodId'));
      await tap(tester, find.widgetWithText(FilledButton, 'Xóa'));
      await waitFor(tester, keyed('delete-custom-$foodId'), absent: true);
      todayMeals = await nutrition.loadRange(
        alice,
        _today,
        DateTime(_today.year, _today.month, _today.day + 1),
      );
      expect(
        todayMeals.singleWhere((m) => m.id == recipeMeal.id).totals.kcal,
        50,
      );
      expect(todayMeals.singleWhere((m) => m.id == sourceId).totals.kcal, 260);
      await checkpoint('07-edit-delete-source-keeps-history');

      await tap(tester, keyed('nav-dashboard'));
      await tap(tester, keyed('edit-nutrition-target-${localDateKey(_today)}'));
      await enter(tester, 'target-kcal', '2100');
      await db.disableNetwork();
      await tap(tester, keyed('save-target'));
      await waitFor(
        tester,
        find.textContaining('Thông tin vẫn được giữ trong form'),
      );
      expect(find.text('2100'), findsOneWidget);
      await db.enableNetwork();
      await tap(tester, keyed('save-target'));
      await waitFor(tester, keyed('target-kcal'), absent: true);
      expect(
        (await targets.loadForDay(alice, localDateKey(_today)))!.kcalTarget,
        2100,
      );
      expect(
        (await targets.loadForDay(alice, localDateKey(_yesterday)))!.kcalTarget,
        1800,
      );
      expect(
        (await db.collection('users/$alice/nutrition_targets').get()).size,
        2,
      );
      await checkpoint('08-offline-draft-retry-target-history');

      await profileRoot();
      await tap(tester, find.widgetWithText(ChoiceChip, 'Tối'));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      await tester.pump(const Duration(milliseconds: 300));
      await tap(tester, keyed('nav-progress'));
      await waitFor(tester, find.textContaining('Nước: 350 ml'));
      await capture('c6-03-dark-large-text');
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.pump(const Duration(milliseconds: 300));
      await checkpoint('09-dark-large-text');
      await profileRoot();
      await tap(tester, keyed('sign-out'));
      await waitFor(tester, keyed('auth-email'));
      await register(tester, emailB);
      await onboard(tester, 'C6 QA Bob');
      final bob = auth.currentUser!.uid;
      expect(bob, isNot(alice));
      await tap(tester, keyed('nav-progress'));
      await waitFor(
        tester,
        find.textContaining('Chưa có nhật ký bữa ăn, nước hoặc vận động'),
      );
      expect(find.textContaining('C6 món riêng'), findsNothing);
      await expectLater(
        targets.loadForDay(alice, localDateKey(_today)),
        throwsA(isA<NutritionTargetFailure>()),
      );
      expect(await targets.loadForDay(bob, localDateKey(_today)), isNull);
      expect(container.exists(chatControllerProvider), isFalse);
      expect(container.exists(knowledgeServiceProvider), isFalse);
      expect(container.exists(foodScannerServiceProvider), isFalse);
      expect(container.read(appFeatureFlagsProvider).chatbotEnabled, isFalse);
      expect(
        container.read(appFeatureFlagsProvider).foodScannerEnabled,
        isFalse,
      );
      await capture('c6-04-account-isolation');
      await checkpoint('10-signout-second-account-private-data-isolation');
      binding.reportData?['coreAcceptance'] = {
        'project': _project,
        'checkpoints': 10,
        'android': true,
        'production': false,
      };
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
