import 'package:flutter/material.dart';
import '../data/barcode_product_service.dart';
import '../../nutrition/models/nutrition_models.dart';

/// Bottom sheet hiển thị thông tin sản phẩm từ barcode
class BarcodeProductDetailSheet extends StatefulWidget {
  final BarcodeProduct product;

  const BarcodeProductDetailSheet({
    required this.product,
    super.key,
  });

  @override
  State<BarcodeProductDetailSheet> createState() =>
      _BarcodeProductDetailSheetState();
}

class _BarcodeProductDetailSheetState extends State<BarcodeProductDetailSheet> {
  late final TextEditingController _gramsController;
  double _currentGrams = 100;

  @override
  void initState() {
    super.initState();
    // Default serving size hoặc 100g
    _currentGrams = widget.product.servingSizeG ?? 100;
    _gramsController = TextEditingController(
      text: _currentGrams.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  NutritionTotals? get _scaledNutrition {
    if (widget.product.nutrition == null) return null;
    final scale = _currentGrams / 100;
    final base = widget.product.nutrition!;
    return NutritionTotals(
      kcal: base.kcal * scale,
      proteinG: base.proteinG * scale,
      carbsG: base.carbsG * scale,
      fatG: base.fatG * scale,
    );
  }

  void _updateGrams(String value) {
    final grams = double.tryParse(value);
    if (grams != null && grams > 0 && grams <= 9999) {
      setState(() => _currentGrams = grams);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nutrition = _scaledNutrition;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Product image
              if (widget.product.imageUrl != null)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(widget.product.imageUrl!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

              // Product name
              Text(
                widget.product.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Brand
              if (widget.product.brand != null)
                Text(
                  widget.product.brand!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 8),

              // Barcode & Source
              Row(
                children: [
                  Chip(
                    label: Text(widget.product.barcode),
                    avatar: const Icon(Icons.qr_code, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(widget.product.source),
                    avatar: const Icon(Icons.source, size: 16),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Serving size input
              Text(
                'Điều chỉnh khẩu phần',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gramsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Khối lượng (g)',
                        suffixText: 'g',
                      ),
                      onChanged: _updateGrams,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (widget.product.servingSizeG != null)
                    TextButton(
                      onPressed: () {
                        final serving = widget.product.servingSizeG!;
                        _gramsController.text = serving.toStringAsFixed(0);
                        _updateGrams(serving.toString());
                      },
                      child: const Text('Khẩu phần gốc'),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Nutrition info
              if (nutrition != null) ...[
                Text(
                  'Thông tin dinh dưỡng',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _NutritionRow(
                  label: 'Năng lượng',
                  value: '${nutrition.kcal.toStringAsFixed(0)} kcal',
                  color: Colors.orange,
                ),
                _NutritionRow(
                  label: 'Protein',
                  value: '${nutrition.proteinG.toStringAsFixed(1)} g',
                  color: Colors.blue,
                ),
                _NutritionRow(
                  label: 'Carbs',
                  value: '${nutrition.carbsG.toStringAsFixed(1)} g',
                  color: Colors.green,
                ),
                _NutritionRow(
                  label: 'Chất béo',
                  value: '${nutrition.fatG.toStringAsFixed(1)} g',
                  color: Colors.red,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tính cho ${_currentGrams.toStringAsFixed(0)} g',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sản phẩm này thiếu thông tin dinh dưỡng.\n'
                          'Bạn có thể nhập thủ công sau.',
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quét lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: nutrition != null
                          ? () => Navigator.pop(context, widget.product)
                          : null,
                      child: const Text('Thêm vào bữa ăn'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutritionRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
