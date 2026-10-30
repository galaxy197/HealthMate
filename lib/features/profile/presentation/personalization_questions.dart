import 'package:flutter/material.dart';
import '../models/personalization_answers.dart';

class PersonalizationQuestions extends StatelessWidget {
  const PersonalizationQuestions({
    super.key,
    required this.numbers,
    required this.answers,
    required this.onChanged,
  });
  final List<int> numbers;
  final PersonalizationAnswers answers;
  final ValueChanged<PersonalizationAnswers> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final q in personalizationQuestions.where(
        (q) => numbers.contains(q.number),
      )) ...[
        if (!(answers['exerciseDays'] == 0 && [11, 12].contains(q.number))) ...[
          Text(
            '${q.number}/20 · ${q.title}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (q.id == 'avoidFoods')
            TextFormField(
              key: const ValueKey('survey-avoidFoods'),
              initialValue: answers[q.id] as String? ?? '',
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: sữa; trứng; đậu phộng; tôm',
              ),
              onChanged: (v) => onChanged(
                answers.withAnswer(q.id, v.trim().isEmpty ? null : v.trim()),
              ),
            )
          else
            DropdownButtonFormField<Object>(
              key: ValueKey('survey-${q.id}'),
              initialValue: answers[q.id] ?? 'unanswered',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Câu trả lời'),
              items: [
                const DropdownMenuItem(
                  value: 'unanswered',
                  child: Text('Để sau / chưa trả lời'),
                ),
                for (final o
                    in q.id == 'sleepHours'
                        ? [
                            for (var h = 0; h <= 48; h++)
                              SurveyOption(h / 2, '${h / 2} giờ'),
                          ]
                        : q.options)
                  DropdownMenuItem(
                    value: o.value,
                    child: Text(
                      o.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                var next = answers.withAnswer(
                  q.id,
                  v == 'unanswered' ? null : v,
                );
                if (q.id == 'exerciseDays' && v == 0) {
                  next = next
                      .withAnswer('exerciseMinutes', null)
                      .withAnswer('exerciseType', null);
                }
                onChanged(next);
              },
            ),
          if (q.id == 'guidance')
            const Text(
              'Đề xuất tự động dành cho người 18–65 tuổi, không mang thai/cho con bú, không có chế độ ăn điều trị, rối loạn ăn uống hoặc nhu cầu thể thao chuyên nghiệp. Chọn cần hướng dẫn riêng hoặc không trả lời sẽ giữ lựa chọn nhập mục tiêu thủ công.',
            ),
          if (q.id == 'activity')
            const Text(
              'Tính cả sinh hoạt và tập luyện thường lệ. Các câu tập luyện sau giúp mô tả thói quen; app không cộng thêm calo lần nữa.',
            ),
          if (q.id == 'avoidFoods')
            const Text(
              'Ngăn cách từng thực phẩm bằng dấu ; hoặc dấu phẩy. App ẩn món có từ khóa trùng và món chưa đủ thành phần khi tìm/gợi ý. Không kiểm tra được nhiễm chéo; luôn kiểm tra nhãn và nguyên liệu thực tế.',
            ),
          const SizedBox(height: 20),
        ],
      ],
    ],
  );
}
