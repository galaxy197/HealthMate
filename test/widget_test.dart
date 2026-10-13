import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/shared/providers/theme_mode_provider.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('starts in Vietnamese with honest pending content', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    expect(find.text('Từng bước nhỏ,\nsống khỏe hơn.'), findsOneWidget);
    expect(find.text('Tổng quan đang được chuẩn bị'), findsOneWidget);
    expect(find.text('Đang chờ triển khai'), findsOneWidget);
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      AppRoutes.dashboard,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('vi'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('all five navigation destinations open the correct route', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    for (final destination in [
      (label: 'Nhật ký', route: AppRoutes.journal, title: 'Nhật ký của bạn'),
      (label: 'Quest', route: AppRoutes.quest, title: 'Nhịp khỏe mỗi ngày'),
      (
        label: 'AI / Chat',
        route: AppRoutes.chat,
        title: 'Thêm một người đồng hành',
      ),
      (label: 'Cá nhân', route: AppRoutes.profile, title: 'Không gian cá nhân'),
      (
        label: 'Tổng quan',
        route: AppRoutes.dashboard,
        title: 'Từng bước nhỏ,\nsống khỏe hơn.',
      ),
    ]) {
      await tester.tap(
        find.widgetWithText(NavigationDestination, destination.label),
      );
      await tester.pumpAndSettle();
      expect(find.text(destination.title), findsOneWidget);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        destination.route,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('dashboard actions navigate and account can sign out', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Khám phá nhật ký'));
    await tester.pumpAndSettle();
    expect(find.text('Nhật ký của bạn'), findsOneWidget);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Cá nhân'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('authenticated user is redirected away from auth', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    container.read(appRouterProvider).go(AppRoutes.auth);
    await tester.pumpAndSettle();
    expect(find.text('Từng bước nhỏ,\nsống khỏe hơn.'), findsOneWidget);
  });

  testWidgets('unknown route has a working recovery action', (tester) async {
    final container = await pumpApp(tester);
    container.read(appRouterProvider).go('/missing');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy trang'), findsOneWidget);
    await tester.tap(find.text('Về Tổng quan'));
    await tester.pumpAndSettle();
    expect(find.text('Từng bước nhỏ,\nsống khỏe hơn.'), findsOneWidget);
  });

  testWidgets('theme preference changes the app and survives navigation', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    container.read(appRouterProvider).go(AppRoutes.profile);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Tối'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tối'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.dark,
    );
    container.read(appRouterProvider).go(AppRoutes.dashboard);
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(tester.takeException(), isNull);
  });

  for (final layout in [
    (
      name: 'small phone with large text',
      size: const Size(320, 640),
      scale: 2.0,
      rail: false,
    ),
    (name: 'wide screen', size: const Size(1024, 768), scale: 1.0, rail: true),
  ]) {
    testWidgets('routes fit ${layout.name} without layout exceptions', (
      tester,
    ) async {
      final container = await pumpApp(
        tester,
        size: layout.size,
        textScale: layout.scale,
      );
      for (final route in [
        AppRoutes.dashboard,
        AppRoutes.journal,
        AppRoutes.quest,
        AppRoutes.chat,
        AppRoutes.profile,
        AppRoutes.auth,
      ]) {
        container.read(appRouterProvider).go(route);
        await tester.pumpAndSettle();
        if (route != AppRoutes.auth) {
          expect(
            find.byType(NavigationRail),
            layout.rail ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(NavigationBar),
            layout.rail ? findsNothing : findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull, reason: route);
      }
    });
  }
}
