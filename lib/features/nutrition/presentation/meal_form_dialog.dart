import '../models/food_diet.dart';
import '../models/food_avoidance.dart';
import 'food_diet_filter.dart';
import 'meal_form_controller.dart';
import 'meal_search_controller.dart';
import 'meal_entry_sources.dart';
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
import '../../food_library/presentation/meal_food_sources.dart';
import '../../food_scanner/presentation/barcode_scanner_screen.dart';
import '../../../core/config/app_feature_flags.dart';
import '../../food_scanner/data/food_camera_service.dart';
import '../../food_scanner/presentation/food_scanner_dialog.dart';
import '../../auth/providers/auth_providers.dart';

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
  late final MealFormController _form;
  late final MealSearchController _foodSearch;
  String? _ownerUid;
  bool _ownerResolved = false;
  MealType get _type => _form.type;
  set _type(MealType value) => _form.type = value;
  late FoodDietPreference _diet;
  List<FoodCatalogItem> get _eligibleCatalog => widget.catalog
      .where((food) => _diet.allows(food) && widget.avoidance.allows(food))
      .toList();
  DateTime get _consumedAt => _form.consumedAt;
  set _consumedAt(DateTime value) => _form.consumedAt = value;
  List<MealItemSnapshot> get _items => _form.items;
  late final TextEditingController _searchController;
  String? _error;
  set _storedOffset(int? value) => _form.timezoneOffsetOverride = value;
  String? get _localStatus => _form.localStatus;
  bool _discarding = false;
  late MealEntryMode _entryMode;
  bool _photoVisited = false;
  bool _favoritesVisited = false;
  set _scannerAiUsed(bool value) => _form.scannerAiUsed = value;
  String? _scanSearch;

  void _switchEntryMode(MealEntryMode mode) {
    if (saving || _discarding) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (mode != MealEntryMode.manual) _cancelFoodWork();
    setState(() {
      _entryMode = mode;
      _photoVisited |= mode == MealEntryMode.photo;
      _favoritesVisited |= mode == MealEntryMode.favorites;
    });
    if (mode == MealEntryMode.manual &&
        widget.sourcesBuilder == null &&
        _scanSearch == null) {
      _onSearchChanged();
    }
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

  bool _searchVisible = true;
  void _cancelFoodWork() => _foodSearch.cancel();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (_searchVisible && !visible) _cancelFoodWork();
    final resumed = !_searchVisible && visible;
    _searchVisible = visible;
    if (resumed && widget.sourcesBuilder == null && _scanSearch == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _searchVisible) _onSearchChanged();
      });
    }
  }

  @override
  void didUpdateWidget(covariant MealFormDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    _form.onDraftChanged = widget.onDraftChanged;
    _form.minimumSchemaVersion =
        widget.initialDraft?.minimumSchemaVersion ??
        widget.meal?.schemaVersion ??
        2;
    _form.source =
        widget.initialDraft?.source ??
        (widget.aiAssisted || widget.meal?.source == MealSource.aiAssisted
            ? MealSource.aiAssisted
            : MealSource.manual);
    if (oldWidget.avoidance.label != widget.avoidance.label ||
        oldWidget.catalog != widget.catalog) {
      _onSearchChanged();
    }
  }

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

  MealDraft get _draft => _form.draft;

  void _changeMeal(VoidCallback change) {
    if (_discarding) return;
    setState(change);
    _persistLocal();
  }

  Future<void> _persistLocal() => _form.persistLocal();

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
    final initialAt =
        widget.initialDraft?.consumedAt ??
        widget.meal?.consumedAt ??
        widget.initialConsumedAt ??
        DateTime.now();
    final initialSession = ref.read(authSessionProvider);
    _ownerResolved = !initialSession.isLoading && !initialSession.hasError;
    _ownerUid = initialSession.value?.uid;
    _form = MealFormController(
      type:
          widget.initialDraft?.type ??
          widget.meal?.type ??
          widget.initialType ??
          _typeFor(initialAt),
      consumedAt: initialAt,
      items:
          widget.initialDraft?.items ??
          [...?widget.meal?.items, ...widget.initialItems],
      minimumSchemaVersion:
          widget.initialDraft?.minimumSchemaVersion ??
          widget.meal?.schemaVersion ??
          2,
      timezoneOffsetOverride: widget.initialDraft?.timezoneOffsetMinutes,
      source:
          widget.initialDraft?.source ??
          (widget.aiAssisted || widget.meal?.source == MealSource.aiAssisted
              ? MealSource.aiAssisted
              : MealSource.manual),
      onDraftChanged: widget.onDraftChanged,
      onChanged: () {
        if (mounted) setState(() {});
      },
      isCurrent: () =>
          mounted &&
          _ownerResolved &&
          ref.read(authSessionProvider).value?.uid == _ownerUid,
    );
    _searchController = TextEditingController(text: widget.initialSearch);
    _foodSearch = MealSearchController(
      service: () => ref.read(unifiedFoodSearchProvider),
      catalog: () => _eligibleCatalog,
      query: () => _searchController.text,
      currentUid: () => ref.read(authSessionProvider).value?.uid,
      isActive: () =>
          mounted && _searchVisible && _entryMode == MealEntryMode.manual,
      canSearch: () =>
          widget.sourcesBuilder == null &&
          _scanSearch == null &&
          _searchVisible &&
          _entryMode == MealEntryMode.manual,
      allows: (food) => _diet.allows(food) && widget.avoidance.allows(food),
      onChanged: () {
        if (mounted) setState(() {});
      },
      initialResults: _eligibleCatalog
          .map(
            (food) => FoodSearchResult(
              food: food,
              source: FoodResultSource.firestore,
            ),
          )
          .toList(),
    );
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
    _foodSearch.dispose();
    _form.dispose();
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

  Future<void> _performUnifiedSearch() => _foodSearch.search();

  void _onSearchChanged() => _foodSearch.changed();

  Future<void> _selectSearchResult(FoodSearchResult result) async {
    if (_foodSearch.state.pendingDetailId != null || saving || _discarding) {
      return;
    }
    if (!result.requiresDetail) return _add(result.food);
    final uid = ref.read(authSessionProvider).value?.uid;
    final food = await _foodSearch.resolve(result);
    if (food != null &&
        mounted &&
        _entryMode == MealEntryMode.manual &&
        ref.read(authSessionProvider).value?.uid == uid) {
      await _add(food);
    }
  }

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
    final uid = ref.read(authSessionProvider).value?.uid;
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
    if (grams == null ||
        !mounted ||
        ref.read(authSessionProvider).value?.uid != uid) {
      return;
    }
    if (!_diet.allows(food) || !widget.avoidance.allows(food)) return;
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
    final entryError = _form.entryError(DateTime.now());
    if (entryError != null) {
      setState(() => _error = entryError);
      return;
    }
    FocusScope.of(context).unfocus();
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
    final snapshotError = _form.snapshotError();
    if (snapshotError != null) {
      setState(() => _error = snapshotError);
      return;
    }
    await saveDraft(
      _draft,
      widget.onSave == null
          ? null
          : (draft) => _form.submit(draft, widget.onSave!),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (previous, next) {
      if (!_ownerResolved && !next.isLoading && !next.hasError) {
        // Initial stream resolution establishes ownership, not an account switch.
        _ownerResolved = true;
        _ownerUid = next.value?.uid;
        if (widget.onDraftChanged != null) _persistLocal();
        _onSearchChanged();
        return;
      }
      if (previous?.value?.uid == next.value?.uid) return;
      _foodSearch.clear();
    });
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
                        TickerMode(
                          enabled: _entryMode == MealEntryMode.manual,
                          child: MealFoodSources(
                            key: ValueKey('scan-search-$_scanSearch'),
                            initialSearch: _scanSearch!,
                            diet: _diet,
                            avoidance: widget.avoidance,
                            onCatalog: _add,
                            onRecent: _addRecent,
                            onCustom: _addCustomFood,
                          ),
                        )
                      else if (widget.sourcesBuilder != null)
                        TickerMode(
                          enabled: _entryMode == MealEntryMode.manual,
                          child: widget.sourcesBuilder!(
                            _add,
                            _addRecent,
                            _addCustomFood,
                            _diet,
                            widget.avoidance,
                          ),
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
                        ...MealCatalogSource(
                          state: _foodSearch.state,
                          searchController: _searchController,
                          onRetry: _performUnifiedSearch,
                          onCustom: _addCustomFood,
                          onSelect: _selectSearchResult,
                          onMore: _foodSearch.showMore,
                        ).buildChildren(context),
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
                MealFavoritesSource(
                  filter: _dietFilter(),
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
