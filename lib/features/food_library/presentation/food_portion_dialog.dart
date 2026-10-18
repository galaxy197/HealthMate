import 'package:flutter/material.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/models/nutrition_validation.dart';
import 'food_nutrition_text.dart';

Future<double?> askFoodGrams(
  BuildContext context, {
  double initial = 100,
  FoodCatalogItem? food,
}) => showDialog<double>(
  context: context,
  builder: (_) => FoodPortionDialog(initial: initial, food: food),
);

class FoodPortionDialog extends StatefulWidget {
  const FoodPortionDialog({required this.initial, this.food, super.key});
  final double initial;
  final FoodCatalogItem? food;
  @override
  State<FoodPortionDialog> createState() => _FoodPortionDialogState();
}

class _FoodPortionDialogState extends State<FoodPortionDialog> {
  late final TextEditingController _amount;
  bool _portions = false;
  final _form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: widget.initial.toString());
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _grams {
    final amount = NutritionValidation.parseDecimal(_amount.text);
    return amount == null
        ? null
        : amount * (_portions ? widget.food!.servingGrams! : 1);
  }

  void _submit() {
    if (_form.currentState!.validate()) Navigator.pop(context, _grams);
  }

  String? _validate() {
    final error = NutritionValidation.grams(_grams?.toString());
    if (error != null || widget.food == null) return error;
    final nutrition = widget.food!.forGrams(_grams!);
    if ([
          nutrition.kcal,
          nutrition.proteinG,
          nutrition.carbsG,
          nutrition.fatG,
        ].any((value) => !value.isFinite || value < 0) ||
        nutrition.kcal > 10000 ||
        nutrition.proteinG > 1000 ||
        nutrition.carbsG > 1000 ||
        nutrition.fatG > 1000) {
      return 'Khẩu phần vượt giới hạn lưu của một món. Hãy giảm lượng trong bản ghi này.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final hasPortion =
        food?.servingGrams != null &&
        food!.servingGrams!.isFinite &&
        food.servingGrams! > 0 &&
        food.servingLabel != null;
    final grams = _grams;
    return AlertDialog(
      title: const Text('Khối lượng đã ăn'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasPortion) ...[
                Text(
                  '1 ${food.servingLabel} = ${foodNumber(food.servingGrams!)} g',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Gram'),
                      selected: !_portions,
                      onSelected: (_) => setState(() {
                        _portions = false;
                        _amount.text = widget.initial.toString();
                      }),
                    ),
                    ChoiceChip(
                      key: const ValueKey('portion-unit'),
                      label: Text(food.servingLabel!),
                      selected: _portions,
                      onSelected: (_) => setState(() {
                        _portions = true;
                        _amount.text = '1';
                      }),
                    ),
                  ],
                ),
              ],
              TextFormField(
                key: const ValueKey('meal-grams'),
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _portions
                      ? 'Số ${food!.servingLabel}'
                      : 'Khối lượng (g)',
                  suffixText: _portions ? null : 'g',
                ),
                onChanged: (_) => setState(() {}),
                validator: (_) => _validate(),
                onFieldSubmitted: (_) => _submit(),
              ),
              if (grams != null &&
                  grams.isFinite &&
                  grams > 0 &&
                  grams <= 2000) ...[
                Text('Quy đổi: ${foodNumber(grams)} g'),
                if (food != null) Text(nutritionLabel(food.forGrams(grams))),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Xác nhận')),
      ],
    );
  }
}
