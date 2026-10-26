import 'dart:convert';
import '../../nutrition/models/nutrition_models.dart';

/// Reference values proposed by AI, never treated as verified catalog data.
class AiFoodNutrition {
  const AiFoodNutrition({
    this.kcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
  });
  final double? kcal, proteinG, carbsG, fatG, fiberG;
  bool get isComplete =>
      kcal != null && proteinG != null && carbsG != null && fatG != null;
  NutritionTotals? get totals => kcal == null
      ? null
      : NutritionTotals(
          kcal: kcal!,
          proteinG: proteinG ?? 0,
          carbsG: carbsG ?? 0,
          fatG: fatG ?? 0,
          fiberG: fiberG ?? 0,
          proteinKnown: proteinG != null,
          carbsKnown: carbsG != null,
          fatKnown: fatG != null,
          fiberKnown: fiberG != null,
        );
  factory AiFoodNutrition.fromData(Map<String, dynamic> data) =>
      AiFoodNutrition(
        kcal: readNumber(data['kcal'], 1000),
        proteinG: readNumber(data['proteinG'], 100),
        carbsG: readNumber(data['carbsG'], 100),
        fatG: readNumber(data['fatG'], 100),
        fiberG: readNumber(data['fiberG'], 100),
      );
  static double? readNumber(
    Object? value,
    double max, {
    bool positive = false,
  }) {
    if (value == null) return null;
    if (value is! num ||
        !value.isFinite ||
        (positive ? value <= 0 : value < 0) ||
        value > max) {
      throw const FormatException('Invalid AI nutrition or serving.');
    }
    return value.toDouble();
  }
}

class AiFoodSuggestion {
  const AiFoodSuggestion({
    required this.dishName,
    required this.description,
    required this.ingredients,
    required this.searchTerms,
    this.isFood = true,
    this.estimatedNutritionPer100g,
    this.estimatedServingGrams,
  });

  final String dishName;
  final String description;
  final List<String> ingredients;
  final List<String> searchTerms;
  final bool isFood;
  final AiFoodNutrition? estimatedNutritionPer100g;
  final double? estimatedServingGrams;

  factory AiFoodSuggestion.fromJsonText(String source) {
    if (source.length > 16384) {
      throw const FormatException('Response too long.');
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map) throw const FormatException('Expected object.');
    final map = Map<String, dynamic>.from(decoded);
    final dishName = _requiredText(map['dishName'], 80);
    final description = _requiredText(map['description'], 240);
    final ingredients = _textList(map['ingredients'], 12, 60);
    final searchTerms = _textList(map['searchTerms'], 8, 60);
    final isFood = map['isFood'] ?? true;
    if (isFood is! bool) throw const FormatException('Invalid food indicator.');
    if (isFood && searchTerms.isEmpty) {
      throw const FormatException('Missing search terms.');
    }
    final nutrition = map['estimatedNutritionPer100g'];
    if (nutrition != null && nutrition is! Map) {
      throw const FormatException('Invalid nutrition.');
    }
    return AiFoodSuggestion(
      dishName: dishName,
      description: description,
      ingredients: ingredients,
      searchTerms: searchTerms,
      isFood: isFood,
      estimatedNutritionPer100g: !isFood || nutrition == null
          ? null
          : AiFoodNutrition.fromData(
              Map<String, dynamic>.from(nutrition as Map),
            ),
      estimatedServingGrams: !isFood
          ? null
          : AiFoodNutrition.readNumber(
              map['estimatedServingGrams'],
              2000,
              positive: true,
            ),
    );
  }

  static String _requiredText(Object? value, int maxLength) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Missing text.');
    }
    final text = value.trim();
    if (text.length > maxLength) throw const FormatException('Text too long.');
    return text;
  }

  static List<String> _textList(Object? value, int maxItems, int maxLength) {
    if (value is! List || value.length > maxItems) {
      throw const FormatException('Invalid list.');
    }
    return value.map((item) => _requiredText(item, maxLength)).toList();
  }
}
