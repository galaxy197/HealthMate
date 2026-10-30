import 'package:flutter/material.dart';
import '../models/food_diet.dart';

class FoodDietFilter extends StatelessWidget {
  const FoodDietFilter({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final FoodDietPreference value;
  final ValueChanged<FoodDietPreference>? onChanged;

  @override
  Widget build(BuildContext context) =>
      DropdownButtonFormField<FoodDietPreference>(
        key: const ValueKey('food-diet-filter'),
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Chế độ ăn'),
        items: [
          for (final diet in FoodDietPreference.values)
            DropdownMenuItem(value: diet, child: Text(diet.label)),
        ],
        onChanged: onChanged == null
            ? null
            : (diet) {
                if (diet != null) onChanged!(diet);
              },
      );
}
