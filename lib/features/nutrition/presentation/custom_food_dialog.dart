import 'package:flutter/material.dart';

import '../models/nutrition_models.dart';
import '../models/nutrition_validation.dart';

class CustomFoodDialog extends StatefulWidget {
  const CustomFoodDialog({super.key});

  @override
  State<CustomFoodDialog> createState() => _CustomFoodDialogState();
}

class _CustomFoodDialogState extends State<CustomFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _grams = TextEditingController(text: '100');
  final _kcal = TextEditingController();
  final _protein = TextEditingController(text: '0');
  final _carbs = TextEditingController(text: '0');
  final _fat = TextEditingController(text: '0');
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _grams, _kcal, _protein, _carbs, _fat]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _nameValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Tên món cần ít nhất 2 ký tự.';
    if (text.length > 100) return 'Tên món tối đa 100 ký tự.';
    return null;
  }

  String? _nutrientValidator(String? value, {required double max}) {
    final parsed = NutritionValidation.parseDecimal(value);
    if (parsed == null || parsed < 0 || parsed > max) {
      return 'Nhập số từ 0 đến ${max.toStringAsFixed(0)}.';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final grams = NutritionValidation.parseDecimal(_grams.text)!;
    final per100g = NutritionTotals(
      kcal: NutritionValidation.parseDecimal(_kcal.text)!,
      proteinG: NutritionValidation.parseDecimal(_protein.text)!,
      carbsG: NutritionValidation.parseDecimal(_carbs.text)!,
      fatG: NutritionValidation.parseDecimal(_fat.text)!,
    );
    final nutrition = per100g.scale(grams / 100);
    if (nutrition.kcal > 10000 ||
        nutrition.proteinG > 1000 ||
        nutrition.carbsG > 1000 ||
        nutrition.fatG > 1000) {
      setState(() {
        _error = 'Giá trị theo khẩu phần vượt giới hạn có thể lưu.';
      });
      return;
    }
    final name = _name.text.trim();
    Navigator.pop(
      context,
      MealItemSnapshot(
        foodId: 'custom-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        grams: grams,
        nutrition: nutrition,
        sourceLabel: 'Người dùng nhập · Ước tính',
        isEstimated: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Món ngoài danh mục'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nhập giá trị trên 100 g từ nhãn thực phẩm hoặc nguồn bạn có. HealthMate sẽ lưu món này với nhãn “Ước tính”.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('custom-food-name'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Tên món'),
                  validator: _nameValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('custom-food-grams'),
                  controller: _grams,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Khối lượng đã ăn',
                    suffixText: 'g',
                  ),
                  validator: NutritionValidation.grams,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('custom-food-kcal'),
                  controller: _kcal,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Năng lượng trên 100 g',
                    suffixText: 'kcal',
                  ),
                  validator: (value) => _nutrientValidator(value, max: 10000),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _macroField(_protein, 'Protein', 'protein'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _macroField(_carbs, 'Carb', 'carbs')),
                    const SizedBox(width: 8),
                    Expanded(child: _macroField(_fat, 'Chất béo', 'fat')),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('save-custom-food'),
          onPressed: _submit,
          child: const Text('Thêm món'),
        ),
      ],
    );
  }

  Widget _macroField(
    TextEditingController controller,
    String label,
    String keyName,
  ) {
    return TextFormField(
      key: ValueKey('custom-food-$keyName'),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: 'g/100 g'),
      validator: (value) => _nutrientValidator(value, max: 1000),
    );
  }
}
