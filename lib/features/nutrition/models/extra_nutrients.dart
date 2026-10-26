import 'dart:convert';

enum ExtraNutrient {
  sugar('Đường', 'g', 2000),
  saturatedFat('Béo bão hòa', 'g', 2000),
  sodium('Natri', 'mg', 100000),
  potassium('Kali', 'mg', 100000),
  calcium('Canxi', 'mg', 100000),
  iron('Sắt', 'mg', 10000),
  vitaminC('Vitamin C', 'mg', 100000),
  cholesterol('Cholesterol', 'mg', 100000);

  const ExtraNutrient(this.label, this.unit, this.maximum);
  final String label, unit;
  final double maximum;
}

Map<String, double> readExtraNutrients(Object? raw) {
  if (raw is String) {
    try {
      final vector = jsonDecode(raw);
      if (vector is! List || vector.length != ExtraNutrient.values.length) {
        return const {};
      }
      raw = {for (final n in ExtraNutrient.values) n.name: vector[n.index]};
    } catch (_) {
      return const {};
    }
  }
  if (raw is! Map) return const {};
  return {
    for (final n in ExtraNutrient.values)
      if (raw[n.name] case final num v
          when v.isFinite && v >= 0 && v <= n.maximum)
        n.name: v.toDouble(),
  };
}

/// Fixed order/units, 6 decimal places, null=unknown. One bounded Rules regex
/// validates this versioned wire representation even with six ingredients.
String encodeExtraNutrients(Map<String, double> values) =>
    '[${ExtraNutrient.values.map((n) {
      final value = values[n.name];
      if (value == null) return 'null';
      return (value == 0 ? 0.0 : value).toStringAsFixed(6);
    }).join(',')}]';

Map<String, double> scaleExtras(Map<String, double> values, double factor) => {
  for (final e in values.entries) e.key: e.value * factor,
};

// A sum is known only when every contributing ingredient has that nutrient.
Map<String, double> sumExtras(Map<String, double> a, Map<String, double> b) => {
  for (final key in a.keys)
    if (b.containsKey(key)) key: a[key]! + b[key]!,
};
