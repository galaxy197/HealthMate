import 'package:flutter/material.dart';

/// Builds secondary content only after the user asks for it.
class DetailsDisclosure extends StatefulWidget {
  const DetailsDisclosure({
    required this.title,
    required this.builder,
    super.key,
  });

  final String title;
  final WidgetBuilder builder;

  @override
  State<DetailsDisclosure> createState() => _DetailsDisclosureState();
}

class _DetailsDisclosureState extends State<DetailsDisclosure> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
    title: Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
    onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
    children: [if (_expanded) widget.builder(context)],
  );
}
