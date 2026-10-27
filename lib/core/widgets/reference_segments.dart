import 'package:flutter/material.dart';

class ReferenceSegments extends StatelessWidget {
  const ReferenceSegments({required this.items, super.key});
  final List<({String label, bool selected, VoidCallback onTap, Key key})>
  items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final theme = Theme.of(context);
      final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final children = [
        for (final item in items)
          Container(
            decoration: BoxDecoration(
              color: item.selected
                  ? theme.colorScheme.surface
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextButton(
              key: item.key,
              onPressed: item.onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: item.selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
      ];
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(24),
        ),
        child: large
            ? Wrap(spacing: 6, children: children)
            : Row(
                children: [
                  for (final child in children) Expanded(child: child),
                ],
              ),
      );
    },
  );
}
