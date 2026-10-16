import 'dart:convert';

class AiFoodSuggestion {
  const AiFoodSuggestion({
    required this.dishName,
    required this.description,
    required this.ingredients,
    required this.searchTerms,
  });

  final String dishName;
  final String description;
  final List<String> ingredients;
  final List<String> searchTerms;

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
    if (searchTerms.isEmpty) {
      throw const FormatException('Missing search terms.');
    }
    return AiFoodSuggestion(
      dishName: dishName,
      description: description,
      ingredients: ingredients,
      searchTerms: searchTerms,
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
