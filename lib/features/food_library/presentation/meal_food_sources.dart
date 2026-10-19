import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../nutrition/models/food_catalog_search.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../models/favorite_food.dart';
import '../providers/favorite_food_providers.dart';
import '../providers/food_library_providers.dart';
import 'food_library_screen.dart';
import 'food_nutrition_text.dart';

enum _FoodSource {
  search('Tìm món'),
  recent('Gần đây'),
  frequent('Hay dùng'),
  favorites('Yêu thích'),
  custom('Món của tôi'),
  recipes('Công thức');

  const _FoodSource(this.label);
  final String label;
}

class MealFoodSources extends ConsumerStatefulWidget {
  const MealFoodSources({
    required this.onCatalog,
    required this.onRecent,
    required this.onCustom,
    this.initialSearch = '',
    super.key,
  });
  final ValueChanged<FoodCatalogItem> onCatalog;
  final ValueChanged<MealItemSnapshot> onRecent;
  final VoidCallback onCustom;
  final String initialSearch;
  @override
  ConsumerState<MealFoodSources> createState() => _MealFoodSourcesState();
}

class _MealFoodSourcesState extends ConsumerState<MealFoodSources> {
  _FoodSource _source = _FoodSource.search;
  late final TextEditingController _query;
  int _visible = 12;
  int _favoriteLimit = 40;
  bool _initialResolved = false;
  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialSearch);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _favorite(
    String sourceId,
    bool selected, {
    FoodSourceKind kind = FoodSourceKind.catalog,
  }) async {
    final saved = await ref
        .read(favoriteFoodControllerProvider.notifier)
        .setFavorite(sourceId, selected, sourceKind: kind);
    if (!mounted || !saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selected ? 'Đã lưu món vào yêu thích.' : 'Đã bỏ yêu thích.',
        ),
      ),
    );
  }

  bool _matches(String name) =>
      normalizeFoodSearch(name).contains(normalizeFoodSearch(_query.text));
  Widget _retry(String text, VoidCallback retry) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text),
      TextButton(onPressed: retry, child: const Text('Thử tải lại nguồn món')),
    ],
  );
  Widget _catalogTile(FoodCatalogItem food, {bool removable = false}) {
    final busy = ref.watch(favoriteFoodControllerProvider).isLoading;
    return ListTile(
      key: ValueKey('${removable ? 'favorite' : 'catalog'}-food-${food.id}'),
      contentPadding: EdgeInsets.zero,
      title: Text(food.name),
      subtitle: Text(
        !food.hasNutritionData
            ? 'Món thiếu dữ liệu dinh dưỡng; chưa thể thêm vào bữa.'
            : '${food.per100g.kcal.toStringAsFixed(0)} kcal / 100 g${food.isEstimated ? ' · Ước tính' : ''} · ${food.sourceLabel}'
                  '${food.packageLabel == null ? '' : ' · ${food.packageLabel}'}'
                  '${food.hasValidServing ? ' · 1 ${food.servingLabel} = ${foodNumber(food.servingGrams!)} g' : ''}'
                  '${food.servingMetadataInvalid ? ' · Dùng gram: khẩu phần chưa hợp lệ' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey(
              '${removable ? 'remove' : 'save'}-favorite-${food.id}',
            ),
            onPressed: busy ? null : () => _favorite(food.id, !removable),
            tooltip: removable
                ? 'Bỏ yêu thích ${food.name}'
                : 'Lưu yêu thích ${food.name}',
            icon: Icon(
              removable
                  ? Icons.bookmark_remove_outlined
                  : Icons.bookmark_add_outlined,
            ),
          ),
          IconButton.filledTonal(
            onPressed: food.hasNutritionData
                ? () => widget.onCatalog(food)
                : null,
            tooltip: 'Thêm ${food.name}',
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  Widget _search() {
    final state = ref.watch(foodCatalogProvider);
    if (state.isLoading) return const LinearProgressIndicator();
    if (state.hasError) {
      return _retry(
        'Chưa tải được danh mục. Bạn vẫn có thể nhập món ngoài danh mục.',
        () => ref.invalidate(foodCatalogProvider),
      );
    }
    final results = searchFoodCatalog(state.value ?? [], _query.text);
    return Column(
      children: [
        if (results.isEmpty)
          const Text('Không tìm thấy món phù hợp trong danh mục.'),
        for (final food in results.take(_visible)) _catalogTile(food),
        if (results.length > _visible)
          TextButton.icon(
            key: const ValueKey('more-catalog-foods'),
            onPressed: () => setState(() => _visible += 12),
            icon: const Icon(Icons.expand_more),
            label: const Text('Xem thêm món'),
          ),
      ],
    );
  }

  Widget _recent({bool frequent = false}) {
    final state = ref.watch(recentMealsProvider);
    if (state.isLoading) return const LinearProgressIndicator();
    if (state.hasError) {
      return _retry(
        'Chưa tải được món gần đây; không coi lỗi là chưa có dữ liệu.',
        () => ref.invalidate(recentMealsProvider),
      );
    }
    final page = state.value!;
    final ranked = frequentMealItems(page.meals);
    final items =
        (frequent ? ranked.map((r) => r.item) : recentMealItems(page.meals))
            .where((item) => _matches(item.name))
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (frequent)
          Text(
            'Tần suất trong ${page.meals.length} bản ghi gần nhất (tối đa 20), không phải toàn bộ lịch sử.',
          ),
        if (page.fromCache)
          const Text('Dữ liệu trên thiết bị; đang chờ đồng bộ với máy chủ.'),
        if (items.isEmpty)
          Text(
            page.fromCache
                ? 'Chưa xác nhận được món gần đây từ máy chủ.'
                : 'Chưa có món gần đây phù hợp. Ghi một bữa để dùng lại món ở đây.',
          ),
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            key: ValueKey('recent-food-${item.foodId}'),
            title: Text(item.name),
            subtitle: Text(
              item.hasNutritionData
                  ? '${snapshotQuantityLabel(item)} · ${item.nutrition.kcal.toStringAsFixed(0)} kcal · ${item.sourceLabel}${item.isEstimated ? ' · Ước tính' : ''}${item.nutrition.hasCompleteMacros ? '' : ' · Chưa đủ ba chất'}'
                        '${frequent ? ' · ${ranked.singleWhere((r) => identical(r.item, item)).count} bản ghi' : ''}'
                  : 'Snapshot thiếu dữ liệu dinh dưỡng; hãy chọn lại từ nguồn bạn xác nhận.',
            ),
            trailing: IconButton.filledTonal(
              tooltip: 'Dùng lại ${item.name}',
              onPressed: item.hasNutritionData
                  ? () => widget.onRecent(item)
                  : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ),
      ],
    );
  }

  Widget _favorites() {
    final state = ref.watch(favoriteFoodsProvider(_favoriteLimit));
    final catalog =
        state.value?.items.any(
              (item) => item.sourceKind == FoodSourceKind.catalog,
            ) ==
            true
        ? ref.watch(foodCatalogProvider)
        : const AsyncData<List<FoodCatalogItem>>([]);
    if (state.isLoading) return const LinearProgressIndicator();
    if (state.hasError) {
      return _retry(
        'Chưa tải được yêu thích; không coi lỗi là danh sách rỗng.',
        () => ref.invalidate(favoriteFoodsProvider(_favoriteLimit)),
      );
    }
    final page = state.value!;
    final busy = ref.watch(favoriteFoodControllerProvider).isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (page.fromCache)
          const Text('Dữ liệu trên thiết bị; đang chờ đồng bộ với máy chủ.'),
        if (catalog.isLoading) const LinearProgressIndicator(),
        if (catalog.hasError)
          _retry(
            'Chưa tải được nguồn món. Bạn có thể bỏ yêu thích nhưng chưa thể thêm món này vào bữa.',
            () => ref.invalidate(foodCatalogProvider),
          ),
        if (page.items.isEmpty)
          Text(
            page.fromCache
                ? 'Chưa xác nhận được yêu thích từ máy chủ.'
                : 'Chưa có yêu thích. Chọn Lưu yêu thích bên cạnh món trong Tìm món.',
          ),
        for (final favorite in page.items)
          Builder(
            builder: (_) {
              final food = (!catalog.isLoading && !catalog.hasError)
                  ? catalog.value
                        ?.where((food) => food.id == favorite.sourceId)
                        .firstOrNull
                  : null;
              if (favorite.sourceKind != FoodSourceKind.catalog) {
                return PrivateFavoriteTile(
                  favorite: favorite,
                  onChoose: widget.onCatalog,
                  onRemove: () => _favorite(
                    favorite.sourceId,
                    false,
                    kind: favorite.sourceKind,
                  ),
                  query: _query.text,
                );
              }
              if (food != null) {
                return _matches(food.name)
                    ? _catalogTile(food, removable: true)
                    : const SizedBox.shrink();
              }
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  catalog.isLoading || catalog.hasError
                      ? 'Chưa xác định được món: ${favorite.sourceId}'
                      : 'Món không còn khả dụng: ${favorite.sourceId}',
                ),
                subtitle: const Text(
                  'Chưa thể thêm món này vào bữa. Bạn có thể bỏ yêu thích.',
                ),
                trailing: IconButton(
                  key: ValueKey('remove-favorite-${favorite.sourceId}'),
                  onPressed: busy
                      ? null
                      : () => _favorite(favorite.sourceId, false),
                  tooltip: 'Bỏ yêu thích',
                  icon: const Icon(Icons.bookmark_remove_outlined),
                ),
              );
            },
          ),
        if (page.items.length == _favoriteLimit)
          TextButton(
            key: const ValueKey('more-favorites'),
            onPressed: () => setState(() => _favoriteLimit += 40),
            child: const Text('Xem thêm yêu thích'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialResolved && widget.initialSearch.isEmpty) {
      final recent = ref.watch(recentMealsProvider);
      if (recent.hasValue && !recent.isLoading && !recent.hasError) {
        _source = recent.value!.meals.isEmpty
            ? _FoodSource.search
            : _FoodSource.recent;
        _initialResolved = true;
      } else if (recent.hasError) {
        _initialResolved = true;
      }
    }
    final action = ref.watch(favoriteFoodControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final source in _FoodSource.values)
              ChoiceChip(
                key: ValueKey('food-source-${source.name}'),
                label: Text(source.label),
                selected: _source == source,
                onSelected: (_) => setState(() {
                  _initialResolved = true;
                  _source = source;
                  _visible = 12;
                  _query.clear();
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('food-search'),
          controller: _query,
          onChanged: (_) => setState(() => _visible = 12),
          decoration: const InputDecoration(
            labelText: 'Tìm trong nguồn đang chọn',
            hintText: 'Ví dụ: phở bò, com tam…',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('add-custom-food'),
          onPressed: widget.onCustom,
          icon: const Icon(Icons.edit_note),
          label: const Text('Nhập món ngoài danh mục'),
        ),
        const Text(
          'Khối lượng tính theo g. Không tự quy đổi bát, tô hoặc ổ thành 100 g.',
        ),
        if (action.isLoading) ...[
          const LinearProgressIndicator(),
          const Text('Đang chờ máy chủ xác nhận yêu thích; không gửi lặp.'),
        ],
        if (action.error case final FavoriteFoodFailure error)
          Text(
            error.message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        switch (_source) {
          _FoodSource.search => _search(),
          _FoodSource.recent => _recent(),
          _FoodSource.frequent => _recent(frequent: true),
          _FoodSource.favorites => _favorites(),
          _FoodSource.custom => LibraryFoodList(
            key: const ValueKey('source-custom'),
            kind: FoodSourceKind.custom,
            query: _query.text,
            onChoose: widget.onCatalog,
          ),
          _FoodSource.recipes => LibraryFoodList(
            key: const ValueKey('source-recipes'),
            kind: FoodSourceKind.recipe,
            query: _query.text,
            onChoose: widget.onCatalog,
          ),
        },
      ],
    );
  }
}

class PrivateFavoriteTile extends ConsumerWidget {
  const PrivateFavoriteTile({
    required this.favorite,
    required this.onChoose,
    required this.onRemove,
    required this.query,
    super.key,
  });
  final FavoriteFood favorite;
  final ValueChanged<FoodCatalogItem> onChoose;
  final VoidCallback onRemove;
  final String query;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (kind: favorite.sourceKind, id: favorite.sourceId);
    final state = ref.watch(libraryEntryProvider(key));
    final busy = ref.watch(favoriteFoodControllerProvider).isLoading;
    final entry = state.value;
    if (entry != null &&
        !state.isLoading &&
        !state.hasError &&
        searchFoodCatalog([entry.asFood()], query).isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.isLoading)
              const LinearProgressIndicator()
            else if (state.hasError) ...[
              const Text(
                'Chưa tải được nguồn yêu thích. Không coi lỗi là món đã bị xóa.',
              ),
              TextButton(
                onPressed: () => ref.invalidate(libraryEntryProvider(key)),
                child: const Text('Thử tải lại nguồn yêu thích'),
              ),
            ] else if (entry == null)
              Text('Món không còn khả dụng: ${favorite.sourceId}')
            else ...[
              Text(entry.name),
              Text(
                '${nutritionLabel(entry.asFood().per100g)} /100 g · Ước tính',
              ),
              TextButton.icon(
                key: ValueKey('choose-favorite-${favorite.id}'),
                onPressed: () => onChoose(entry.asFood()),
                icon: const Icon(Icons.add),
                label: const Text('Thêm vào bữa'),
              ),
            ],
            TextButton(
              key: ValueKey('remove-favorite-${favorite.id}'),
              onPressed: busy ? null : onRemove,
              child: const Text('Bỏ yêu thích'),
            ),
          ],
        ),
      ),
    );
  }
}
