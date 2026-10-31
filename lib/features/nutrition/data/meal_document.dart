import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nutrition_failure.dart';
import '../models/nutrition_models.dart';

/// Shared serialization for manual and atomic plan-to-journal writes.
Map<String, Object?> mealDocumentData(MealDraft draft) {
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
    'queryPartition': 'current',
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
                (i) => i.hasFiberData || i.nutrition.extraNutrients.isNotEmpty,
              ) ||
              draft.minimumSchemaVersion >= 4
        ? 4
        : draft.items.any((i) => i.needsExtendedSchema) ||
              draft.minimumSchemaVersion >= 3
        ? 3
        : 2,
  };
}

/// Routing metadata is not part of the user's idempotent nutrition snapshot.
bool sameMealPayload(
  Map<String, Object?> expected,
  Map<String, dynamic>? saved,
) => sameDocumentValue(
  {
    for (final key in expected.keys)
      if (key != 'queryPartition') key: expected[key],
  },
  {
    for (final key in expected.keys)
      if (key != 'queryPartition') key: saved?[key],
  },
);

bool sameDocumentValue(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every(
          (key) => b.containsKey(key) && sameDocumentValue(a[key], b[key]),
        );
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        a.indexed.every((entry) => sameDocumentValue(entry.$2, b[entry.$1]));
  }
  return a == b;
}
