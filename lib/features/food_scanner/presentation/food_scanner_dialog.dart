import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../nutrition/models/nutrition_models.dart';
import '../data/firebase_food_scanner_service.dart';
import '../data/food_scanner_service.dart';
import '../models/ai_food_suggestion.dart';
import '../providers/food_scanner_providers.dart';

class FoodScanChoice {
  const FoodScanChoice({required this.query, this.food});

  final String query;
  final FoodCatalogItem? food;
}

class FoodScannerDialog extends ConsumerStatefulWidget {
  const FoodScannerDialog({required this.catalog, super.key});

  final List<FoodCatalogItem> catalog;

  @override
  ConsumerState<FoodScannerDialog> createState() => _FoodScannerDialogState();
}

class _FoodScannerDialogState extends ConsumerState<FoodScannerDialog> {
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  Uint8List? _bytes;
  String? _mimeType;
  AiFoodSuggestion? _suggestion;
  FoodCatalogItem? _selected;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (kIsWeb) {
      setState(() {
        _error =
            'Quét ảnh hiện được bảo vệ và hỗ trợ trên ứng dụng Android. Bạn vẫn có thể nhập món thủ công trên web.';
      });
      return;
    }
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
      maxHeight: 1600,
      requestFullMetadata: false,
    );
    if (image == null || !mounted) return;
    final bytes = await image.readAsBytes();
    final mime = lookupMimeType(
      image.name,
      headerBytes: bytes.take(16).toList(),
    );
    if (bytes.length > FoodScannerConfig.maxImageBytes) {
      setState(() => _error = 'Ảnh lớn hơn 8 MB. Hãy chọn ảnh khác.');
      return;
    }
    setState(() {
      _bytes = bytes;
      _mimeType = mime ?? 'image/jpeg';
      _suggestion = null;
      _selected = null;
      _error = null;
      _nameController.clear();
    });
  }

  Future<void> _analyze() async {
    final bytes = _bytes;
    final mime = _mimeType;
    if (bytes == null || mime == null || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(foodScannerServiceProvider)
          .analyze(bytes: bytes, mimeType: mime);
      if (!mounted) return;
      _nameController.text = result.dishName;
      setState(() {
        _suggestion = result;
        _selected = _matches(result).firstOrNull;
      });
    } on FoodScannerFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<FoodCatalogItem> _matches(AiFoodSuggestion suggestion) {
    final terms = [
      _nameController.text,
      suggestion.dishName,
      ...suggestion.searchTerms,
    ].map(_normalize).where((value) => value.isNotEmpty).toList();
    return widget.catalog
        .where((food) {
          final names = [food.name, ...food.alternateNames].map(_normalize);
          return names.any(
            (name) =>
                terms.any((term) => name.contains(term) || term.contains(name)),
          );
        })
        .take(6)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = _suggestion;
    final matches = suggestion == null
        ? const <FoodCatalogItem>[]
        : _matches(suggestion);
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nhận diện món bằng Gemini'),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Đóng',
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Gemini chỉ gợi ý tên và thành phần. Bạn xác nhận món và khẩu phần; dinh dưỡng được tính từ danh mục.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                if (_bytes case final bytes?)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(bytes, height: 260, fit: BoxFit.cover),
                  )
                else
                  Container(
                    height: 220,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_search_rounded, size: 56),
                        SizedBox(height: 8),
                        Text('Ảnh không được lưu sau khi phân tích'),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Chụp ảnh'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Chọn ảnh'),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('analyze-food-image'),
                      onPressed: _bytes == null || _loading ? null : _analyze,
                      icon: _loading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(_loading ? 'Đang phân tích…' : 'Phân tích'),
                    ),
                  ],
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (suggestion != null) ...[
                  const Divider(height: 40),
                  TextField(
                    controller: _nameController,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Tên món — hãy sửa nếu Gemini nhận diện sai',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(suggestion.description),
                  if (suggestion.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Có thể gồm: ${suggestion.ingredients.join(', ')}'),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Món phù hợp trong danh mục',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (matches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Chưa có món khớp. Hãy tiếp tục tìm và nhập thủ công.',
                      ),
                    )
                  else
                    RadioGroup<FoodCatalogItem>(
                      groupValue: _selected,
                      onChanged: (value) => setState(() => _selected = value),
                      child: Column(
                        children: [
                          for (final food in matches)
                            RadioListTile<FoodCatalogItem>(
                              value: food,
                              title: Text(food.name),
                              subtitle: Text(
                                '${food.per100g.kcal.toStringAsFixed(0)} kcal / 100 g',
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(
                      context,
                      FoodScanChoice(
                        query: _nameController.text.trim(),
                        food: _selected,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      _selected == null
                          ? 'Tiếp tục nhập thủ công'
                          : 'Xác nhận món đã chọn',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _normalize(String value) {
  const accented =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const plain =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  var output = value.toLowerCase().trim();
  for (var index = 0; index < accented.length; index++) {
    output = output.replaceAll(accented[index], plain[index]);
  }
  return output
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
}
