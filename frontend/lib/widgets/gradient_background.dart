import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Page backdrop: near-black base with two soft, glowing colour blooms.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  Widget _bloom(Color c, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [c.withValues(alpha: 0.35), c.withValues(alpha: 0)]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Positioned.fill(child: ColoredBox(color: CF.bg)),
      Positioned(top: -220, left: -160, child: _bloom(CF.violet, 700)),
      Positioned(top: 120, right: -240, child: _bloom(CF.cyan, 640)),
      Positioned(bottom: -300, left: 200, child: _bloom(CF.pink, 640)),
      Positioned.fill(child: child),
    ]);
  }
}
