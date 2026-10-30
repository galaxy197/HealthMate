import 'dart:convert';
import 'dart:io';
import 'package:healthmate/features/nutrition/models/catalog_food_reader.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';

void main(List<String> args) {
  final foods = [
    for (final path in [
      'assets/nutrition/vietnamese-foods.json',
      'assets/nutrition/usda-sr-legacy.json',
      'assets/nutrition/usda-current.json',
    ])
      for (final raw
          in jsonDecode(File(path).readAsStringSync())['foods'] as List)
        readCatalogFood(raw['id'] as String, Map<String, dynamic>.from(raw)),
  ]..sort(compareCatalogFoods);
  final result = <String, Object?>{'catalogCount': foods.length};
  for (final query in [
    'pho bo',
    'thit ga uc',
    'sua chua',
    'broccoli',
    'dau phu',
  ]) {
    final clock = Stopwatch()..start();
    final matches = searchFoodCatalog(foods, query);
    clock.stop();
    result[query] = {
      'milliseconds': clock.elapsedMicroseconds / 1000,
      'matches': matches.length,
      'firstIds': matches.take(3).map((f) => f.id).toList(),
    };
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
}
