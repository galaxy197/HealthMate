import '../models/food_catalog_search.dart';
import '../models/food_diet.dart';
import '../models/food_avoidance.dart';
import 'food_diet_filter.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/widgets/help_details.dart';
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
import '../../../core/config/app_feature_flags.dart';
import '../../food_scanner/data/food_camera_service.dart';
import '../../food_scanner/presentation/food_scanner_dialog.dart';
import '../../food_library/presentation/meal_food_sources.dart';

enum MealEntryMode { manual, photo, favorites }

class MealFormDialog extends ConsumerStatefulWidget {
  const MealFormDialog({
    required this.catalog,
    this.recentItems = const [],
    this.meal,
    this.initialConsumedAt,
    this.initialType,
    this.initialItems = const [],
    this.suggestedFood,
    this.suggestedGrams = 100,
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
    this.initialEntryMode = MealEntryMode.manual,
    this.initialDiet = FoodDietPreference.general,
    this.avoidance = const FoodAvoidance.none(),
    super.key,
  });

  final List<FoodCatalogItem> catalog;
  final MealDraft? initialDraft;
  final Future<void> Function(MealDraft)? onDraftChanged;
  final Future<void> Function()? onDiscardDraft;
  final String? draftNotice;
  final MealEntryMode initialEntryMode;
  final FoodDietPreference initialDiet;
  final FoodAvoidance avoidance;
  final List<MealItemSnapshot> recentItems;
  final MealLog? meal;
  final DateTime? initialConsumedAt;
  final MealType? initialType;
  final List<MealItemSnapshot> initialItems;
  final FoodCatalogItem? suggestedFood;
  final double suggestedGrams;
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
    FoodDietPreference,
    FoodAvoidance,
  )?
  sourcesBuilder;

  @override
  ConsumerState<MealFormDialog> createState() => _MealFormDialogState();
}

class _MealFormDialogState extends ConsumerState<MealFormDialog>
    with ConfirmedSave<MealDraft, MealFormDialog> {
  late MealType _type;
  late FoodDietPreference _diet;
  List<FoodCatalogItem> get _eligibleCatalog => widget.catalog
      .where((food) => _diet.allows(food) && widget.avoidance.allows(food))
      .toList();
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
  late MealEntryMode _entryMode;
  bool _photoVisited = false;
  bool _favoritesVisited = false;
  bool _scannerAiUsed = false;
  String? _scanSearch;

  void _switchEntryMode(MealEntryMode mode) {
    if (saving || _discarding) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _entryMode = mode;
      _photoVisited |= mode == MealEntryMode.photo;
      _favoritesVisited |= mode == MealEntryMode.favorites;
    });
  }

  void _acceptScan(FoodScanChoice choice) {
    final food = choice.food;
    if (food != null && _items.length >= NutritionValidation.maxItemsPerMeal) {
      _switchEntryMode(MealEntryMode.manual);
      setState(
        () => _error = 'Mỗi bữa tối đa 5 mục. Bỏ bớt món trước khi thêm.',
      );
      return;
    }
    _changeMeal(() {
      _scannerAiUsed = true;
      if (food != null && food.hasNutritionData) {
        _items.add(MealItemSnapshot.fromCatalog(food, choice.grams));
        _error = null;
      } else {
        _searchController.text = choice.query;
        _scanSearch = choice.query;
      }
    });
    _switchEntryMode(MealEntryMode.manual);
  }

  // Unified search state
  List<FoodSearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  Timer? _searchDebounce;
  int _searchGeneration = 0;

  Widget _dietFilter() => FoodDietFilter(
    value: _diet,
    onChanged: saving || _discarding
        ? null
        : (diet) {
            if (diet == _diet) return;
            setState(() => _diet = diet);
            _onSearchChanged();
          },
  );

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
    source: _scannerAiUsed
        ? MealSource.aiAssisted
        : widget.initialDraft?.source ??
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
    setState(() => _localStatus = 'Đang giữ nháp…');
    try {
      await widget.onDraftChanged!(_draft);
      if (mounted && revision == _localRevision) {
        setState(() => _localStatus = 'Đã giữ nháp trên thiết bị');
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
    _diet = widget.initialDiet;
    _entryMode =
        widget.initialDraft == null &&
            ref.read(appFeatureFlagsProvider).foodScannerEnabled
        ? widget.initialEntryMode
        : MealEntryMode.manual;
    _photoVisited = _entryMode == MealEntryMode.photo;
    _favoritesVisited = _entryMode == MealEntryMode.favorites;
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
    _searchResults = _eligibleCatalog
        .map(
          (food) =>
              FoodSearchResult(food: food, source: FoodResultSource.firestore),
        )
        .toList();
    _searchController = TextEditingController(text: widget.initialSearch);
    _searchController.addListener(_onSearchChanged);
    if ((widget.initialDraft == null ? widget.suggestedFood : null)
        case final food?) {
      if (food.hasNutritionData) {
        if (NutritionValidation.grams(widget.suggestedGrams.toString()) ==
            null) {
          _items.add(MealItemSnapshot.fromCatalog(food, widget.suggestedGrams));
        } else {
          _error = 'Khẩu phần gợi ý chưa hợp lệ. Hãy chọn lại món.';
        }
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
    if (widget.initialSearch.isNotEmpty && widget.sourcesBuilder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _performUnifiedSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchGeneration++;
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
    final generation = ++_searchGeneration;
    if (query.isEmpty) {
      setState(() {
        _searchResults = _eligibleCatalog
            .map(
              (food) => FoodSearchResult(
                food: food,
                source: FoodResultSource.firestore,
              ),
            )
            .toList();
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _searchResults = searchFoodCatalog(_eligibleCatalog, query)
          .map(
            (food) => FoodSearchResult(
              food: food,
              source: FoodResultSource.firestore,
            ),
          )
          .toList();
      _isSearching = true;
      _searchError = null;
    });

    try {
      final searchService = ref.read(unifiedFoodSearchProvider);
      final results = await searchService.search(
        query: query,
        firestoreCatalog: _eligibleCatalog,
        limit: 50,
      );

      if (mounted &&
          generation == _searchGeneration &&
          _searchController.text.trim() == query) {
        setState(() {
          _searchResults = results
              .where(
                (r) => _diet.allows(r.food) && widget.avoidance.allows(r.food),
              )
              .toList();
          _isSearching = false;
          _visibleFoodCount = _foodPageSize;
        });
      }
    } catch (_) {
      if (mounted &&
          generation == _searchGeneration &&
          _searchController.text.trim() == query) {
        setState(() {
          _searchError =
              'Chưa tìm thêm được món. Bạn có thể dùng kết quả trong danh mục hoặc thử lại.';
          _isSearching = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchGeneration++;
    if (!mounted) return;
    final query = _searchController.text.trim();
    setState(() {
      _visibleFoodCount = _foodPageSize;
      _searchResults = searchFoodCatalog(_eligibleCatalog, query)
          .map(
            (food) => FoodSearchResult(
              food: food,
              source: FoodResultSource.firestore,
            ),
          )
          .toList();
      _isSearching = query.isNotEmpty;
      _searchError = null;
    });
    if (query.isEmpty) return;
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _performUnifiedSearch();
    });
  }

  Widget _dataSourceBadge(FoodResultSource source) => Text(switch (source) {
    FoodResultSource.firestore => 'Danh mục',
    FoodResultSource.cache => 'Đã lưu trên máy',
    FoodResultSource.usdaApi => 'USDA',
    FoodResultSource.user => 'Món riêng',
  }, style: Theme.of(context).textTheme.bodySmall);
  Future<void> _openBarcodeScanner() async {
    if (saving || _discarding) return;
    if (_items.length >= NutritionValidation.maxItemsPerMeal) {
      setState(() => _error = 'Mỗi bữa tối đa 5 mục.');
      return;
    }
    try {
      await ref.read(foodCameraServiceProvider).release();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa dừng được camera. Hãy đóng màn hình và thử lại.',
        );
      }
      return;
    }
    if (!mounted) return;
    final result = await ref.read(barcodeMealScannerProvider)(context);

    if (result == null || !mounted) return;

    if (saving ||
        _discarding ||
        _items.length >= NutritionValidation.maxItemsPerMeal) {
      return;
    }
    try {
      final item = result.toSnapshot();
      _changeMeal(() {
        _items.add(item);
        _error = null;
      });
      _switchEntryMode(MealEntryMode.manual);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
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
    if (widget.avoidance.isActive) {
      final flagged = widget.avoidance.flaggedSnapshots(_items, widget.catalog);
      if (flagged.isNotEmpty) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kiểm tra thực phẩm cần tránh'),
            content: Text(
              'Bạn đã khai báo tránh: ${widget.avoidance.label}.\n${flagged.map((i) => i.name).join(', ')} có thể chứa thực phẩm cần tránh hoặc chưa đủ thành phần. Ghi nhật ký không có nghĩa món này an toàn để ăn. Bạn vẫn muốn ghi lại bữa đã ăn?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Quay lại kiểm tra'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Vẫn ghi nhật ký'),
              ),
            ],
          ),
        );
        if (confirm != true || !mounted) return;
      }
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
    final scannerEnabled = ref
        .watch(appFeatureFlagsProvider)
        .foodScannerEnabled;
    return guardSave(
      Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.meal == null ? 'Thêm bữa ăn' : 'Sửa bữa ăn'),
            leading: IconButton(
              onPressed: _discarding ? null : () => Navigator.pop(context),
              tooltip: _entryMode == MealEntryMode.photo ? 'Đóng' : 'Hủy',
              icon: const Icon(Icons.close_rounded),
            ),
            actions: [
              if (_entryMode == MealEntryMode.photo)
                IconButton(
                  tooltip: 'Thông tin quét món',
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const SafeArea(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Chụp toàn bộ phần ăn hoặc chọn ảnh từ thư viện. Mã vạch tra cứu thông tin trên sản phẩm. Ảnh chỉ được gửi đến dịch vụ AI của Google khi bạn đồng ý và bấm Phân tích. Dịch vụ miễn phí có thể dùng ảnh/kết quả để cải thiện sản phẩm và có người đánh giá. Không chọn ảnh có thông tin cá nhân. HealthMate không tải ảnh gốc lên kho lưu trữ; camera/thư viện có thể giữ tệp tạm trên thiết bị. Dinh dưỡng từ ảnh là ước tính; hãy kiểm tra món và khẩu phần trước khi lưu.',
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.onDiscardDraft != null)
                IconButton(
                  key: const ValueKey('discard-local-draft'),
                  onPressed: saving || _discarding ? null : _discardLocal,
                  tooltip: 'Bỏ bản nháp này',
                  icon: const Icon(Icons.delete_outline),
                ),
              if (_entryMode != MealEntryMode.photo)
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
                  if (_entryMode != MealEntryMode.photo) ...[
                    if (widget.draftNotice != null) Text(widget.draftNotice!),
                    if (_localStatus != null)
                      Text(
                        _localStatus!,
                        key: const ValueKey('local-draft-status'),
                        style: theme.textTheme.bodySmall,
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final mode in MealEntryMode.values)
                        if (mode != MealEntryMode.photo || scannerEnabled)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: TextButton(
                                key: ValueKey('meal-entry-${mode.name}'),
                                style: TextButton.styleFrom(
                                  backgroundColor: _entryMode == mode
                                      ? theme.colorScheme.primaryContainer
                                      : null,
                                  foregroundColor: _entryMode == mode
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurfaceVariant,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: saving || _discarding
                                    ? null
                                    : () => _switchEntryMode(mode),
                                child: Text(switch (mode) {
                                  MealEntryMode.manual => 'Nhập tay',
                                  MealEntryMode.photo => 'Ảnh',
                                  MealEntryMode.favorites => 'Yêu thích',
                                }, textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: IndexedStack(
            index: _entryMode.index,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    key: const ValueKey('meal-manual-content'),
                    padding: const EdgeInsets.all(24),
                    children: [
                      DropdownButtonFormField<MealType>(
                        key: const ValueKey('meal-type'),
                        isExpanded: true,
                        initialValue: _type,
                        decoration: const InputDecoration(
                          labelText: 'Loại bữa ăn',
                        ),
                        items: [
                          for (final type in MealType.values)
                            DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
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
                      if (_items.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: 12,
                              children: [
                                Text(
                                  'Món đã chọn (${_items.length}/5)',
                                  style: theme.textTheme.titleMedium,
                                ),
                                for (final entry in _items.indexed)
                                  Column(
                                    key: ValueKey(
                                      'selected-meal-item-${entry.$1}',
                                    ),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        entry.$2.name,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${snapshotQuantityLabel(entry.$2)} · ${entry.$2.nutrition.kcal.toStringAsFixed(0)} kcal${entry.$2.isEstimated ? ' · Ước tính' : ''}',
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _edit(entry.$1),
                                            tooltip: 'Sửa khẩu phần',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => _changeMeal(
                                              () => _items.removeAt(entry.$1),
                                            ),
                                            tooltip: 'Bỏ món',
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                const Divider(),
                                FoodNutritionSummary(value: totals),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            key: const ValueKey('scan-barcode'),
                            onPressed: saving || _discarding
                                ? null
                                : _openBarcodeScanner,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Quét mã vạch'),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey('open-quick-add'),
                            onPressed: () async {
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              if (_items.length >= 5) {
                                setState(
                                  () => _error = 'Mỗi bản ghi tối đa 5 món.',
                                );
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
                            label: const Text('Nhập nhanh kcal'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _dietFilter(),
                      const SizedBox(height: 12),
                      if (widget.avoidance.isActive)
                        Text('Đang tránh: ${widget.avoidance.label}'),
                      const SizedBox(height: 12),
                      if (_scanSearch != null)
                        MealFoodSources(
                          key: ValueKey('scan-search-$_scanSearch'),
                          initialSearch: _scanSearch!,
                          diet: _diet,
                          avoidance: widget.avoidance,
                          onCatalog: _add,
                          onRecent: _addRecent,
                          onCustom: _addCustomFood,
                        )
                      else if (widget.sourcesBuilder != null)
                        widget.sourcesBuilder!(
                          _add,
                          _addRecent,
                          _addCustomFood,
                          _diet,
                          widget.avoidance,
                        )
                      else ...[
                        if (widget.recentItems.isNotEmpty) ...[
                          Text(
                            'Món gần đây',
                            style: theme.textTheme.titleMedium,
                          ),
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
                        TextField(
                          key: const ValueKey('food-search'),
                          controller: _searchController,
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
                        // Loading state
                        if (_isSearching && _searchResults.isEmpty) ...[
                          const LinearProgressIndicator(),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Đang tìm kiếm từ nhiều nguồn...'),
                          ),
                        ]
                        // Error state
                        else if (_searchError != null &&
                            _searchResults.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Text(
                                  _searchError!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
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
                          if (_searchError != null) ...[
                            Text(_searchError!),
                            TextButton(
                              onPressed: _performUnifiedSearch,
                              child: const Text('Thử lại'),
                            ),
                          ],
                          ..._searchResults
                              .take(_visibleFoodCount)
                              .map(
                                (result) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(result.food.name),
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
                      const HelpDetails(
                        title: 'Lưu ý khi ghi bữa',
                        children: [
                          Text(
                            'Mỗi bản ghi tối đa 5 món. Nhập lượng đã ăn theo gram; khẩu phần tô/chén chỉ là tham khảo. Bộ lọc ẩn món cần tránh và món chưa rõ thành phần; vẫn cần kiểm tra nhãn thực tế.',
                          ),
                        ],
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
                    ],
                  ),
                ),
              ),
              if (_photoVisited && scannerEnabled)
                FoodScannerDialog(
                  catalog: widget.catalog,
                  embedded: true,
                  active: _entryMode == MealEntryMode.photo,
                  onSelected: _acceptScan,
                  onBarcode: _openBarcodeScanner,
                )
              else
                const SizedBox.shrink(),
              if (_favoritesVisited)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(
                          'Món yêu thích',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _dietFilter(),
                        const SizedBox(height: 12),
                        MealFoodSources(
                          favoritesOnly: true,
                          diet: _diet,
                          avoidance: widget.avoidance,
                          onCatalog: (food) async {
                            final before = _items.length;
                            await _add(food);
                            if (mounted && _items.length > before) {
                              _switchEntryMode(MealEntryMode.manual);
                            }
                          },
                          onRecent: _addRecent,
                          onCustom: _addCustomFood,
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
