import '../../nutrition_targets/models/energy_estimate.dart';
import '../../nutrition_targets/models/personal_nutrition_plan.dart';
import 'health_goal.dart';

class SurveyOption {
  const SurveyOption(this.value, this.label);
  final Object value;
  final String label;
}

class SurveyQuestion {
  const SurveyQuestion(this.number, this.id, this.title, this.options);
  final int number;
  final String id, title;
  final List<SurveyOption> options;
}

/// Product questions adapted from WHO STEPS/GPAQ, NCI DSQ and CDC BRFSS.
/// This shortened, combined survey is not a validated clinical instrument.
const personalizationQuestions = [
  SurveyQuestion(2, 'formulaSex', 'Hệ số sinh lý dùng để tính năng lượng?', [
    SurveyOption('male', 'Nam · hệ số công thức'),
    SurveyOption('female', 'Nữ · hệ số công thức'),
  ]),
  SurveyQuestion(7, 'pace', 'Bạn muốn điều chỉnh năng lượng theo nhịp nào?', [
    SurveyOption('gentle', 'Nhẹ · dễ bắt đầu'),
    SurveyOption('moderate', 'Vừa'),
  ]),
  SurveyQuestion(
    8,
    'guidance',
    'Bạn có cần hướng dẫn dinh dưỡng riêng không?',
    [
      SurveyOption('eligible', 'Không, tôi thuộc phạm vi đề xuất'),
      SurveyOption('needsGuidance', 'Có, tôi cần hướng dẫn riêng'),
      SurveyOption('preferNotSay', 'Tôi không muốn trả lời'),
    ],
  ),
  SurveyQuestion(
    9,
    'activity',
    'Sinh hoạt thường ngày của bạn vận động thế nào?',
    [
      SurveyOption('sedentary', 'Chủ yếu ngồi'),
      SurveyOption('light', 'Hoạt động nhẹ'),
      SurveyOption('active', 'Hoạt động vừa'),
      SurveyOption('heavy', 'Hoạt động nhiều / lao động thể lực'),
    ],
  ),
  SurveyQuestion(
    10,
    'exerciseDays',
    'Bạn thường tập bao nhiêu ngày mỗi tuần?',
    [
      SurveyOption(0, 'Chưa tập thường xuyên'),
      SurveyOption(1, '1 ngày'),
      SurveyOption(2, '2 ngày'),
      SurveyOption(3, '3 ngày'),
      SurveyOption(4, '4 ngày'),
      SurveyOption(5, '5 ngày'),
      SurveyOption(6, '6 ngày'),
      SurveyOption(7, '7 ngày'),
    ],
  ),
  SurveyQuestion(
    11,
    'exerciseMinutes',
    'Một buổi tập thường kéo dài bao lâu?',
    [
      SurveyOption(15, 'Khoảng 15 phút'),
      SurveyOption(30, 'Khoảng 30 phút'),
      SurveyOption(45, 'Khoảng 45 phút'),
      SurveyOption(60, 'Khoảng 60 phút'),
      SurveyOption(90, 'Khoảng 90 phút'),
      SurveyOption(120, 'Khoảng 120 phút'),
      SurveyOption(180, 'Khoảng 180 phút'),
      SurveyOption(240, 'Khoảng 240 phút'),
    ],
  ),
  SurveyQuestion(12, 'exerciseType', 'Bạn thường tập loại hình nào?', [
    SurveyOption('light', 'Đi bộ chậm, giãn cơ · nhẹ'),
    SurveyOption('moderate', 'Đi bộ nhanh, đạp xe thư thả · vừa'),
    SurveyOption('vigorous', 'Chạy, thể thao cường độ cao · mạnh'),
    SurveyOption('strength', 'Tập sức mạnh / tập tạ'),
    SurveyOption('other', 'Khác hoặc kết hợp nhiều loại'),
  ]),
  SurveyQuestion(13, 'diet', 'Bạn thường ăn theo lựa chọn nào?', [
    SurveyOption('general', 'Ăn đa dạng, không theo chế độ riêng'),
    SurveyOption('vegetarian', 'Ăn chay có trứng / sữa'),
    SurveyOption('vegan', 'Thuần chay'),
    SurveyOption('other', 'Lựa chọn khác'),
  ]),
  SurveyQuestion(
    14,
    'avoidFoods',
    'Bạn có dị ứng hoặc thực phẩm cần tránh không?',
    [],
  ),
  SurveyQuestion(
    15,
    'produce',
    'Bạn thường ăn rau và trái cây với tần suất nào?',
    [
      SurveyOption('rarely', 'Hiếm khi'),
      SurveyOption('someDays', 'Một số ngày trong tuần'),
      SurveyOption('daily', 'Hằng ngày'),
    ],
  ),
  SurveyQuestion(
    16,
    'sweetDrinks',
    'Bạn uống đồ uống thêm đường với tần suất nào?',
    [
      SurveyOption('rarely', 'Không uống hoặc hiếm khi'),
      SurveyOption('someDays', 'Một số ngày trong tuần'),
      SurveyOption('daily', 'Hằng ngày'),
    ],
  ),
  SurveyQuestion(
    17,
    'sleepHours',
    'Bạn ngủ trung bình bao nhiêu giờ trong 24 giờ?',
    [],
  ),
  SurveyQuestion(
    18,
    'sleepSchedule',
    'Lịch ngủ và thức của bạn thường thế nào?',
    [
      SurveyOption('regular', 'Tương đối cố định'),
      SurveyOption('irregular', 'Thường xuyên thay đổi'),
      SurveyOption('shift', 'Thay đổi theo ca làm việc'),
    ],
  ),
  SurveyQuestion(
    19,
    'barrier',
    'Điều gì khiến bạn khó duy trì thói quen nhất?',
    [
      SurveyOption('time', 'Thiếu thời gian'),
      SurveyOption('budget', 'Chi phí'),
      SurveyOption('foodChoice', 'Khó chọn món phù hợp'),
      SurveyOption('motivation', 'Khó duy trì động lực'),
      SurveyOption('none', 'Chưa có khó khăn nổi bật'),
    ],
  ),
  SurveyQuestion(
    20,
    'priority',
    'Ngoài mục tiêu chính, bạn muốn ưu tiên điều gì?',
    [
      SurveyOption('nutrition', 'Ăn uống'),
      SurveyOption('activity', 'Vận động'),
      SurveyOption('sleep', 'Giấc ngủ'),
    ],
  ),
];

class PersonalizationAnswers {
  PersonalizationAnswers([Map<String, Object?> values = const {}])
    : values = Map.unmodifiable(values);

  final Map<String, Object?> values;
  Object? operator [](String id) => values[id];

  PersonalizationAnswers withAnswer(String id, Object? value) =>
      PersonalizationAnswers({...values, id: value});

  PersonalizationAnswers normalized(HealthGoal? goal) =>
      PersonalizationAnswers({
        ...values,
        if (goal?.needsTargetWeight != true) 'pace': null,
        if (values['exerciseDays'] == 0) ...{
          'exerciseMinutes': null,
          'exerciseType': null,
        },
      });

  String? validate() {
    final ids = personalizationQuestions.map((q) => q.id).toSet();
    if (values.keys.any((id) => !ids.contains(id))) {
      return 'Câu trả lời không hợp lệ.';
    }
    for (final q in personalizationQuestions) {
      final v = values[q.id];
      if (v == null) continue;
      if (q.id == 'avoidFoods') {
        if (v is! String || v.length > 200) {
          return 'Thực phẩm cần tránh tối đa 200 ký tự.';
        }
      } else if (q.id == 'sleepHours') {
        if (v is! num || !v.isFinite || v < 0 || v > 24) {
          return 'Giờ ngủ cần từ 0 đến 24.';
        }
      } else if (!q.options.any((o) => o.value == v)) {
        return 'Kiểm tra câu ${q.number}: ${q.title}';
      }
    }
    if (values['exerciseDays'] == 0 &&
        (values['exerciseMinutes'] != null || values['exerciseType'] != null)) {
      return 'Không ghi thời lượng tập khi chưa tập thường xuyên.';
    }
    return null;
  }

  Map<String, Object?> toMap() {
    final error = validate();
    if (error != null) throw FormatException(error);
    return {
      'version': 1,
      for (final q in personalizationQuestions) q.id: values[q.id],
    };
  }

  factory PersonalizationAnswers.fromMap(Map<String, dynamic> data) {
    if (data['version'] != 1) {
      throw const FormatException('Phiên bản câu hỏi chưa hỗ trợ.');
    }
    final result = PersonalizationAnswers(
      Map<String, Object?>.from(data)..remove('version'),
    );
    final error = result.validate();
    if (error != null) throw FormatException(error);
    return result;
  }

  FormulaSex? get formulaSex => switch (values['formulaSex']) {
    'male' => FormulaSex.male,
    'female' => FormulaSex.female,
    _ => null,
  };
  PlanActivity? get activity => switch (values['activity']) {
    'sedentary' => PlanActivity.sedentary,
    'light' => PlanActivity.light,
    'active' => PlanActivity.active,
    'heavy' => PlanActivity.heavy,
    _ => null,
  };
  PlanPace get pace =>
      values['pace'] == 'moderate' ? PlanPace.moderate : PlanPace.gentle;
  bool get eligible => values['guidance'] == 'eligible';

  String? label(String id) {
    final q = personalizationQuestions.firstWhere((q) => q.id == id);
    final value = values[id];
    if (value == null) return null;
    if (id == 'sleepHours') return '$value giờ/24 giờ (tự khai)';
    if (id == 'avoidFoods') return (value as String).isEmpty ? null : value;
    return q.options.where((o) => o.value == value).firstOrNull?.label;
  }

  List<String> get segmentLabels => [
    for (final entry in const {
      'activity': 'Sinh hoạt',
      'diet': 'Ăn uống',
      'sweetDrinks': 'Đồ uống thêm đường',
      'sleepSchedule': 'Lịch ngủ',
      'barrier': 'Khó khăn',
      'priority': 'Ưu tiên',
    }.entries)
      if (label(entry.key) case final String label) '${entry.value}: $label',
  ];

  String get firstAction => switch (values['priority']) {
    'activity' =>
      'Bắt đầu bằng một hoạt động bạn thấy phù hợp và ghi lại trong Nhật ký.',
    'sleep' =>
      'Vào Thêm → Thói quen & kế hoạch → Giấc ngủ để ghi một lần ngủ/dậy.',
    'nutrition' => 'Bắt đầu bằng việc ghi một bữa ăn và kiểm tra khẩu phần.',
    _ =>
      'Chọn một thói quen bạn muốn theo dõi trước; bạn có thể đổi lựa chọn sau.',
  };
}
