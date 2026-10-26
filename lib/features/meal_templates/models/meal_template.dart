import '../../food_library/models/food_library_models.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/models/extra_nutrients.dart';

class MealTemplate {
  MealTemplate({
    required this.id,
    required this.name,
    required List<MealItemSnapshot> items,
  }) : items = List.unmodifiable(items);
  final String id;
  final String name;
  final List<MealItemSnapshot> items;
  void validate() {
    LibraryValidation.id(id);
    LibraryValidation.text(name, 80, min: 2);
    if (items.isEmpty || items.length > 5) {
      throw const FormatException('Bữa mẫu cần từ 1 đến 5 món.');
    }
    for (final item in items) {
      item.withQuantity(item.quantity);
      LibraryValidation.number(item.quantity, 2000, positive: true);
      LibraryValidation.nutrition(item.nutrition);
      LibraryValidation.text(item.name, 100);
      LibraryValidation.text(item.foodId, 100);
      LibraryValidation.text(item.sourceLabel, 160);
    }
    if (items.fold(0.0, (sum, i) => sum + i.nutrition.kcal) > 20000) {
      throw const FormatException('Bữa mẫu vượt giới hạn năng lượng.');
    }
    final totals = items.fold(
      NutritionTotals.zero,
      (sum, item) => sum + item.nutrition,
    );
    if ([totals.proteinG, totals.carbsG, totals.fatG].any((v) => v > 2000)) {
      throw const FormatException(
        'Tổng chất dinh dưỡng vượt giới hạn bản ghi.',
      );
    }
  }

  /// Schema 3 keeps a bounded fiber vector aligned with the immutable item
  /// order: number=known subtotal, null=unknown. The bit mask marks subtotals
  /// with incomplete sources; absent mask means all numeric values are known.
  List<Object?> get fiberValues => [
    for (final item in items)
      item.nutrition.fiberKnown || item.nutrition.fiberG > 0
          ? item.nutrition.fiberG
          : null,
  ];
  int get fiberPartialMask => items.indexed.fold(
    0,
    (mask, row) => !row.$2.nutrition.fiberKnown && row.$2.nutrition.fiberG > 0
        ? mask | (1 << row.$1)
        : mask,
  );

  Map<String, Object?> toData({int minimumSchemaVersion = 1}) {
    validate();
    if (minimumSchemaVersion > 4) {
      throw const FormatException('Cần cập nhật ứng dụng để sửa bữa mẫu này.');
    }
    final version =
        minimumSchemaVersion >= 4 ||
            items.any((i) => i.nutrition.extraNutrients.isNotEmpty)
        ? 4
        : items.any((i) => i.hasFiberData) || minimumSchemaVersion >= 3
        ? 3
        : items.any((i) => i.needsExtendedSchema) || minimumSchemaVersion >= 2
        ? 2
        : 1;
    return {
      'name': name,
      'items': [
        for (final item in items)
          {
            for (final entry in item.toData().entries)
              if (![
                    'fiberG',
                    'knownFiberG',
                    'fiberIncomplete',
                    'nutrientVectorV1',
                  ].contains(entry.key) &&
                  !(version >= 3 && entry.key == 'grams') &&
                  !(version >= 3 &&
                      entry.value == null &&
                      ['proteinG', 'carbsG', 'fatG'].contains(entry.key)))
                entry.key: entry.value,
            if (version >= 3) ...{
              'quantity': item.quantity,
              'quantityUnit': item.quantityUnit,
            },
          },
      ],
      if (version >= 3) 'fiberValues': fiberValues,
      if (version >= 3 && fiberPartialMask > 0)
        'fiberPartialMask': fiberPartialMask,
      if (version == 4)
        'nutrientVectorsV1': items
            .map((i) => encodeExtraNutrients(i.nutrition.extraNutrients))
            .join('|'),
      'schemaVersion': version,
    };
  }

  factory MealTemplate.fromData(String id, Map<String, dynamic> data) {
    if (![1, 2, 3, 4].contains(data['schemaVersion'])) {
      throw const FormatException('Phiên bản bữa mẫu không hợp lệ.');
    }
    final rawItems = data['items'] as List;
    final vectors = data['schemaVersion'] == 4
        ? (data['nutrientVectorsV1'] as String).split('|')
        : null;
    if (vectors != null && vectors.length != rawItems.length) {
      throw const FormatException('Thiếu dưỡng chất trong bữa mẫu.');
    }
    final fiber = (data['schemaVersion'] as int) >= 3
        ? data['fiberValues'] as List
        : null;
    final mask = data['fiberPartialMask'] ?? 0;
    if (mask is! int || mask < 0 || mask >= (1 << rawItems.length)) {
      throw const FormatException('Mức độ ghi nhận chất xơ không hợp lệ.');
    }
    if (fiber != null && fiber.length != rawItems.length) {
      throw const FormatException('Thiếu mức độ ghi nhận chất xơ.');
    }
    if (fiber != null) {
      for (final value in fiber) {
        if (value == null) continue;
        if (value is num && value.isFinite && value >= 0 && value <= 1000) {
          continue;
        }
        throw const FormatException(
          'Thông tin chất xơ trong bữa mẫu không hợp lệ.',
        );
      }
    }
    MealItemSnapshot readItem(int index) {
      final row = Map<String, dynamic>.from(rawItems[index] as Map);
      if (vectors != null) row['nutrientVectorV1'] = vectors[index];
      if (fiber != null) {
        final unit = row['quantityUnit'];
        row['grams'] = unit == 'g' ? row['quantity'] : null;
        if (unit == 'g') {
          row.remove('quantity');
          row.remove('quantityUnit');
        }
        for (final key in ['proteinG', 'carbsG', 'fatG']) {
          row.putIfAbsent(key, () => null);
        }
        if (fiber[index] is num) {
          if ((mask & (1 << index)) == 0) {
            row['fiberG'] = fiber[index];
          } else {
            row['fiberG'] = fiber[index];
            row['fiberIncomplete'] = true;
          }
        }
      }
      return LibraryValidation.readSnapshot(row);
    }

    final template = MealTemplate(
      id: id,
      name: data['name'] as String,
      items: [
        for (var index = 0; index < rawItems.length; index++) readItem(index),
      ],
    );
    template.validate();
    return template;
  }
}

class MealTemplateFailure implements Exception {
  const MealTemplateFailure([
    this.message =
        'Chưa thể tải hoặc lưu bữa mẫu. Kiểm tra kết nối/quyền truy cập rồi thử lại.',
  ]);
  final String message;
}
