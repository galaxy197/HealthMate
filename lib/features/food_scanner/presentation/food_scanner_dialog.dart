import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../nutrition/models/nutrition_models.dart';
import '../../../core/config/ai_access_policy.dart';
import '../../../core/config/app_feature_flags.dart';
import '../../auth/providers/auth_providers.dart';
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
  final _nameController = TextEditingController();
  Uint8List? _bytes;
  String? _mimeType;
  AiFoodSuggestion? _suggestion;
  FoodCatalogItem? _selected;
  bool _loading = false;
  bool _picking = false;
  bool _acceptedProcessing = false;
  int _operation = 0;
  Completer<void>? _stopped;
  String? _error;

  @override
  void dispose() {
    if (_stopped case final stopped? when !stopped.isCompleted) {
      stopped.complete();
    }
    _operation++;
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (!ref.read(appFeatureFlagsProvider).foodScannerEnabled) return;
    if (_picking || _loading) return;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) {
      setState(() => _error = 'Hãy đăng nhập trước khi chọn ảnh.');
      return;
    }
    final operation = ++_operation;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final image = await ref.read(foodImagePickerProvider).pick(source);
      if (image == null || !_current(operation, uid)) return;
      setState(() {
        _bytes = image.bytes;
        _mimeType = image.mimeType;
        _suggestion = null;
        _selected = null;
        _acceptedProcessing = false;
        _nameController.clear();
      });
    } catch (error) {
      if (_current(operation, uid)) {
        setState(
          () => _error = error is FoodScannerFailure
              ? error.message
              : 'Chưa thể chọn ảnh. Bạn vẫn có thể nhập món thủ công.',
        );
      }
    } finally {
      if (_current(operation, uid)) setState(() => _picking = false);
    }
  }

  bool _current(int operation, String? uid) =>
      mounted &&
      operation == _operation &&
      uid != null &&
      ref.read(authSessionProvider).value?.uid == uid;

  Future<void> _analyze() async {
    if (!ref.read(appFeatureFlagsProvider).foodScannerEnabled) return;
    final bytes = _bytes;
    final mime = _mimeType;
    if (bytes == null ||
        mime == null ||
        _loading ||
        _picking ||
        !_acceptedProcessing) {
      return;
    }
    final access = ref.read(aiAccessProvider);
    if (!access.allowed) {
      setState(() => _error = access.message);
      return;
    }
    final uid = ref.read(authSessionProvider).value?.uid;
    final operation = ++_operation;
    final stopped = _stopped = Completer<void>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.any<AiFoodSuggestion>([
        ref
            .read(foodScannerServiceProvider)
            .analyze(bytes: bytes, mimeType: mime),
        stopped.future.then<AiFoodSuggestion>(
          (_) => throw const FoodScannerFailure('Đã đóng lượt quét.'),
        ),
      ]).timeout(const Duration(seconds: 45));
      if (!_current(operation, uid)) return;
      _nameController.text = result.dishName;
      setState(() {
        _suggestion = result;
        _selected = _matches(result).firstOrNull;
      });
    } on FoodScannerFailure catch (error) {
      if (_current(operation, uid)) setState(() => _error = error.message);
    } on TimeoutException {
      if (_current(operation, uid)) {
        setState(
          () => _error =
              'Phân tích quá thời gian chờ. Hãy thử lại hoặc nhập thủ công.',
        );
      }
    } catch (_) {
      if (_current(operation, uid)) {
        setState(
          () => _error =
              'Chưa thể phân tích ảnh. Hãy kiểm tra mạng hoặc nhập thủ công.',
        );
      }
    } finally {
      if (_current(operation, uid)) {
        _stopped = null;
        setState(() => _loading = false);
      }
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
    if (!ref.watch(appFeatureFlagsProvider).foodScannerEnabled) {
      return AlertDialog(
        title: const Text('Quét món đang tạm tắt'),
        content: const Text('Bạn vẫn có thể thêm bữa ăn thủ công từ Nhật ký.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      );
    }
    ref.listen(authSessionProvider.select((session) => session.value?.uid), (
      previous,
      next,
    ) {
      if (previous == next) return;
      _operation++;
      if (_stopped case final stopped? when !stopped.isCompleted) {
        stopped.complete();
      }
      final route = ModalRoute.of(context);
      final navigator = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Auth redirects may already have removed this dialog by this frame.
        if (mounted && route?.isCurrent == true && navigator.canPop()) {
          navigator.pop();
        }
      });
    });
    final access = ref.watch(aiAccessProvider);
    final busy = _loading || _picking;
    final suggestion = _suggestion;
    final matches = suggestion == null
        ? const <FoodCatalogItem>[]
        : _matches(suggestion);
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nhận diện món từ ảnh'),
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
              key: const ValueKey('scanner-content'),
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Công cụ chỉ gợi ý tên và thành phần. Bạn xác nhận món và khẩu phần; dinh dưỡng được tính từ danh mục.',
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
                        Text('Chỉ chọn ảnh món ăn'),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Chụp ảnh'),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Chọn ảnh'),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('analyze-food-image'),
                      onPressed:
                          _bytes == null ||
                              busy ||
                              !_acceptedProcessing ||
                              !access.allowed
                          ? null
                          : _analyze,
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
                const SizedBox(height: 12),
                const Text(
                  'Khi bạn bấm Phân tích, ảnh được gửi đến dịch vụ AI của Google. Dịch vụ miễn phí có thể dùng ảnh và kết quả để cải thiện sản phẩm, có thể có người đánh giá nội dung. Không chọn ảnh có mặt người, giấy tờ hoặc thông tin riêng tư. HealthMate không tải ảnh gốc lên kho lưu trữ; camera/thư viện có thể giữ tệp tạm trên thiết bị.',
                ),
                CheckboxListTile(
                  key: const ValueKey('scanner-processing-consent'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Ảnh chỉ có món ăn, không có thông tin cá nhân; tôi đồng ý gửi ảnh để phân tích.',
                  ),
                  value: _acceptedProcessing,
                  onChanged: busy || _bytes == null
                      ? null
                      : (value) => setState(
                          () => _acceptedProcessing = value ?? false,
                        ),
                ),
                if (!access.allowed) Text(access.message),
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
                      labelText: 'Tên món — hãy sửa nếu nhận diện chưa đúng',
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
                                '${food.nutritionPer100g.kcal.toStringAsFixed(0)} kcal / 100 g',
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
