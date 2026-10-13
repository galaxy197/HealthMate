import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feature_page.dart';

enum AccountInformationPage { about, privacy, disclaimer }

class AccountInformationScreen extends StatelessWidget {
  const AccountInformationScreen({required this.page, super.key});

  final AccountInformationPage page;

  @override
  Widget build(BuildContext context) {
    final content = _content(page);
    return FeaturePage(
      title: content.title,
      subtitle: content.subtitle,
      children: [
        for (final section in content.sections) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(section.body),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.profile),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Quay lại Cá nhân'),
        ),
      ],
    );
  }
}

({String title, String subtitle, List<_InformationSection> sections}) _content(
  AccountInformationPage page,
) => switch (page) {
  AccountInformationPage.about => (
    title: 'Giới thiệu HealthMate',
    subtitle:
        'Công cụ theo dõi thói quen sức khỏe dành cho đời sống hằng ngày.',
    sections: const [
      _InformationSection(
        'Mục đích',
        'HealthMate giúp bạn ghi nhận bữa ăn, nước uống, vận động và thay đổi thể trạng để nhìn lại thói quen của mình.',
      ),
      _InformationSection(
        'Cách sử dụng dữ liệu',
        'Các tổng hợp trong ứng dụng được tính từ dữ liệu bạn chủ động ghi nhận. Kết quả AI chỉ là gợi ý và luôn cần bạn kiểm tra trước khi lưu.',
      ),
    ],
  ),
  AccountInformationPage.privacy => (
    title: 'Quyền riêng tư',
    subtitle:
        'Thông tin bạn lưu được gắn với tài khoản Firebase của chính bạn.',
    sections: const [
      _InformationSection(
        'Dữ liệu tài khoản',
        'Email dùng để xác thực. Hồ sơ, thể trạng và nhật ký được lưu trong Cloud Firestore dưới UID của tài khoản; Security Rules giới hạn quyền đọc và sửa cho chủ tài khoản.',
      ),
      _InformationSection(
        'Dữ liệu trên thiết bị',
        'Lựa chọn giao diện sáng, tối hoặc theo thiết bị được lưu cục bộ trên thiết bị. Dữ liệu này không phải thông tin sức khỏe.',
      ),
      _InformationSection(
        'Tính năng AI',
        'Khi bạn chủ động quét món ăn, ảnh được gửi đến Firebase AI Logic để phân tích. HealthMate không lưu ảnh gốc theo mặc định và chỉ lưu kết quả bạn đã xác nhận.',
      ),
      _InformationSection(
        'Xóa dữ liệu',
        'Bạn có thể xóa tài khoản trong màn Cá nhân. Ứng dụng xóa dữ liệu HealthMate trước rồi mới xóa tài khoản đăng nhập.',
      ),
    ],
  ),
  AccountInformationPage.disclaimer => (
    title: 'Lưu ý sức khỏe',
    subtitle:
        'HealthMate hỗ trợ theo dõi thói quen và không cung cấp chẩn đoán y khoa.',
    sections: const [
      _InformationSection(
        'Thông tin tham khảo',
        'BMI, dinh dưỡng ước tính, gợi ý AI và các nội dung trong ứng dụng chỉ có tính tham khảo. Chúng không thay thế bác sĩ, chuyên gia dinh dưỡng hoặc nhân viên y tế.',
      ),
      _InformationSection(
        'Tình huống khẩn cấp',
        'Nếu bạn có triệu chứng nghiêm trọng hoặc cần trợ giúp khẩn cấp, hãy liên hệ cơ sở y tế hoặc dịch vụ khẩn cấp tại nơi bạn đang ở.',
      ),
      _InformationSection(
        'Quyết định sức khỏe',
        'Không tự thay đổi thuốc, điều trị hoặc chế độ ăn đặc biệt chỉ dựa trên dữ liệu hay gợi ý của HealthMate.',
      ),
    ],
  ),
};

class _InformationSection {
  const _InformationSection(this.title, this.body);

  final String title;
  final String body;
}
