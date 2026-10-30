import 'package:flutter/material.dart';

/// Supporting information stays in the current screen and opens on request.
class HelpDetails extends StatelessWidget {
  const HelpDetails({
    required this.children,
    this.title = 'Cách sử dụng',
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 12),
    shape: const Border(),
    collapsedShape: const Border(),
    title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
    children: [
      DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: children,
        ),
      ),
    ],
  );
}
