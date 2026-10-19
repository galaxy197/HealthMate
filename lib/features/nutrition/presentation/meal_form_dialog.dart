import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/confirmed_save.dart';

import '../models/nutrition_models.dart';
import '../models/nutrition_validation.dart';
import '../data/unified_food_search_service.dart';
import '../providers/nutrition_providers.dart';
import 'custom_food_dialog.dart';
import 'quick_add_dialog.dart';
import '../../food_library/presentation/food_portion_dialog.dart';
import '../../food_library/models/food_library_models.dart';
import '../../food_library/presentation/food_nutrition_text.dart';
import '../../food_scanner/presentation/barcode_scanner_screen.dart';
import '../../food_scanner/data/barcode_product_service.dart';

class MealFormDialog extends ConsumerStatefulWidget {
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
    this.sourcesBuilder,
    this.saveErrorMessage,
    this.newLibraryId,
    this.onSavePersonalFood,
    this.libraryErrorMessage,
    this.templatesBuilder,
    this.initialDraft,
    this.onDraftChanged,
    this.onDiscardDraft,
    this.draftNotice,
    super.key,
  });

  final List<FoodCatalogItem> catalog;
  final MealDraft? initialDraft;
  final Future<void> Function(MealDraft)? onDraftChanged;
  final Future<void> Function()? onDiscardDraft;
  final String? draftNotice;
  final List<MealItemSnapshot> recentItems;
  final MealLog? meal;
  final DateTime? initialConsumedAt;
  final MealType? initialType;
  final List<MealItemSnapshot> initialItems;
  final FoodCatalogItem? suggestedFood;
  final String initialSearch;
  final bool aiAssisted;
  final Future<bool> Function(MealDraft)? onSave;
  final String? Function()? saveErrorMessage;
  final String Function()? newLibraryId;
  final Future<bool> Function(PersonalFood)? onSavePersonalFood;
  final String? Function()? libraryErrorMessage;
  final Widget Function(
    List<MealItemSnapshot>,
    ValueChanged<List<MealItemSnapshot>>,
  )?
  templatesBuilder;
  final Widget Function(
    ValueChanged<FoodCatalogItem>,
    ValueChanged<MealItemSnapshot>,
    VoidCallback,
  )?
  sourcesBuilder;

  @override
  ConsumerState<MealFormDialog> createState() => _MealFormDialogState();
}

class _MealFormDialogState extends ConsumerState<MealFormDialog>
    with ConfirmedSave<MealDraft, MealFormDialog> {
  late MealType _type;
  late DateTime _consumedAt;
  late List<MealItemSnapshot> _items;
  late final TextEditingController _searchController;
  String? _error;
  static const _foodPageSize = 12;
  int _visibleFoodCount = _foodPageSize;
  int? _storedOffset;
  String? _localStatus;
  int _localRevision = 0;
  bool _discarding = false;

  // Unified search state
  List<FoodSearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  Future<void> _discardLocal() async {
    if (saving || _discarding || widget.onDiscardDraft == null) return;
    setState(() => _discarding = true);
    try {
      await widget.onDiscardDraft!();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _discarding = false;
          _error = 'Chưa xóa được nháp; hãy thử lại.';
        });
      }
    }
  }

  MealDraft get _draft => MealDraft(
    minimumSchemaVersion:
        widget.initialDraft?.minimumSchemaVersion ??
        widget.meal?.schemaVersion ??
        2,
    type: _type,
    consumedAt: _consumedAt,
    items: List.unmodifiable(_items),
    timezoneOffsetOverride: _storedOffset,
    source:
        widget.initialDraft?.source ??
        (widget.aiAssisted || widget.meal?.source == MealSource.aiAssisted
            ? MealSource.aiAssisted
            : MealSource.manual),
  );

  void _changeMeal(VoidCallback change) {
    if (_discarding) return;
    setState(change);
    _persistLocal();
  }

  Future<void> _persistLocal() async {
    if (widget.onDraftChanged == null) return;
    final revision = ++_localRevision;
    setState(
      () =>
          _localStatus = 'Nháp chờ xác nhận nhật ký · Đang giữ trên thiết bị…',
    );
    try {
      await widget.onDraftChanged!(_draft);
      if (mounted && revision == _localRevision) {
        setState(
          () => _localStatus =
              'Nháp chờ xác nhận nhật ký · Đã giữ mã hóa trên thiết bị (7 ngày).',
        );
      }
    } catch (_) {
      if (mounted && revision == _localRevision) {
        setState(
          () => _localStatus =
              'Chưa giữ được nháp trên thiết bị. Đừng đóng ứng dụng; thử thay đổi lại hoặc lưu khi có mạng.',
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _consumedAt =
        widget.meal?.consumedAt ?? widget.initialConsumedAt ?? DateTime.now();
    _type = widget.meal?.type ?? widget.initialType ?? _typeFor(_consumedAt);
    _items = [...?widget.meal?.items, ...widget.initialItems];
    if (widget.initialDraft case final restored?) {
      _consumedAt = restored.consumedAt;
      _type = restored.type;
      _items = [...restored.items];
      _storedOffset = restored.timezoneOffsetMinutes;
    }
    _searchController = TextEditingController(text: widget.initialSearch);
    _searchController.addListener(_onSearchChanged);
    if ((widget.initialDraft == null ? widget.suggestedFood : null)
        case final food?) {
      if (food.hasNutritionData) {
        _items.add(MealItemSnapshot.fromCatalog(food, 100));
      } else {
        _error =
            'Món gợi ý thiếu dữ liệu dinh dưỡng. Hãy chọn lại món có đủ thông tin.';
      }
    }
    if (widget.onDraftChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _persistLocal();
      });
    }
    // Trigger initial search if there's initial search text
    if (widget.initialSearch.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _performUnifiedSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  static MealType _typeFor(DateTime time) => switch (time.hour) {
    < 10 => MealType.breakfast,
    < 14 => MealType.lunch,
    < 18 => MealType.snack,
    _ => MealType.dinner,
  };

  Future<void> _performUnifiedSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final searchService = ref.read(unifiedFoodSearchProvider);
      final results = await searchService.search(
        query: query,
        firestoreCatalog: widget.catalog,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _visibleFoodCount = _foodPageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _searchController.text == _searchController.text) {
        _performUnifiedSearch();
      }
    });
  }

  Widget _dataSourceBadge(FoodResultSource source) {
    final (icon, color, label) = switch (source) {
      FoodResultSource.firestore => (Icons.store, Colors.blue, 'Local'),
      FoodResultSource.cache => (Icons.save_alt, Colors.green, 'Cache'),
      FoodResultSource.usdaApi => (Icons.cloud, Colors.orange, 'USDA'),
      FoodResultSource.user => (Icons.person, Colors.purple, 'Của bạn'),
    };

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3), width: 1),
    );
  }

  Future<void> _openBarcodeScanner() async {
    final result = await Navigator.push<BarcodeProduct>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(),
      ),
    );

    if (result == null || !mounted) return;

    // Convert BarcodeProduct to MealItemSnapshot
    if (result.nutrition != null) {
      _changeMeal(() {
        _items.add(
          MealItemSnapshot(
            foodId: 'barcode_${result.barcode}',
            name: result.name,
            brand: result.brand,
            grams: result.servingSizeG ?? 100,
            kcal: result.nutrition!.kcal,
            proteinG: result.nutrition!.proteinG,
            carbsG: result.nutrition!.carbsG,
            fatG: result.nutrition!.fatG,
            source: FoodDataSource.user,
          ),
        );
        _error = null;
      });
    }
  }

  Future<double?> _askGrams({double initial = 100, FoodCatalogItem? food}) =>
      askFoodGrams(context, initial: initial, food: food);

  Future<void> _add(FoodCatalogItem food) async {
    if (!food.hasNutritionData) {
      setState(
        () => _error =
            'Món thiếu dữ liệu dinh dưỡng; hãy chọn món khác hoặc nhập đầy đủ bằng tay.',
      );
      return;
    }
    if (_items.length >= NutritionValidation.maxItemsPerMeal) {
      setState(() => _error = 'Mỗi bữa tối đa 5 mục.');
      return;
    }
    final grams = await _askGrams(
      initial: food.defaultServingGrams,
      food: food,
    );
    if (grams == null || !mounted) return;
    _changeMeal(() {
      _items.add(MealItemSnapshot.fromCatalog(food, grams));
      _error = null;
    });
  }

  Future<void> _addRecent(MealItemSnapshot item) async {
    if (_items.length >= NutritionValidation.maxItemsPerMeal) {
      setState(() => _error = 'Mỗi bữa tối đa 5 mục.');
      return;
    }
    try {
      final resized = item.withQuantity(item.quantity);
      final index = _items.length;
      _changeMeal(() {
        _items.add(resized);
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm ${item.name}, ${snapshotQuantityLabel(item)} vào bản nháp. Kiểm tra rồi Lưu.',
          ),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () {
              if (mounted &&
                  index < _items.length &&
                  identical(_items[index], resized)) {
                _changeMeal(() => _items.removeAt(index));
              }
            },
          ),
        ),
      );
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
      builder: (_) => CustomFoodDialog(
        newLibraryId: widget.newLibraryId,
        onSaveToLibrary: widget.onSavePersonalFood,
        libraryErrorMessage: widget.libraryErrorMessage,
      ),
    );
    if (item == null || !mounted) return;
    _changeMeal(() {
      _items.add(item);
      _error = null;
    });
    if (item.foodId.startsWith('custom:')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Món đã lưu vào Món của tôi. Bữa ăn vẫn là bản nháp; hãy kiểm tra rồi bấm Lưu.',
          ),
        ),
      );
    }
  }

  Future<void> _edit(int index) async {
    final current = _items[index];
    final grams = await askSnapshotQuantity(context, current);
    if (grams == null || !mounted) return;
    try {
      final resized = current.withQuantity(grams);
      _changeMeal(() => _items[index] = resized);
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
    _changeMeal(() {
      _storedOffset = null;
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
    _changeMeal(() {
      _storedOffset = null;
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
    if (saving || _discarding) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (_consumedAt.isAfter(DateTime.now())) {
      setState(() => _error = 'Thời điểm dùng bữa không thể ở tương lai.');
      return;
    }
    if (_items.length > NutritionValidation.maxItemsPerMeal) {
      setState(
        () => _error =
            'Mỗi bản ghi tối đa 5 món. Bạn có thể thêm bản ghi khác cùng bữa.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    if (_items.isEmpty) {
      setState(() => _error = 'Hãy chọn ít nhất một món ăn.');
      return;
    }
    try {
      for (final item in _items) {
        item.withQuantity(item.quantity);
      }
    } on FormatException {
      setState(
        () => _error =
            'Snapshot món bị thiếu hoặc hỏng. Hãy bỏ món và thêm lại sau khi xác nhận nguồn.',
      );
      return;
    }
    final draft = _draft;
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
    final totals = sumNutritionTotals(_items.map((i) => i.nutrition));
    return guardSave(
      Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.meal == null ? 'Thêm bữa ăn' : 'Sửa bữa ăn'),
            leading: IconButton(
              onPressed: _discarding ? null : () => Navigator.pop(context),
              tooltip: 'Hủy',
              icon: const Icon(Icons.close_rounded),
            ),
            actions: [
              if (widget.onDiscardDraft != null)
                IconButton(
                  key: const ValueKey('discard-local-draft'),
                  onPressed: saving || _discarding ? null : _discardLocal,
                  tooltip: 'Bỏ bản nháp này',
                  icon: const Icon(Icons.delete_outline),
                ),
              TextButton(
                key: const ValueKey('save-meal'),
                onPressed: saving || _discarding ? null : _submit,
                child: Text(saving ? 'Đang lưu…' : 'Lưu'),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.draftNotice != null) Text(widget.draftNotice!),
                  if (_localStatus != null)
                    Text(
                      _localStatus!,
                      key: const ValueKey('local-draft-status'),
                    ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  if (saveError != null &&
                      widget.saveErrorMessage?.call() != null)
                    Text(widget.saveErrorMessage!.call()!),
                  saveFeedback(),
                ],
              ),
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
                    isExpanded: true,
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Loại bữa ăn'),
                    items: [
                      for (final type in MealType.values)
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: (value) =>
                        _changeMeal(() => _type = value ?? _type),
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
                    '${_items.length}/5 món đã chọn. Có thể thêm bản ghi khác cùng bữa khi đủ 5 món.',
                  ),
                  if (widget.sourcesBuilder != null)
                    widget.sourcesBuilder!(_add, _addRecent, _addCustomFood)
                  else ...[
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
                              avatar: const Icon(
                                Icons.history_rounded,
                                size: 18,
                              ),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const ValueKey('food-search'),
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Ví dụ: phở bò, com tam, trứng…',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _openBarcodeScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: 'Quét mã vạch',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const ValueKey('add-custom-food'),
                      onPressed: _addCustomFood,
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Nhập món ngoài danh mục'),
                    ),
                    const SizedBox(height: 8),
                    // Loading state
                    if (_isSearching) ...[
                      const LinearProgressIndicator(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Đang tìm kiếm từ nhiều nguồn...'),
                      ),
                    ]
                    // Error state
                    else if (_searchError != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text(
                              'Lỗi tìm kiếm: $_searchError',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _performUnifiedSearch,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                    ]
                    // Empty query state
                    else if (_searchController.text.trim().isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(Icons.search, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Nhập tên món để tìm kiếm từ nhiều nguồn',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ]
                    // No results
                    else if (_searchResults.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Không tìm thấy món phù hợp trong tất cả nguồn dữ liệu.',
                        ),
                      ),
                    ]
                    // Results with source badges
                    else ...[
                      ..._searchResults
                          .take(_visibleFoodCount)
                          .map(
                            (result) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                children: [
                                  Expanded(child: Text(result.food.name)),
                                  _dataSourceBadge(result.source),
                                ],
                              ),
                              subtitle: Text(
                                result.food.hasNutritionData
                                    ? '${result.food.nutritionPer100g.kcal.toStringAsFixed(0)} kcal / 100 g'
                                          '${result.food.isEstimated ? ' · Ước tính' : ''} · ${result.food.sourceLabel}'
                                    : 'Món thiếu dữ liệu dinh dưỡng; chưa thể thêm vào bữa.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton.filledTonal(
                                onPressed: result.food.hasNutritionData
                                    ? () => _add(result.food)
                                    : null,
                                tooltip: 'Thêm ${result.food.name}',
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ),
                          ),
                      if (_searchResults.length > _visibleFoodCount)
                        TextButton.icon(
                          key: const ValueKey('more-catalog-foods'),
                          onPressed: () => setState(() {
                            _visibleFoodCount += _foodPageSize;
                          }),
                          icon: const Icon(Icons.expand_more_rounded),
                          label: const Text('Xem thêm món'),
                        ),
                    ],
                  ],
                  const Divider(height: 32),
                  OutlinedButton.icon(
                    key: const ValueKey('open-quick-add'),
                    onPressed: () async {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      if (_items.length >= 5) {
                        setState(() => _error = 'Mỗi bản ghi tối đa 5 món.');
                        return;
                      }
                      final item = await showDialog<MealItemSnapshot>(
                        context: context,
                        builder: (_) => const QuickAddDialog(),
                      );
                      if (item != null && mounted) {
                        _changeMeal(() => _items.add(item));
                      }
                    },
                    icon: const Icon(Icons.bolt_outlined),
                    label: const Text('Ghi nhanh kcal / nhập nhãn khác'),
                  ),
                  if (widget.templatesBuilder != null)
                    widget.templatesBuilder!(_items, (items) {
                      if (_items.length + items.length >
                          NutritionValidation.maxItemsPerMeal) {
                        setState(
                          () => _error =
                              'Tổng tối đa 5 món. Bỏ bớt món đã chọn hoặc dùng bữa mẫu trong bản ghi mới.',
                        );
                        return;
                      }
                      _changeMeal(() {
                        _items.addAll(items);
                        _error = null;
                      });
                    }),
                  Text('Món đã chọn', style: theme.textTheme.titleMedium),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Chưa có món nào.'),
                    )
                  else
                    ..._items.indexed.map(
                      (entry) => ListTile(
                        key: ValueKey('selected-meal-item-${entry.$1}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.$2.name),
                        subtitle: Text(
                          '${snapshotQuantityLabel(entry.$2)} · ${entry.$2.nutrition.kcal.toStringAsFixed(0)} kcal'
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
                                  _changeMeal(() => _items.removeAt(entry.$1)),
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
                        'P ${macroAmount(totals.proteinG, totals.proteinKnown)}  ·  '
                        'C ${macroAmount(totals.carbsG, totals.carbsKnown)}  ·  '
                        'F ${macroAmount(totals.fatG, totals.fatKnown)}',
                        style: theme.textTheme.titleMedium,
                      ),
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
