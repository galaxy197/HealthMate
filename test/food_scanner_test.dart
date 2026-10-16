import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/food_scanner/data/food_image_picker.dart';
import 'package:healthmate/features/food_scanner/data/food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/models/ai_food_suggestion.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

class _Picker implements FoodImagePicker {
  FoodImage? image = FoodImage(
    bytes: Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
      ),
    ),
    mimeType: 'image/png',
  );
  Object? error;
  int calls = 0;
  @override
  Future<FoodImage?> pick(ImageSource source) async {
    calls++;
    if (error != null) throw error!;
    return image;
  }
}

class _Scanner implements FoodScannerService {
  Object? error;
  Completer<AiFoodSuggestion>? pending;
  int calls = 0;
  @override
  Future<AiFoodSuggestion> analyze({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    calls++;
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    return const AiFoodSuggestion(
      dishName: 'Cơm trắng chín',
      description: 'Một phần cơm.',
      ingredients: ['gạo'],
      searchTerms: ['cơm trắng'],
    );
  }
}

class _EmptyCatalog extends FakeNutritionRepository {
  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() => Stream.value(const []);
}

Future<void> _visibleTap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty &&
      find.byKey(const ValueKey('scanner-content')).evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(
      finder,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('scanner-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester,
  _Picker picker,
  _Scanner scanner, {
  FakeNutritionRepository? nutrition,
  FakeAuthRepository? auth,
}) async {
  final container = await pumpApp(
    tester,
    foodImagePicker: picker,
    foodScannerService: scanner,
    nutritionRepository: nutrition,
    repository: auth,
  );
  container.read(appRouterProvider).go(AppRoutes.journal);
  await tester.pumpAndSettle();
  await _visibleTap(tester, find.byKey(const ValueKey('scan-food')));
}

Future<void> _chooseAndConsent(WidgetTester tester) async {
  await _visibleTap(tester, find.text('Chọn ảnh'));
  final button = tester.widget<FilledButton>(
    find.byKey(const ValueKey('analyze-food-image')),
  );
  expect(button.onPressed, isNull);
  await _visibleTap(
    tester,
    find.byKey(const ValueKey('scanner-processing-consent')),
  );
}

void main() {
  test(
    'prepared images contain pixels rather than original file metadata',
    () async {
      final bytes = _Picker().image!.bytes;
      final prepared = await prepareFoodImage(
        Uint8List.fromList([
          ...bytes,
          ...utf8.encode('GPSLatitude=private-test'),
        ]),
      );
      expect(prepared.mimeType, 'image/png');
      expect(
        utf8.decode(prepared.bytes, allowMalformed: true),
        isNot(contains('GPSLatitude')),
      );
      expect(prepared.bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      for (final invalid in [
        Uint8List(0),
        Uint8List.fromList([1, 2, 3]),
        Uint8List(8 * 1024 * 1024 + 1),
      ]) {
        await expectLater(
          prepareFoodImage(invalid),
          throwsA(isA<FoodScannerFailure>()),
        );
      }
    },
  );
  testWidgets(
    'an empty catalog still permits scanning and manual confirmation',
    (tester) async {
      final repository = _EmptyCatalog();
      await _open(tester, _Picker(), _Scanner(), nutrition: repository);
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      await _visibleTap(tester, find.text('Tiếp tục nhập thủ công'));
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(repository.addCalls, 0);
    },
  );
  testWidgets(
    'cancelled picker and denied permission leave a working manual path',
    (tester) async {
      final picker = _Picker()..image = null;
      final scanner = _Scanner();
      await _open(tester, picker, scanner);
      await _visibleTap(tester, find.text('Chọn ảnh'));
      expect(scanner.calls, 0);
      picker.error = const FoodScannerFailure(
        'Chưa mở được ảnh. Kiểm tra quyền camera.',
      );
      await _visibleTap(tester, find.text('Chụp ảnh'));
      expect(find.textContaining('Kiểm tra quyền camera'), findsOneWidget);
      expect(scanner.calls, 0);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      await _visibleTap(tester, find.byKey(const ValueKey('add-meal')));
      expect(find.byType(MealFormDialog), findsOneWidget);
    },
  );

  testWidgets(
    'scanner requires disclosure, shows real result, never saves before confirmation',
    (tester) async {
      final picker = _Picker();
      final scanner = _Scanner();
      final nutrition = FakeNutritionRepository();
      await _open(tester, picker, scanner, nutrition: nutrition);
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      expect(scanner.calls, 1);
      await tester.scrollUntilVisible(
        find.text('Một phần cơm.'),
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('scanner-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Một phần cơm.'), findsOneWidget);
      expect(nutrition.addCalls, 0);
      await _visibleTap(tester, find.text('Xác nhận món đã chọn'));
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(nutrition.addCalls, 0);
      expect(find.byKey(const ValueKey('save-meal')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unexpected SDK error is safe and retry succeeds without auto-saving',
    (tester) async {
      final scanner = _Scanner()..error = StateError('private SDK detail');
      await _open(tester, _Picker(), scanner);
      await _chooseAndConsent(tester);
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      expect(find.textContaining('Chưa thể phân tích ảnh'), findsOneWidget);
      expect(find.textContaining('private SDK detail'), findsNothing);
      scanner.error = null;
      await _visibleTap(
        tester,
        find.byKey(const ValueKey('analyze-food-image')),
      );
      expect(scanner.calls, 2);
      await tester.scrollUntilVisible(
        find.text('Một phần cơm.'),
        150,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('scanner-content')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Một phần cơm.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'timeout resets scanner and closing while pending discards late response',
    (tester) async {
      final scanner = _Scanner()..pending = Completer<AiFoodSuggestion>();
      await _open(tester, _Picker(), scanner);
      await _chooseAndConsent(tester);
      final analyze = find.byKey(const ValueKey('analyze-food-image'));
      await tester.ensureVisible(analyze);
      await tester.pumpAndSettle();
      await tester.tap(analyze);
      await tester.pump();
      expect(scanner.calls, 1);
      expect(tester.widget<FilledButton>(analyze).onPressed, isNull);
      await tester.pump(const Duration(seconds: 46));
      await tester.pumpAndSettle();
      expect(find.textContaining('quá thời gian chờ'), findsOneWidget);
      await tester.tap(analyze);
      await tester.pump();
      expect(scanner.calls, 2);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      scanner.pending!.complete(
        const AiFoodSuggestion(
          dishName: 'late',
          description: 'late',
          ingredients: [],
          searchTerms: ['late'],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('late'), findsNothing);
      expect(find.byType(MealFormDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sign-out dismisses scanner and does not retain another account image',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final scanner = _Scanner()..pending = Completer<AiFoodSuggestion>();
      await _open(tester, _Picker(), scanner, auth: auth);
      await _chooseAndConsent(tester);
      final button = find.byKey(const ValueKey('analyze-food-image'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      auth.emitUser(null);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('scanner-processing-consent')),
        findsNothing,
      );
      expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
      scanner.pending!.complete(
        const AiFoodSuggestion(
          dishName: 'old account',
          description: 'late',
          ingredients: [],
          searchTerms: ['late'],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('old account'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
