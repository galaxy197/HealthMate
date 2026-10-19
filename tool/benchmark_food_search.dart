import 'dart:convert';
import 'dart:io';
import 'package:healthmate/features/nutrition/models/catalog_food_reader.dart';
import 'package:healthmate/features/nutrition/models/food_catalog_search.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

// Fixed BEFORE running the benchmark: Vietnamese meals, exact packaged variants,
// unsupported products and a held-out group. Missing brands are not counted as
// correct products just because a generic milk happens to match.
const cases = [
  ('vietnamese', 'pho bo', ['vn-pho-bo']),
  ('vietnamese', 'com ga', ['vn-com-ga']),
  ('vietnamese', 'bun bo hue', ['vn-bun-bo-hue']),
  (
    'vietnamese',
    'banh mi',
    ['vn-banh-mi-thit', 'vn-banh-mi-trung', 'vn2007-1012'],
  ),
  ('vietnamese', 'com tam', ['vn-com-tam-suon']),
  ('vietnamese', 'dau sot ca', ['vn-dau-sot-ca']),
  ('packaged', 'sua chua TH co duong', ['th-yogurt-sweetened-100g']),
  ('packaged', 'TH yogurt vi tu nhien', ['th-yogurt-natural-100g']),
  ('packaged', 'sua chua TH sau rieng', ['th-yogurt-durian-100g']),
  ('unsupported', 'Vinamilk 180ml', <String>[]),
  ('unsupported', 'TH true milk 180 ml', <String>[]),
  ('unsupported', 'Milo hop 180ml', <String>[]),
  ('held-out', 'bun cha', ['vn-bun-cha']),
  ('held-out', 'com gao luc', ['vn-com-gao-lut']),
  ('held-out', 'ca loc hap', ['vn-ca-loc-hap']),
  ('held-out', 'bo xao rau', ['vn-bo-xao-rau']),
  ('held-out', 'PHO\u031b\u0309 BO\u0300', ['vn-pho-bo']),
  ('held-out', 'sua chua tu nhien TH', ['th-yogurt-natural-100g']),
  ('held-out-unsupported', 'pizza XYZ', <String>[]),
];

void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError('catalog JSON input; new output JSON path');
  }
  final raw = jsonDecode(File(args[0]).readAsStringSync()) as List;
  final catalog = [
    for (final d in raw)
      readCatalogFood(d['id'] as String, Map<String, dynamic>.from(d)),
  ];
  List<FoodCatalogItem> old(String query) => catalog
      .where(
        (food) => [food.name, ...food.alternateNames].any(
          (name) =>
              normalizeFoodSearch(name).contains(normalizeFoodSearch(query)),
        ),
      )
      .toList();
  final results = <Map<String, Object?>>[];
  for (final c in cases) {
    final before = old(c.$2), after = searchFoodCatalog(catalog, c.$2);
    results.add({
      'group': c.$1,
      'query': c.$2,
      'expectedIds': c.$3,
      'before': before.map((f) => f.id).toList(),
      'after': after.map((f) => f.id).toList(),
      'correctFirst': c.$3.isEmpty
          ? after.isEmpty
          : after.isNotEmpty && c.$3.contains(after.first.id),
      'noisyMatches': after
          .where((f) => !c.$3.contains(f.id))
          .map((f) => f.id)
          .toList(),
    });
  }
  final clock = Stopwatch()..start();
  for (var i = 0; i < 100; i++) {
    for (final c in cases) {
      searchFoodCatalog(catalog, c.$2);
    }
  }
  clock.stop();
  final report = {
    'method':
        'same source dataset; old substring vs new ranking; fixed cases and held-out group; timing local CPU only',
    'catalogCount': catalog.length,
    'queries': cases.length,
    'correctFirst': results.where((r) => r['correctFirst'] == true).length,
    'elapsedMicrosecondsFor100Passes': clock.elapsedMicroseconds,
    'emptyQueryBrowseCount': searchFoodCatalog(catalog, '').length,
    'results': results,
  };
  final output = File(args[1]);
  if (output.existsSync()) {
    throw const FileSystemException('Choose a new benchmark output path.');
  }
  output.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  stdout.writeln(
    'Search benchmark: ${report['correctFirst']}/${cases.length} correct-first or deliberate empty; inspect all noisy matches in report.',
  );
}
