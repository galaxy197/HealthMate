import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// A pinned, accessible heading shared by tracking and report screens.
class TrackingPage extends StatelessWidget {
  const TrackingPage({required this.header, required this.children, super.key});
  final Widget header;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 64 * scale,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleSpacing: 18,
          title: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentWidth,
              ),
              child: header,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
