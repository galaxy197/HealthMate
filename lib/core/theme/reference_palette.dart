import 'package:flutter/material.dart';

/// Reference v2 tokens. Text colors are darker than the preview's small labels
/// to retain readable contrast on translucent cards.
abstract final class ReferencePalette {
  static const blue = Color(0xFF3D7DFA);
  static const ink = Color(0xFF171818);
  static const muted = Color(0xFF5F6269);
  static const carb = Color(0xFF67CAD3);
  static const protein = Color(0xFF76C87A);
  static const fat = Color(0xFFFFCB48);
  static const lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, .27, .58, 1],
    colors: [
      Color(0xFFE4E9F6),
      Color(0xFFE6E6E8),
      Color(0xFFEEE1D1),
      Color(0xFFE3EAF9),
    ],
  );
  static const darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, .55, 1],
    colors: [Color(0xFF1D263A), Color(0xFF292B34), Color(0xFF202B41)],
  );
}

class AppCanvas extends StatelessWidget {
  const AppCanvas({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: Theme.of(context).brightness == Brightness.dark
          ? ReferencePalette.darkGradient
          : ReferencePalette.lightGradient,
    ),
    child: child,
  );
}
