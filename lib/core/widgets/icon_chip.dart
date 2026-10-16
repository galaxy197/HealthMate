import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class IconChip extends StatelessWidget {
  const IconChip({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    super.key,
    this.size = AppSpacing.iconChipSize,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Icon(icon, color: foregroundColor, size: size * 0.5),
  );
}
