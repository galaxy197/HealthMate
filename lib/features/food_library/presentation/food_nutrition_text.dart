import 'package:intl/intl.dart';
import '../../nutrition/models/nutrition_models.dart';

String foodNumber(num value) => NumberFormat('0.##', 'vi_VN').format(value);
String nutritionLabel(NutritionTotals value) =>
    '${NumberFormat('0', 'vi_VN').format(value.kcal)} kcal · Đạm ${foodNumber(value.proteinG)} g · Tinh bột ${foodNumber(value.carbsG)} g · Béo ${foodNumber(value.fatG)} g';
