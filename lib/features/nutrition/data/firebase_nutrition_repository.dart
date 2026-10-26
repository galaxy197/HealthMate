import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/data/bounded_range.dart';

import '../../../core/utils/local_date_key.dart';
import '../models/nutrition_failure.dart';
import '../models/nutrition_models.dart';
import '../models/catalog_food_reader.dart';
import 'nutrition_repository.dart';
import 'bundled_vietnamese_foods.dart';

class FirebaseNutritionRepository implements NutritionRepository {
  FirebaseNutritionRepository(
    this._firestore, {
    Future<List<FoodCatalogItem>> Function()? catalogLoader,
  }) : _catalogLoader = catalogLoader ?? loadBundledVietnameseFoods;

  final FirebaseFirestore _firestore;
  final Future<List<FoodCatalogItem>> Function() _catalogLoader;

  CollectionReference<Map<String, dynamic>> _meals(String uid) =>
      _firestore.collection('users').doc(uid).collection('meal_logs');

  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() async* {
    List<FoodCatalogItem> bundled = const [];
    try {
      bundled = await _catalogLoader().timeout(const Duration(seconds: 3));
    } catch (_) {
      /* A missing bundle must not block the real server catalog. */
    }
    if (bundled.isNotEmpty) yield bundled;
    try {
      await for (final snapshot
          in _firestore
              .collection('food_catalog')
              .orderBy('name')
              .snapshots()) {
        final serverIds = snapshot.docs.map((d) => d.id).toSet();
        yield [
          for (final doc in snapshot.docs)
            if (doc.data()['isActive'] != false) _food(doc.id, doc.data()),
          for (final food in bundled)
            if (!serverIds.contains(food.id)) food,
        ]..sort((a, b) => a.name.compareTo(b.name));
      }
    } on FirebaseException catch (error) {
      if (bundled.isEmpty) throw NutritionFailure.fromCode(error.code);
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
  Stream<RecentMealPage> watchRecentMeals(String uid, {int limit = 20}) async* {
    try {
      await for (final snapshot
          in _meals(uid)
              .orderBy('consumedAt', descending: true)
              .limit(limit)
              .snapshots(includeMetadataChanges: true)) {
        if (snapshot.metadata.hasPendingWrites) continue;
        yield RecentMealPage(
          meals: [for (final doc in snapshot.docs) _meal(doc.id, doc.data())],
          fromCache: snapshot.metadata.isFromCache,
        );
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
        readBoundedRange(
          _meals(uid)
              .where('dateKey', isGreaterThanOrEqualTo: localDateKey(start))
              .where('dateKey', isLessThan: localDateKey(end)),
          start,
          end,
        ),
        readBoundedRange(
          _meals(uid)
              .where(
                'consumedAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where('consumedAt', isLessThan: Timestamp.fromDate(end)),
          start,
          end,
        ),
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
  String newMealId() => _firestore.collection('users').doc().id;

  @override
  Future<String> addMeal({
    required String uid,
    required MealDraft draft,
    String? operationId,
  }) => _guard(() async {
    final ref = _meals(uid).doc(operationId);
    final data = _mealData(draft);
    if (operationId == null) {
      await ref.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.runTransaction((transaction) async {
        final previous = await transaction.get(ref);
        if (previous.exists) {
          if (!_sameValue(data, {
            for (final key in data.keys) key: previous.data()?[key],
          })) {
            throw const NutritionFailure(
              'Thao tác trước đã lưu nội dung khác. Hãy đóng form, tải lại bữa và chọn Sửa.',
            );
          }
          return;
        }
        transaction.set(ref, {
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      final confirmed = await ref.get(const GetOptions(source: Source.server));
      if (!confirmed.exists ||
          confirmed.metadata.hasPendingWrites ||
          confirmed.metadata.isFromCache ||
          !_sameValue(data, {
            for (final key in data.keys) key: confirmed.data()?[key],
          })) {
        throw const NutritionFailure(
          'Chưa xác nhận được đúng bữa trên máy chủ; bản nháp vẫn được giữ.',
        );
      }
    }
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

  Map<String, Object?> _mealData(MealDraft draft) {
    if (draft.minimumSchemaVersion > 5) {
      throw const NutritionFailure(
        'Cần phiên bản ứng dụng mới hơn để sửa bản ghi này.',
      );
    }
    for (final item in draft.items) {
      item.withQuantity(item.quantity);
    }
    final totals = draft.totals;
    final enriched =
        draft.items.any((i) => i.nutrition.extraNutrients.isNotEmpty) ||
        draft.minimumSchemaVersion >= 5;
    return {
      'mealType': draft.type.name,
      'consumedAt': Timestamp.fromDate(draft.consumedAt),
      'dateKey': draft.dateKey,
      'timezoneOffsetMinutes': draft.timezoneOffsetMinutes,
      'items': [
        for (final item in draft.items)
          if (!enriched) item.toData() else item.toCompactData(),
      ],
      'totalKcal': totals.kcal,
      'totalProteinG': totals.proteinKnown ? totals.proteinG : null,
      'totalCarbsG': totals.carbsKnown ? totals.carbsG : null,
      'totalFatG': totals.fatKnown ? totals.fatG : null,
      'source': draft.source.wireValue,
      'schemaVersion': enriched
          ? 5
          : draft.items.any(
                  (i) =>
                      i.hasFiberData || i.nutrition.extraNutrients.isNotEmpty,
                ) ||
                draft.minimumSchemaVersion >= 4
          ? 4
          : draft.items.any((i) => i.needsExtendedSchema) ||
                draft.minimumSchemaVersion >= 3
          ? 3
          : 2,
    };
  }

  FoodCatalogItem _food(String id, Map<String, dynamic> data) =>
      readCatalogFood(id, data, updatedAt: _date(data['updatedAt']));

  MealLog _meal(String id, Map<String, dynamic> data) {
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .map(
          (item) => data['schemaVersion'] == 5
              ? MealItemSnapshot.fromCompactData(item)
              : MealItemSnapshot.fromData(
                  item,
                  allowPartial: [3, 4, 5].contains(data['schemaVersion']),
                ),
        )
        .toList(growable: false);
    final snapshotTotals = sumNutritionTotals(items.map((i) => i.nutrition));
    return MealLog(
      id: id,
      type:
          MealType.values
              .where((value) => value.name == data['mealType'])
              .firstOrNull ??
          MealType.snack,
      consumedAt: _date(data['consumedAt']) ?? DateTime.now(),
      items: items,
      totals: [3, 4, 5].contains(data['schemaVersion'])
          ? snapshotTotals
          : NutritionTotals(
              kcal: _number(data['totalKcal']),
              proteinG: _number(data['totalProteinG']),
              carbsG: _number(data['totalCarbsG']),
              fatG: _number(data['totalFatG']),
              fiberG: snapshotTotals.fiberG,
              fiberKnown: snapshotTotals.fiberKnown,
              extraNutrients: snapshotTotals.extraNutrients,
            ),
      source: data['source'] == 'ai_assisted'
          ? MealSource.aiAssisted
          : MealSource.manual,
      dateKey: data['dateKey'] as String?,
      timezoneOffsetMinutes: (data['timezoneOffsetMinutes'] as num?)?.toInt(),
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 2,
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
    } on NutritionFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw NutritionFailure.fromCode(error.code);
    } catch (_) {
      throw NutritionFailure.fromCode('unknown');
    }
  }
}

bool _sameValue(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((key) => b.containsKey(key) && _sameValue(a[key], b[key]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        a.indexed.every((entry) => _sameValue(entry.$2, b[entry.$1]));
  }
  return a == b;
}
