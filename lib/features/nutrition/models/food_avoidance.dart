import 'food_catalog_search.dart';
import 'nutrition_models.dart';

enum FoodAvoidanceStatus { noKnownMatch, containsAvoided, unknown }

/// Ingredient screening only. Never infers cross-contact or certifies safety.
class FoodAvoidance {
  const FoodAvoidance._(this.terms);
  const FoodAvoidance.none() : terms = const [];

  factory FoodAvoidance.fromText(Object? answer) {
    if (answer is! String) return const FoodAvoidance.none();
    final text = normalizeFoodSearch(answer);
    if (const [
      '',
      'khong',
      'khong co',
      'khong di ung',
      'none',
      'no',
    ].contains(text)) {
      return const FoodAvoidance.none();
    }
    final terms = <String>{};
    for (final part in answer.split(
      RegExp(r'[,;\n/]+|\s+(?:và|va|and)\s+', caseSensitive: false),
    )) {
      final cleaned = normalizeFoodSearch(part)
          .replaceFirst(
            RegExp(
              r'^(?:(?:toi|minh|em)\s+)?(?:bi\s+)?(di ung(?: voi)?|tranh|khong an)\s+',
            ),
            '',
          )
          .trim();
      if (cleaned.isNotEmpty) terms.add(cleaned);
    }
    return FoodAvoidance._(List.unmodifiable(terms));
  }

  final List<String> terms;
  bool get isActive => terms.isNotEmpty;
  String get label => terms
      .map((term) {
        final index = _groups.indexWhere((g) => g.contains(term));
        return index < 0
            ? term
            : const [
                'Sữa và chế phẩm',
                'Trứng',
                'Đậu phộng',
                'Đậu nành',
                'Lúa mì',
                'Gluten',
                'Hạt cây',
                'Giáp xác (tôm, cua…)',
                'Cá',
                'Hải sản',
                'Mè (vừng)',
              ][index];
      })
      .toSet()
      .join(', ');

  static const _groups = [
    [
      'sua',
      'sua bo',
      'dairy',
      'milk',
      'butter',
      'bo dong vat',
      'bo sua',
      'cheese',
      'pho mai',
      'cream',
      'kem sua',
      'yogurt',
      'sua chua',
      'whey',
      'casein',
      'lactose',
    ],
    ['trung', 'egg', 'eggs', 'albumen', 'mayonnaise'],
    ['dau phong', 'lac', 'peanut', 'peanuts', 'arachis'],
    [
      'dau nanh',
      'dau tuong',
      'soy',
      'soya',
      'soybean',
      'soybeans',
      'tofu',
      'dau phu',
      'dau hu',
      'tau hu',
      'miso',
      'tempeh',
    ],
    ['lua mi', 'wheat', 'semolina', 'bulgur', 'spelt', 'seitan'],
    [
      'gluten',
      'wheat',
      'lua mi',
      'barley',
      'lua mach',
      'rye',
      'semolina',
      'spelt',
      'seitan',
      'bulgur',
    ],
    [
      'hat cay',
      'tree nuts',
      'almond',
      'almonds',
      'hanh nhan',
      'cashew',
      'cashews',
      'hat dieu',
      'walnut',
      'walnuts',
      'oc cho',
      'pecan',
      'pecans',
      'hazelnut',
      'hazelnuts',
      'hat phi',
      'pistachio',
      'pistachios',
      'hat de cuoi',
      'macadamia',
    ],
    [
      'giap xac',
      'crustacean',
      'shrimp',
      'shrimps',
      'prawns',
      'crabs',
      'prawn',
      'tom',
      'crab',
      'cua',
      'lobster',
      'crawfish',
    ],
    [
      'ca',
      'fish',
      'salmon',
      'tuna',
      'anchovy',
      'sardine',
      'cod',
      'mackerel',
      'tilapia',
      'catfish',
      'nuoc mam',
      'herring',
      'trout',
      'carp',
      'perch',
      'haddock',
      'pollock',
      'halibut',
    ],
    [
      'hai san',
      'fish',
      'ca',
      'shrimp',
      'tom',
      'crab',
      'cua',
      'clam',
      'ngheu',
      'so',
      'oyster',
      'hau',
      'mussel',
      'scallop',
      'squid',
      'muc',
      'lobster',
      'salmon',
      'tuna',
      'anchovy',
      'nuoc mam',
      'herring',
      'trout',
      'sardine',
      'cod',
      'mackerel',
      'tilapia',
      'catfish',
      'carp',
      'perch',
      'haddock',
      'pollock',
      'halibut',
      'octopus',
      'bach tuoc',
    ],
    ['me', 'vung', 'sesame', 'tahini'],
  ];

  static bool _phrase(String text, String term) => RegExp(
    '(^|[^a-z0-9])${RegExp.escape(term)}(?=\$|[^a-z0-9])',
  ).hasMatch(text);

  bool matchesText(String raw) {
    if (!isActive) return false;
    // Plant milk/butter are not automatically dairy; a separate dairy
    // ingredient in the same description still matches after this removal.
    final text = normalizeFoodSearch(raw);
    for (final term in terms) {
      final group = _groups.where((g) => g.contains(term)).firstOrNull;
      var screened = text;
      if (identical(group, _groups.first)) {
        screened = screened
            .replaceAll(
              RegExp(
                r'\b(soy|almond|coconut|oat|rice|peanut)\s*(milk|butter)\b',
              ),
              ' ',
            )
            .replaceAll(
              RegExp(r'\bsua\s+(dau nanh|hanh nhan|dua|yen mach|gao)\b'),
              ' ',
            )
            .replaceAll(RegExp(r'\bbo\s+(dau phong|lac|hanh nhan)\b'), ' ');
      }
      if (group?.contains('ca') == true) {
        screened = screened.replaceAll(
          RegExp(r'\bca\s+(tim|chua|rot|phe)\b'),
          ' ',
        );
      }
      if ((group ?? [term]).any((word) => _phrase(screened, word))) return true;
    }
    return false;
  }

  FoodAvoidanceStatus assess(FoodCatalogItem food) {
    if (!isActive) return FoodAvoidanceStatus.noKnownMatch;
    // Match names as well as source ingredients, never infer absence from name.
    if ([food.name, ...food.ingredientNames].any(matchesText) ||
        (food.originalName != null && matchesText(food.originalName!))) {
      return FoodAvoidanceStatus.containsAvoided;
    }
    return food.ingredientsKnown
        ? FoodAvoidanceStatus.noKnownMatch
        : FoodAvoidanceStatus.unknown;
  }

  bool allows(FoodCatalogItem food) =>
      assess(food) == FoodAvoidanceStatus.noKnownMatch;

  List<MealItemSnapshot> flaggedSnapshots(
    List<MealItemSnapshot> items,
    List<FoodCatalogItem> catalog,
  ) {
    if (!isActive) return const [];
    return items.where((item) {
      final food = catalog
          .where(
            (f) =>
                f.id == item.foodId &&
                f.name == item.name &&
                f.sourceLabel == item.sourceLabel,
          )
          .firstOrNull;
      if (food == null || item.quantityUnit != 'g' || !allows(food)) {
        return true;
      }
      final current = food.forGrams(item.grams);
      return [
        (current.kcal, item.nutrition.kcal),
        (current.proteinG, item.nutrition.proteinG),
        (current.carbsG, item.nutrition.carbsG),
        (current.fatG, item.nutrition.fatG),
      ].any((p) => (p.$1 - p.$2).abs() > .01);
    }).toList();
  }
}
