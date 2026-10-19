import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/meal_draft_store.dart';
import '../../../core/widgets/confirmed_save.dart';

/// Returning null means cancel; empty string explicitly starts a new draft.
Future<String?> chooseMealDraft(
  BuildContext context,
  List<SavedMealDraft> drafts,
) => showDialog<String>(
  context: context,
  builder: (dialogContext) => AccountBoundDialog(
    child: SimpleDialog(
      title: const Text('Bản nháp chưa xác nhận'),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'Nháp mã hóa theo tài khoản, hết hạn sau 7 ngày. Nếu lần gửi trước bị gián đoạn, thử lại cùng nháp để kiểm tra và tránh trùng; đừng tạo bản mới. Không tự gửi khi đăng nhập.',
          ),
        ),
        for (final saved in drafts)
          SimpleDialogOption(
            key: ValueKey('restore-draft-${saved.operationId}'),
            onPressed: () => Navigator.pop(dialogContext, saved.operationId),
            child: Text(
              '${saved.draft.dateKey} · ${saved.draft.type.label}\n'
              '${saved.draft.items.length} món · ${DateFormat.Hm('vi').format(saved.updatedAt.toLocal())}'
              '${saved.mealId != null ? ' · Sửa bữa' : ''}',
            ),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext, ''),
          child: const Text('Tạo bản mới'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Để sau'),
        ),
      ],
    ),
  ),
);
