import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/catalog_food_reader.dart';
import '../models/nutrition_models.dart';

Future<List<FoodCatalogItem>> loadBundledVietnameseFoods() async {
  final json =
      jsonDecode(
            await rootBundle.loadString(
              'assets/nutrition/vietnamese-foods.json',
            ),
          )
          as Map<String, dynamic>;
  return [
    for (final raw in json['foods'] as List)
      readCatalogFood(
        (raw as Map)['id'] as String,
        Map<String, dynamic>.from(raw),
      ),
  ];
}
