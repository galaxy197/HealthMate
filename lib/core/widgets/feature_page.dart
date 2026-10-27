import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'profile_avatar.dart';

class FeaturePage extends StatelessWidget {
  const FeaturePage({
    required this.title,
    required this.subtitle,
    required this.children,
    this.compactHeader = false,
    this.showProfileAvatar = false,
    this.headerAction,
    this.contentPadding,
    this.titleStyle,
    this.headerGap,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool compactHeader;
  final bool showProfileAvatar;
  final Widget? headerAction;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? titleStyle;
  final double? headerGap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentWidth,
              ),
              child: Padding(
                padding:
                    contentPadding ??
                    EdgeInsets.all(
                      compactHeader ? AppSpacing.md : AppSpacing.lg,
                    ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (showProfileAvatar) ...[
                          const ProfileAvatar(),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style:
                                  titleStyle ?? theme.textTheme.headlineSmall,
                            ),
                          ),
                        ),
                        ?headerAction,
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    SizedBox(
                      height:
                          headerGap ??
                          (compactHeader ? AppSpacing.sm : AppSpacing.lg),
                    ),
                    ...children,
                    const SizedBox(height: AppSpacing.xl),
                    const HealthDisclaimer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HealthDisclaimer extends StatelessWidget {
  const HealthDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'HealthMate hỗ trợ theo dõi thói quen, không thay thế tư vấn y tế.',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
