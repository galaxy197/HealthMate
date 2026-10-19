/// Exercise categories for better organization
enum ExerciseCategory {
  cardio('Tim mạch'),
  strength('Sức mạnh'),
  flexibility('Linh hoạt'),
  sports('Thể thao'),
  daily('Sinh hoạt');

  const ExerciseCategory(this.label);
  final String label;
}

/// Exercise catalog item với MET value
/// MET (Metabolic Equivalent of Task) = tỷ lệ năng lượng tiêu hao so với nghỉ ngơi
/// Calories burned = MET × weight(kg) × duration(hours)
class ExerciseCatalogItem {
  const ExerciseCatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.met,
    this.description,
  });

  final String id;
  final String name;
  final ExerciseCategory category;
  final double met; // Metabolic Equivalent of Task
  final String? description;

  /// Tính calories tiêu hao
  /// Formula: Calories = MET × weight(kg) × duration(hours)
  double calculateCalories({
    required double weightKg,
    required int durationMinutes,
  }) {
    final hours = durationMinutes / 60.0;
    return met * weightKg * hours;
  }
}

/// Common exercises với MET values (Compendium of Physical Activities)
/// Nguồn: https://sites.google.com/site/compendiumofphysicalactivities/
abstract final class ExerciseCatalog {
  static final exercises = <ExerciseCatalogItem>[
    // CARDIO
    const ExerciseCatalogItem(
      id: 'walking_slow',
      name: 'Đi bộ chậm',
      category: ExerciseCategory.cardio,
      met: 2.0,
      description: '3-4 km/h, tản bộ',
    ),
    const ExerciseCatalogItem(
      id: 'walking_moderate',
      name: 'Đi bộ vừa',
      category: ExerciseCategory.cardio,
      met: 3.5,
      description: '5-6 km/h, nhịp bình thường',
    ),
    const ExerciseCatalogItem(
      id: 'walking_brisk',
      name: 'Đi bộ nhanh',
      category: ExerciseCategory.cardio,
      met: 4.5,
      description: '6-7 km/h, cường độ cao',
    ),
    const ExerciseCatalogItem(
      id: 'running_light',
      name: 'Chạy bộ nhẹ',
      category: ExerciseCategory.cardio,
      met: 6.0,
      description: '8 km/h, jogging',
    ),
    const ExerciseCatalogItem(
      id: 'running_moderate',
      name: 'Chạy bộ vừa',
      category: ExerciseCategory.cardio,
      met: 8.0,
      description: '9-10 km/h',
    ),
    const ExerciseCatalogItem(
      id: 'running_fast',
      name: 'Chạy bộ nhanh',
      category: ExerciseCategory.cardio,
      met: 11.0,
      description: '12 km/h trở lên',
    ),
    const ExerciseCatalogItem(
      id: 'cycling_light',
      name: 'Đạp xe nhẹ',
      category: ExerciseCategory.cardio,
      met: 4.0,
      description: '15 km/h, địa hình bằng',
    ),
    const ExerciseCatalogItem(
      id: 'cycling_moderate',
      name: 'Đạp xe vừa',
      category: ExerciseCategory.cardio,
      met: 8.0,
      description: '20-25 km/h',
    ),
    const ExerciseCatalogItem(
      id: 'cycling_vigorous',
      name: 'Đạp xe mạnh',
      category: ExerciseCategory.cardio,
      met: 12.0,
      description: '30 km/h trở lên hoặc dốc',
    ),
    const ExerciseCatalogItem(
      id: 'swimming_light',
      name: 'Bơi lội nhẹ',
      category: ExerciseCategory.cardio,
      met: 6.0,
      description: 'Bơi tự do chậm',
    ),
    const ExerciseCatalogItem(
      id: 'swimming_moderate',
      name: 'Bơi lội vừa',
      category: ExerciseCategory.cardio,
      met: 10.0,
      description: 'Bơi liên tục, cường độ cao',
    ),
    const ExerciseCatalogItem(
      id: 'jump_rope',
      name: 'Nhảy dây',
      category: ExerciseCategory.cardio,
      met: 11.0,
      description: 'Nhịp trung bình, liên tục',
    ),

    // STRENGTH
    const ExerciseCatalogItem(
      id: 'weightlifting_light',
      name: 'Tập tạ nhẹ',
      category: ExerciseCategory.strength,
      met: 3.0,
      description: 'Free weights, cường độ thấp',
    ),
    const ExerciseCatalogItem(
      id: 'weightlifting_moderate',
      name: 'Tập tạ vừa',
      category: ExerciseCategory.strength,
      met: 5.0,
      description: 'Cường độ trung bình',
    ),
    const ExerciseCatalogItem(
      id: 'weightlifting_vigorous',
      name: 'Tập tạ mạnh',
      category: ExerciseCategory.strength,
      met: 6.0,
      description: 'High intensity, heavy weights',
    ),
    const ExerciseCatalogItem(
      id: 'push_ups',
      name: 'Chống đẩy',
      category: ExerciseCategory.strength,
      met: 3.8,
      description: 'Bodyweight exercise',
    ),
    const ExerciseCatalogItem(
      id: 'pull_ups',
      name: 'Kéo xà đơn',
      category: ExerciseCategory.strength,
      met: 4.0,
      description: 'Pull-ups, chin-ups',
    ),
    const ExerciseCatalogItem(
      id: 'calisthenics',
      name: 'Tập thể dục nhịp điệu',
      category: ExerciseCategory.strength,
      met: 3.5,
      description: 'Burpees, squats, lunges',
    ),

    // FLEXIBILITY
    const ExerciseCatalogItem(
      id: 'yoga_light',
      name: 'Yoga nhẹ',
      category: ExerciseCategory.flexibility,
      met: 2.5,
      description: 'Hatha, stretching',
    ),
    const ExerciseCatalogItem(
      id: 'yoga_power',
      name: 'Yoga mạnh',
      category: ExerciseCategory.flexibility,
      met: 4.0,
      description: 'Power yoga, Vinyasa',
    ),
    const ExerciseCatalogItem(
      id: 'pilates',
      name: 'Pilates',
      category: ExerciseCategory.flexibility,
      met: 3.0,
    ),
    const ExerciseCatalogItem(
      id: 'stretching',
      name: 'Giãn cơ',
      category: ExerciseCategory.flexibility,
      met: 2.3,
      description: 'Stretching tĩnh',
    ),

    // SPORTS
    const ExerciseCatalogItem(
      id: 'badminton',
      name: 'Cầu lông',
      category: ExerciseCategory.sports,
      met: 5.5,
      description: 'Chơi đôi hoặc đơn',
    ),
    const ExerciseCatalogItem(
      id: 'basketball',
      name: 'Bóng rổ',
      category: ExerciseCategory.sports,
      met: 6.5,
      description: 'Chơi trận, full court',
    ),
    const ExerciseCatalogItem(
      id: 'soccer',
      name: 'Bóng đá',
      category: ExerciseCategory.sports,
      met: 7.0,
      description: 'Thi đấu, cường độ cao',
    ),
    const ExerciseCatalogItem(
      id: 'tennis',
      name: 'Quần vợt',
      category: ExerciseCategory.sports,
      met: 7.3,
      description: 'Chơi đơn',
    ),
    const ExerciseCatalogItem(
      id: 'table_tennis',
      name: 'Bóng bàn',
      category: ExerciseCategory.sports,
      met: 4.0,
    ),
    const ExerciseCatalogItem(
      id: 'volleyball',
      name: 'Bóng chuyền',
      category: ExerciseCategory.sports,
      met: 4.0,
      description: 'Giải trí',
    ),

    // DAILY ACTIVITIES
    const ExerciseCatalogItem(
      id: 'housework_light',
      name: 'Việc nhà nhẹ',
      category: ExerciseCategory.daily,
      met: 2.5,
      description: 'Quét, lau, nấu ăn',
    ),
    const ExerciseCatalogItem(
      id: 'housework_moderate',
      name: 'Việc nhà vừa',
      category: ExerciseCategory.daily,
      met: 3.5,
      description: 'Lau sàn, hút bụi, giặt tay',
    ),
    const ExerciseCatalogItem(
      id: 'gardening',
      name: 'Làm vườn',
      category: ExerciseCategory.daily,
      met: 4.0,
      description: 'Trồng cây, cắt cỏ',
    ),
    const ExerciseCatalogItem(
      id: 'stairs_climbing',
      name: 'Leo cầu thang',
      category: ExerciseCategory.daily,
      met: 8.0,
      description: 'Lên xuống cầu thang liên tục',
    ),
    const ExerciseCatalogItem(
      id: 'dancing',
      name: 'Nhảy múa',
      category: ExerciseCategory.daily,
      met: 4.8,
      description: 'Nhảy ballroom, aerobic',
    ),
  ];

  /// Search exercises by name
  static List<ExerciseCatalogItem> search(String query) {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return exercises;

    return exercises
        .where((e) => e.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get exercises by category
  static List<ExerciseCatalogItem> byCategory(ExerciseCategory category) {
    return exercises.where((e) => e.category == category).toList();
  }

  /// Get exercise by ID
  static ExerciseCatalogItem? findById(String id) {
    try {
      return exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
