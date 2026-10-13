import 'package:flutter/material.dart';

import '../models/nutrition_models.dart';
import '../models/nutrition_validation.dart';

class MealFormDialog extends StatefulWidget {
  const MealFormDialog({
    required this.catalog,
    this.meal,
    this.suggestedFood,
    this.initialSearch = '',
    this.aiAssisted = false,
    super.key,
  });

  final List<FoodCatalogItem> catalog;
  final MealLog? meal;
  final FoodCatalogItem? suggestedFood;
  final String initialSearch;
  final bool aiAssisted;

  @override
  State<MealFormDialog> createState() => _MealFormDialogState();
}

class _MealFormDialogState extends State<MealFormDialog> {
  late MealType _type;
  late DateTime _consumedAt;
  late List<MealItemSnapshot> _items;
  late final TextEditingController _searchController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.meal?.type ?? _typeFor(DateTime.now());
    _consumedAt = widget.meal?.consumedAt ?? DateTime.now();
    _items = [...?widget.meal?.items];
    _searchController = TextEditingController(text: widget.initialSearch);
    if (widget.suggestedFood case final food?) {
      _items.add(MealItemSnapshot.fromCatalog(food, 100));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static MealType _typeFor(DateTime time) => switch (time.hour) {
    < 10 => MealType.breakfast,
    < 14 => MealType.lunch,
    < 18 => MealType.snack,
    _ => MealType.dinner,
  };

  List<FoodCatalogItem> get _results {
    final query = _searchController.text.trim().toLowerCase();
    final source = query.isEmpty
        ? widget.catalog
        : widget.catalog.where((food) {
            return food.name.toLowerCase().contains(query) ||
                food.alternateNames.any(
                  (name) => name.toLowerCase().contains(query),
                );
          });
    return source.take(8).toList(growable: false);
  }

  Future<double?> _askGrams({double initial = 100}) async {
    final controller = TextEditingController(text: _formatNumber(initial));
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khối lượng đã ăn'),
        content: Form(
          key: formKey,
          child: TextFormField(
            key: const ValueKey('meal-grams'),
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Khối lượng (g)',
              suffixText: 'g',
            ),
            validator: NutritionValidation.grams,
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  context,
                  NutritionValidation.parseDecimal(controller.text),
                );
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  context,
                  NutritionValidation.parseDecimal(controller.text),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _add(FoodCatalogItem food) async {
    if (_items.length >= NutritionValidation.maxItemsPerMeal) {
      setState(() => _error = 'Mỗi bữa tối đa 5 mục.');
      return;
    }
    final grams = await _askGrams();
    if (grams == null || !mounted) return;
    setState(() {
      _items.add(MealItemSnapshot.fromCatalog(food, grams));
      _error = null;
    });
  }

  Future<void> _edit(int index) async {
    final current = _items[index];
    final grams = await _askGrams(initial: current.grams);
    if (grams == null || !mounted) return;
    final catalogItem = widget.catalog
        .where((food) => food.id == current.foodId)
        .firstOrNull;
    setState(() {
      _items[index] = catalogItem != null
          ? MealItemSnapshot.fromCatalog(catalogItem, grams)
          : MealItemSnapshot(
              foodId: current.foodId,
              name: current.name,
              grams: grams,
              nutrition: current.nutrition.scale(grams / current.grams),
              sourceLabel: current.sourceLabel,
              isEstimated: current.isEstimated,
            );
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _consumedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Ngày dùng bữa',
    );
    if (date == null || !mounted) return;
    setState(() {
      _consumedAt = DateTime(
        date.year,
        date.month,
        date.day,
        _consumedAt.hour,
        _consumedAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_consumedAt),
      helpText: 'Giờ dùng bữa',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _consumedAt = DateTime(
        _consumedAt.year,
        _consumedAt.month,
        _consumedAt.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  void _submit() {
    if (_items.isEmpty) {
      setState(() => _error = 'Hãy chọn ít nhất một món ăn.');
      return;
    }
    final draft = MealDraft(
      type: _type,
      consumedAt: _consumedAt,
      items: List.unmodifiable(_items),
      source: widget.aiAssisted || widget.meal?.source == MealSource.aiAssisted
          ? MealSource.aiAssisted
          : MealSource.manual,
    );
    if (draft.totals.kcal > NutritionValidation.maxMealKcal) {
      setState(() => _error = 'Tổng năng lượng vượt giới hạn hợp lệ.');
      return;
    }
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = MaterialLocalizations.of(context);
    final totals = _items.fold(
      const NutritionTotals(),
      (sum, item) => sum + item.nutrition,
    );
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.meal == null ? 'Thêm bữa ăn' : 'Sửa bữa ăn'),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Hủy',
            icon: const Icon(Icons.close_rounded),
          ),
          actions: [
            TextButton(
              key: const ValueKey('save-meal'),
              onPressed: _submit,
              child: const Text('Lưu'),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                DropdownButtonFormField<MealType>(
                  key: const ValueKey('meal-type'),
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Loại bữa ăn'),
                  items: [
                    for (final type in MealType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(locale.formatMediumDate(_consumedAt)),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(
                        locale.formatTimeOfDay(
                          TimeOfDay.fromDateTime(_consumedAt),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Tìm món trong danh mục',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('food-search'),
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: cơm, trứng, chuối…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                if (_results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Không tìm thấy món phù hợp trong danh mục.'),
                  )
                else
                  ..._results.map(
                    (food) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.per100g.kcal.toStringAsFixed(0)} kcal / 100 g · ${food.sourceLabel}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton.filledTonal(
                        onPressed: () => _add(food),
                        tooltip: 'Thêm ${food.name}',
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ),
                const Divider(height: 32),
                Text('Món đã chọn', style: theme.textTheme.titleMedium),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Chưa có món nào.'),
                  )
                else
                  ..._items.indexed.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.$2.name),
                      subtitle: Text(
                        '${_formatNumber(entry.$2.grams)} g · ${entry.$2.nutrition.kcal.toStringAsFixed(0)} kcal'
                        '${entry.$2.isEstimated ? ' · Ước tính' : ''}',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            onPressed: () => _edit(entry.$1),
                            tooltip: 'Sửa khẩu phần',
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _items.removeAt(entry.$1)),
                            tooltip: 'Bỏ món',
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                Card(
                  color: theme.colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${totals.kcal.toStringAsFixed(0)} kcal  ·  '
                      'P ${totals.proteinG.toStringAsFixed(1)} g  ·  '
                      'C ${totals.carbsG.toStringAsFixed(1)} g  ·  '
                      'F ${totals.fatG.toStringAsFixed(1)} g',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Lưu bữa ăn'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);
