import 'package:flutter/material.dart';

/// Small vector-derived artwork exported from the user's Reference v2 kit.
/// No screen or example health data is embedded as a product image.
class DesignIllustration extends StatelessWidget {
  const DesignIllustration(this.name, {this.size = 40, super.key});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/design/$name.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    ),
  );
}
