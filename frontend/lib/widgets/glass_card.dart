import 'dart:ui';
import 'package:flutter/material.dart';

/// Frosted-glass surface (backdrop blur + translucent fill + hairline border).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 22,
    this.glow,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? glow; // optional coloured halo

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow == null
            ? null
            : [BoxShadow(color: glow!.withValues(alpha: 0.25), blurRadius: 40, spreadRadius: -6)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.055),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
