import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:healthmate/features/food_scanner/data/barcode_product_service.dart';
import 'package:healthmate/features/food_scanner/models/barcode_product_models.dart';
import 'package:healthmate/features/food_scanner/presentation/barcode_product_detail_sheet.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

const product = BarcodeProduct(
  barcode: '3017620422003',
  name: 'Món thử',
  source: 'Open Food Facts',
  servingSizeG: 15,
  nutrition: NutritionTotals(
    kcal: 500,
    proteinG: 10,
    carbsG: 50,
    fatG: 20,
    fiberG: 4,
    fiberKnown: true,
  ),
);

void main() {
  test('OFF normalized grams convert minerals to mg exactly once', () async {
    final service = BarcodeProductService(
      client: MockClient(
        (r) async => http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name': 'Label fixture',
              'nutriments': {
                'energy-kcal_100g': 100,
                'proteins_100g': 10,
                'carbohydrates_100g': 10,
                'fat_100g': 2,
                'sodium_100g': .12,
                'iron_100g': .00125,
                'sugars_100g': 0,
                'saturated-fat_100g': 1,
              },
            },
          }),
          200,
        ),
      ),
    );
    final product = (await service.lookupBarcode('1234567890123'))!;
    final snapshot = BarcodeMealSelection(
      product: product,
      grams: 150,
    ).toSnapshot();
    expect(snapshot.nutrition.extraNutrients['sodium'], 180);
    expect(snapshot.nutrition.extraNutrients['iron'], closeTo(1.875, 1e-9));
    expect(snapshot.nutrition.extraNutrients['sugar'], 0);
    expect(snapshot.nutrition.extraNutrients.containsKey('vitaminC'), false);
  });
  test(
    'selected quantity scales every nutrient once and preserves snapshot',
    () {
      final item = const BarcodeMealSelection(
        product: product,
        grams: 30,
      ).toSnapshot();
      expect(item.grams, 30);
      expect(item.nutrition.kcal, 150);
      expect(item.nutrition.proteinG, 3);
      expect(item.nutrition.carbsG, 15);
      expect(item.nutrition.fatG, 6);
      expect(item.nutrition.fiberG, closeTo(1.2, .0001));
      final roundTrip = MealItemSnapshot.fromData(
        Map.from(item.toData()),
        allowPartial: true,
      );
      expect(roundTrip.nutrition.kcal, 150);
      expect(roundTrip.withQuantity(60).nutrition.kcal, 300);
      for (final grams in [0.0, -1.0, 2001.0, double.nan, double.infinity]) {
        expect(
          () =>
              BarcodeMealSelection(product: product, grams: grams).toSnapshot(),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'lookup preserves missing macros and fiber, and uses kJ conversion',
    () async {
      final service = BarcodeProductService(
        client: MockClient((request) async {
          expect(request.headers['User-Agent'], contains('HealthMate'));
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Món thử',
                'serving_quantity': 250,
                'serving_quantity_unit': 'ml',
                'nutriments': {'energy_100g': 418.4, 'proteins_100g': 0},
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(service.dispose);
      final found = (await service.lookupBarcode('123'))!;
      expect(found.nutrition!.kcal, closeTo(100, .0001));
      expect(found.nutrition!.proteinKnown, isTrue);
      expect(found.nutrition!.carbsKnown, isFalse);
      expect(found.nutrition!.fatKnown, isFalse);
      expect(found.nutrition!.fiberKnown, isFalse);
      expect(
        found.servingSizeG,
        isNull,
      ); // ml is never silently treated as grams.
      final data = BarcodeMealSelection(
        product: found,
        grams: 50,
      ).toSnapshot().toData();
      expect(data['proteinG'], 0);
      expect(data['carbsG'], isNull);
      expect(data['fatG'], isNull);
      expect(data.containsKey('fiberG'), isFalse);
    },
  );

  test(
    'lookup distinguishes not found from network, quota and invalid data',
    () async {
      for (final response in [
        http.Response('{"status":0}', 200),
        http.Response('', 404),
      ]) {
        final service = BarcodeProductService(
          client: MockClient((_) async => response),
        );
        expect(await service.lookupBarcode('123'), isNull);
        service.dispose();
      }
      for (final response in [
        http.Response('', 429),
        http.Response('', 503),
        http.Response('bad json', 200),
        http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name': 'Món thử',
              'nutriments': {'energy-kcal_100g': -10},
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ]) {
        final service = BarcodeProductService(
          client: MockClient((_) async => response),
        );
        await expectLater(
          service.lookupBarcode('123'),
          throwsA(isA<BarcodeLookupFailure>()),
        );
        service.dispose();
      }
      final service = BarcodeProductService(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.lookupBarcode('123'),
        throwsA(isA<BarcodeLookupFailure>()),
      );
    },
  );

  testWidgets(
    'barcode review returns edited decimal grams; invalid input cannot confirm',
    (tester) async {
      BarcodeMealSelection? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<BarcodeMealSelection>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        const BarcodeProductDetailSheet(product: product),
                  );
                },
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      final grams = find.byKey(const ValueKey('barcode-grams'));
      await tester.enterText(grams, '30,5');
      await tester.pumpAndSettle();
      expect(find.text('153 kcal'), findsOneWidget);
      await tester.enterText(grams, '');
      await tester.pumpAndSettle();
      final confirm = find.byKey(const ValueKey('barcode-confirm'));
      await tester.scrollUntilVisible(
        confirm,
        150,
        scrollable: find
            .descendant(
              of: find.byType(BarcodeProductDetailSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.scrollUntilVisible(
        grams,
        -150,
        scrollable: find
            .descendant(
              of: find.byType(BarcodeProductDetailSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(grams, '30');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        confirm,
        150,
        scrollable: find
            .descendant(
              of: find.byType(BarcodeProductDetailSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(result!.grams, 30);
      expect(result!.toSnapshot().nutrition.kcal, 150);
      expect(product.nutrition!.kcal, 500);
    },
  );
}
