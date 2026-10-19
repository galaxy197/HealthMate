import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

/// Skeleton loader với shimmer effect
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    this.width,
    this.height = 20,
    this.borderRadius,
    super.key,
  });

  const SkeletonLoader.card({
    this.width,
    this.height = 120,
    super.key,
  }) : borderRadius = const BorderRadius.all(
          Radius.circular(AppSpacing.cardRadius),
        );

  const SkeletonLoader.circle({
    required double size,
    super.key,
  })  : width = size,
        height = size,
        borderRadius = const BorderRadius.all(Radius.circular(999));

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_controller.value * 2), 0),
              end: Alignment(1.0 + (_controller.value * 2), 0),
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ]
                  : [
                      Colors.black.withOpacity(0.04),
                      Colors.black.withOpacity(0.08),
                      Colors.black.withOpacity(0.04),
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Dashboard skeleton với multiple loaders
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        // Hero section skeleton
        SkeletonLoader(height: 160),
        SizedBox(height: AppSpacing.lg),

        // Metric cards grid
        Row(
          children: [
            Expanded(
              child: SkeletonLoader.card(height: 120),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: SkeletonLoader.card(height: 120),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: SkeletonLoader.card(height: 120),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: SkeletonLoader.card(height: 120),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),

        // Chart card
        SkeletonLoader.card(height: 200),
        SizedBox(height: AppSpacing.lg),

        // List items
        SkeletonLoader(height: 60),
        SizedBox(height: AppSpacing.sm),
        SkeletonLoader(height: 60),
        SizedBox(height: AppSpacing.sm),
        SkeletonLoader(height: 60),
      ],
    );
  }
}
