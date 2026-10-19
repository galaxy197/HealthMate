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

Future<double?> askSnapshotQuantity(
  BuildContext context,
  MealItemSnapshot snapshot,
) => showDialog<double>(
  context: context,
  builder: (_) =>
      FoodPortionDialog(initial: snapshot.quantity, snapshot: snapshot),
);

class FoodPortionDialog extends StatefulWidget {
  const FoodPortionDialog({
    required this.initial,
    this.food,
    this.snapshot,
    super.key,
  });
  final double initial;
  final FoodCatalogItem? food;
  final MealItemSnapshot? snapshot;
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

  void _switchUnit(bool portions) {
    if (_portions == portions) return;
    final grams = _grams;
    setState(() {
      _portions = portions;
      _amount.text = grams == null
          ? ''
          : (grams / (portions ? widget.food!.servingGrams! : 1)).toString();
    });
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
          nutrition.fiberG,
        ].any((value) => !value.isFinite || value < 0) ||
        nutrition.kcal > 10000 ||
        nutrition.proteinG > 1000 ||
        nutrition.carbsG > 1000 ||
        nutrition.fatG > 1000 ||
        nutrition.fiberG > 1000) {
      return 'Khẩu phần vượt giới hạn lưu của một món. Hãy giảm lượng trong bản ghi này.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final hasPortion = food?.hasValidServing == true;
    final grams = _grams;
    return AlertDialog(
      title: Text(
        widget.snapshot?.quantityUnit != null &&
                widget.snapshot!.quantityUnit != 'g'
            ? 'Lượng đã ghi'
            : 'Khối lượng đã ăn',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasPortion) ...[
                Text(
                  '1 ${food!.servingLabel} = ${foodNumber(food.servingGrams!)} g',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Gram'),
                      selected: !_portions,
                      onSelected: (_) => _switchUnit(false),
                    ),
                    ChoiceChip(
                      key: const ValueKey('portion-unit'),
                      label: Text(food.servingLabel!),
                      selected: _portions,
                      onSelected: (_) => _switchUnit(true),
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
                      : 'Lượng (${widget.snapshot?.quantityUnitLabel ?? 'g'})',
                  suffixText: _portions
                      ? null
                      : widget.snapshot?.quantityUnitLabel ?? 'g',
                ),
                onChanged: (_) => setState(() {}),
                validator: (_) => _validate(),
                onFieldSubmitted: (_) => _submit(),
              ),
              if (grams != null &&
                  grams.isFinite &&
                  grams > 0 &&
                  grams <= 2000) ...[
                Text(
                  'Quy đổi: ${foodNumber(grams)} ${widget.snapshot?.quantityUnitLabel ?? 'g'}',
                ),
                if (widget.snapshot != null)
                  Text(
                    nutritionLabel(
                      widget.snapshot!.withQuantity(grams).nutrition,
                    ),
                  ),
                if (food?.hasNutritionData == true)
                  Text(nutritionLabel(food!.forGrams(grams))),
              ],
              if (food?.servingMetadataInvalid == true)
                const Text(
                  'Thông tin khẩu phần chưa hợp lệ. Hãy dùng khối lượng gram đã cân.',
                ),
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
