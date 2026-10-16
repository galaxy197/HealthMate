import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/local_date_key.dart';
import '../models/nutrition_failure.dart';
import '../models/nutrition_models.dart';
import 'nutrition_repository.dart';

class FirebaseNutritionRepository implements NutritionRepository {
  FirebaseNutritionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _meals(String uid) =>
      _firestore.collection('users').doc(uid).collection('meal_logs');

  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() async* {
    try {
      await for (final snapshot
          in _firestore
              .collection('food_catalog')
              .orderBy('name')
              .snapshots()) {
        yield [for (final doc in snapshot.docs) _food(doc.id, doc.data())];
      }
    } on FirebaseException catch (error) {
      throw NutritionFailure.fromCode(error.code);
    }
  }

  @override
  Stream<List<MealLog>> watchMealLogs(String uid, DateTime localDate) async* {
    final dateKey = localDateKey(localDate);
    final range = localDayRange(localDate);
    yield* _watchMealDay(uid, dateKey, range);
  }

  Stream<List<MealLog>> _watchMealDay(
    String uid,
    String dateKey,
    LocalDayRange legacyRange,
  ) {
    late StreamController<List<MealLog>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? currentSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? legacySub;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? currentDocs;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? legacyDocs;

    void emitWhenReady() {
      if (currentDocs == null || legacyDocs == null || controller.isClosed) {
        return;
      }
      final byId = <String, MealLog>{
        for (final doc in currentDocs!) doc.id: _meal(doc.id, doc.data()),
      };
      for (final doc in legacyDocs!) {
        final data = doc.data();
        if (data['dateKey'] is String) continue;
        byId.putIfAbsent(doc.id, () => _meal(doc.id, data));
      }
      final meals = byId.values.toList(growable: false)
        ..sort((a, b) => b.consumedAt.compareTo(a.consumedAt));
      controller.add(meals);
    }

    void addError(Object error, StackTrace stack) {
      if (controller.isClosed) return;
      controller.addError(
        error is FirebaseException
            ? NutritionFailure.fromCode(error.code)
            : NutritionFailure.fromCode('unknown'),
        stack,
      );
    }

    controller = StreamController<List<MealLog>>(
      onListen: () {
        currentSub = _meals(uid)
            .where('dateKey', isEqualTo: dateKey)
            .snapshots()
            .listen((snapshot) {
              currentDocs = snapshot.docs;
              emitWhenReady();
            }, onError: addError);
        legacySub = _meals(uid)
            .where(
              'consumedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(legacyRange.start),
            )
            .where(
              'consumedAt',
              isLessThan: Timestamp.fromDate(legacyRange.end),
            )
            .orderBy('consumedAt', descending: true)
            .snapshots()
            .listen((snapshot) {
              legacyDocs = snapshot.docs;
              emitWhenReady();
            }, onError: addError);
      },
      onCancel: () async {
        await currentSub?.cancel();
        await legacySub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<MealLog>> watchRecentMeals(String uid, {int limit = 20}) async* {
    try {
      await for (final snapshot in _meals(
        uid,
      ).orderBy('consumedAt', descending: true).limit(limit).snapshots()) {
        yield [for (final doc in snapshot.docs) _meal(doc.id, doc.data())];
      }
    } on FirebaseException catch (error) {
      throw NutritionFailure.fromCode(error.code);
    }
  }

  @override
  Future<List<MealLog>> loadRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshots = await (
        _meals(uid)
            .where('dateKey', isGreaterThanOrEqualTo: localDateKey(start))
            .where('dateKey', isLessThan: localDateKey(end))
            .get(const GetOptions(source: Source.server)),
        _meals(uid)
            .where(
              'consumedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('consumedAt', isLessThan: Timestamp.fromDate(end))
            .get(const GetOptions(source: Source.server)),
      ).wait;
      final byId = <String, MealLog>{
        for (final doc in snapshots.$1.docs) doc.id: _meal(doc.id, doc.data()),
      };
      for (final doc in snapshots.$2.docs) {
        if (doc.data()['dateKey'] is String) continue;
        byId.putIfAbsent(doc.id, () => _meal(doc.id, doc.data()));
      }
      return byId.values.toList()
        ..sort((a, b) => a.consumedAt.compareTo(b.consumedAt));
    } on FirebaseException catch (error) {
      throw NutritionFailure.fromCode(error.code);
    }
  }

  @override
  Future<String> addMeal({required String uid, required MealDraft draft}) =>
      _guard(() async {
        final ref = _meals(uid).doc();
        await ref.set({
          ..._mealData(draft),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return ref.id;
      });

  @override
  Future<void> updateMeal({
    required String uid,
    required String mealId,
    required MealDraft draft,
  }) => _guard(
    () => _meals(uid).doc(mealId).update({
      ..._mealData(draft),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> deleteMeal({required String uid, required String mealId}) =>
      _guard(() => _meals(uid).doc(mealId).delete());

  Map<String, Object> _mealData(MealDraft draft) {
    final totals = draft.totals;
    return {
      'mealType': draft.type.name,
      'consumedAt': Timestamp.fromDate(draft.consumedAt),
      'dateKey': draft.dateKey,
      'timezoneOffsetMinutes': draft.timezoneOffsetMinutes,
      'items': [
        for (final item in draft.items)
          {
            'foodId': item.foodId,
            'name': item.name,
            'grams': item.grams,
            'kcal': item.nutrition.kcal,
            'proteinG': item.nutrition.proteinG,
            'carbsG': item.nutrition.carbsG,
            'fatG': item.nutrition.fatG,
            'sourceLabel': item.sourceLabel,
            'isEstimated': item.isEstimated,
          },
      ],
      'totalKcal': totals.kcal,
      'totalProteinG': totals.proteinG,
      'totalCarbsG': totals.carbsG,
      'totalFatG': totals.fatG,
      'source': draft.source.wireValue,
      'schemaVersion': 2,
    };
  }

  FoodCatalogItem _food(String id, Map<String, dynamic> data) =>
      FoodCatalogItem(
        id: id,
        name: data['name'] as String? ?? '',
        alternateNames: (data['alternateNames'] as List? ?? const [])
            .whereType<String>()
            .toList(growable: false),
        category: data['category'] as String? ?? '',
        servingBasis: data['servingBasis'] as String? ?? 'per_100g',
        unit: data['unit'] as String? ?? 'g',
        per100g: NutritionTotals(
          kcal: _number(data['kcalPer100g']),
          proteinG: _number(data['proteinGPer100g']),
          carbsG: _number(data['carbsGPer100g']),
          fatG: _number(data['fatGPer100g']),
        ),
        sourceLabel: data['sourceLabel'] as String? ?? 'Không rõ nguồn',
        isEstimated: data['isEstimated'] as bool? ?? true,
        updatedAt: _date(data['updatedAt']),
      );

  MealLog _meal(String id, Map<String, dynamic> data) {
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .map(
          (item) => MealItemSnapshot(
            foodId: item['foodId'] as String? ?? '',
            name: item['name'] as String? ?? '',
            grams: _number(item['grams']),
            nutrition: NutritionTotals(
              kcal: _number(item['kcal']),
              proteinG: _number(item['proteinG']),
              carbsG: _number(item['carbsG']),
              fatG: _number(item['fatG']),
            ),
            sourceLabel: item['sourceLabel'] as String? ?? '',
            isEstimated: item['isEstimated'] as bool? ?? true,
          ),
        )
        .toList(growable: false);
    return MealLog(
      id: id,
      type:
          MealType.values
              .where((value) => value.name == data['mealType'])
              .firstOrNull ??
          MealType.snack,
      consumedAt: _date(data['consumedAt']) ?? DateTime.now(),
      items: items,
      totals: NutritionTotals(
        kcal: _number(data['totalKcal']),
        proteinG: _number(data['totalProteinG']),
        carbsG: _number(data['totalCarbsG']),
        fatG: _number(data['totalFatG']),
      ),
      source: data['source'] == 'ai_assisted'
          ? MealSource.aiAssisted
          : MealSource.manual,
      dateKey: data['dateKey'] as String?,
      timezoneOffsetMinutes: (data['timezoneOffsetMinutes'] as num?)?.toInt(),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  double _number(Object? value) => value is num ? value.toDouble() : 0;

  DateTime? _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    _ => null,
  };

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      throw NutritionFailure.fromCode(error.code);
    } catch (_) {
      throw NutritionFailure.fromCode('unknown');
    }
  }
}
