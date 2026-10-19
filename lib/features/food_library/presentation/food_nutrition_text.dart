import 'package:intl/intl.dart';
import '../../nutrition/models/nutrition_models.dart';

String foodNumber(num value) => NumberFormat('0.##', 'vi_VN').format(value);
String macroAmount(double value, bool known) => known
    ? '${foodNumber(value)} g'
    : value > 0
    ? '≥${foodNumber(value)} g (chưa đủ)'
    : 'Chưa đủ dữ liệu';
String snapshotQuantityLabel(MealItemSnapshot item) =>
    '${foodNumber(item.quantity)} ${item.quantityUnitLabel}';
String nutritionLabel(NutritionTotals value) =>
    '${NumberFormat('0', 'vi_VN').format(value.kcal)} kcal · Đạm ${macroAmount(value.proteinG, value.proteinKnown)} · Tinh bột ${macroAmount(value.carbsG, value.carbsKnown)} · Béo ${macroAmount(value.fatG, value.fatKnown)} · Chất xơ ${macroAmount(value.fiberG, value.fiberKnown)}';
