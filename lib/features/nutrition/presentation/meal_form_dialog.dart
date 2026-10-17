import 'package:flutter/material.dart';
import '../../../core/widgets/confirmed_save.dart';

import '../models/nutrition_models.dart';
import '../models/food_catalog_search.dart';
import '../models/nutrition_validation.dart';
import 'custom_food_dialog.dart';

class MealFormDialog extends StatefulWidget {
  const MealFormDialog({
    required this.catalog,
    this.recentItems = const [],
    this.meal,
    this.initialConsumedAt,
    this.initialType,
    this.initialItems = const [],
    this.suggestedFood,
    this.initialSearch = '',
    this.aiAssisted = false,
    this.onSave,
    super.key,
  });

  final List<FoodCatalogItem> catalog;
  final List<MealItemSnapshot> recentItems;
  final MealLog? meal;
  final DateTime? initialConsumedAt;
  final MealType? initialType;
  final List<MealItemSnapshot> initialItems;
  final FoodCatalogItem? suggestedFood;
  final String initialSearch;
  final bool aiAssisted;
  final Future<bool> Function(MealDraft)? onSave;

  @override
  State<MealFormDialog> createState() => _MealFormDialogState();
}

class _MealFormDialogState extends State<MealFormDialog>
    with ConfirmedSave<MealDraft, MealFormDialog> {
  late MealType _type;
  late DateTime _consumedAt;
  late List<MealItemSnapshot> _items;
  late final TextEditingController _searchController;
  String? _error;
  static const _foodPageSize = 12;
  int _visibleFoodCount = _foodPageSize;

  @override
  void initState() {
    super.initState();
    _consumedAt =
        widget.meal?.consumedAt ?? widget.initialConsumedAt ?? DateTime.now();
    _type = widget.meal?.type ?? widget.initialType ?? _typeFor(_consumedAt);
    _items = [...?widget.meal?.items, ...widget.initialItems];
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

  List<FoodCatalogItem> get _results =>
      searchFoodCatalog(widget.catalog, _searchController.text);

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

  Future<void> _addRecent(MealItemSnapshot item) async {
    if (_items.length >= NutritionValidation.maxItemsPerMeal) {
      setState(() => _error = 'Mỗi bữa tối đa 5 mục.');
      return;
    }
    final grams = await _askGrams(initial: item.grams);
    if (grams == null || !mounted) return;
    try {
      final resized = item.withGrams(grams);
      setState(() {
        _items.add(resized);
        _error = null;
      });
    } on FormatException {
      setState(
        () => _error =
            'Snapshot món gần đây bị thiếu hoặc hỏng. Hãy chọn lại món từ nguồn bạn xác nhận.',
      );
    }
  }

  Future<void> _addCustomFood() async {
    if (_items.length >= NutritionValidation.maxItemsPerMeal) {
      setState(() => _error = 'Mỗi bữa tối đa 5 mục.');
      return;
    }
    final item = await showDialog<MealItemSnapshot>(
      context: context,
      builder: (_) => const CustomFoodDialog(),
    );
    if (item == null || !mounted) return;
    setState(() {
      _items.add(item);
      _error = null;
    });
  }

  Future<void> _edit(int index) async {
    final current = _items[index];
    final grams = await _askGrams(initial: current.grams);
    if (grams == null || !mounted) return;
    try {
      final resized = current.withGrams(grams);
      setState(() => _items[index] = resized);
    } on FormatException {
      setState(
        () => _error =
            'Snapshot món này bị thiếu hoặc hỏng. Hãy bỏ món và chủ động thêm lại từ nguồn bạn xác nhận.',
      );
    }
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

  Future<void> _submit() async {
    if (saving) return;
    if (_items.isEmpty) {
      setState(() => _error = 'Hãy chọn ít nhất một món ăn.');
      return;
    }
    try {
      for (final item in _items) {
        item.withGrams(item.grams);
      }
    } on FormatException {
      setState(
        () => _error =
            'Snapshot món bị thiếu hoặc hỏng. Hãy bỏ món và thêm lại sau khi xác nhận nguồn.',
      );
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
    await saveDraft(draft, widget.onSave);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = MaterialLocalizations.of(context);
    final results = _results;
    final totals = _items.fold(
      const NutritionTotals(),
      (sum, item) => sum + item.nutrition,
    );
    return guardSave(
      Dialog.fullscreen(
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
                onPressed: saving ? null : _submit,
                child: Text(saving ? 'Đang lưu…' : 'Lưu'),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: saveFeedback(),
            ),
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
                    onChanged: (value) =>
                        setState(() => _type = value ?? _type),
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
                  if (widget.recentItems.isNotEmpty) ...[
                    Text('Món gần đây', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in widget.recentItems)
                          ActionChip(
                            key: ValueKey('recent-food-${item.foodId}'),
                            avatar: const Icon(Icons.history_rounded, size: 18),
                            label: Text(item.name),
                            onPressed: () => _addRecent(item),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Tìm món trong danh mục',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Món phối hợp dùng công thức tham khảo. Nhập khối lượng đã ăn theo g; một tô hoặc một ổ không mặc định là 100 g.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('food-search'),
                    controller: _searchController,
                    onChanged: (_) => setState(() {
                      _visibleFoodCount = _foodPageSize;
                    }),
                    decoration: const InputDecoration(
                      hintText: 'Ví dụ: phở bò, com tam, trứng…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('add-custom-food'),
                    onPressed: _addCustomFood,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Nhập món ngoài danh mục'),
                  ),
                  const SizedBox(height: 8),
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Không tìm thấy món phù hợp trong danh mục.'),
                    )
                  else
                    ...results
                        .take(_visibleFoodCount)
                        .map(
                          (food) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(food.name),
                            subtitle: Text(
                              '${food.per100g.kcal.toStringAsFixed(0)} kcal / 100 g'
                              '${food.isEstimated ? ' · Ước tính' : ''} · ${food.sourceLabel}',
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
                  if (results.length > _visibleFoodCount)
                    TextButton.icon(
                      key: const ValueKey('more-catalog-foods'),
                      onPressed: () => setState(() {
                        _visibleFoodCount += _foodPageSize;
                      }),
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Xem thêm món'),
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
                    onPressed: saving ? null : _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Lưu bữa ăn'),
                  ),
                ],
              ),
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
