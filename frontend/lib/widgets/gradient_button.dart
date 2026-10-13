import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Primary call-to-action with a glowing gradient and hover lift.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover && enabled ? -2 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 17),
          decoration: BoxDecoration(
            gradient: CF.brandGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: CF.violet.withValues(alpha: enabled ? (_hover ? 0.65 : 0.40) : 0.12),
                blurRadius: _hover ? 34 : 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Opacity(
            opacity: enabled || widget.loading ? 1 : 0.55,
            child: Row(
              mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                else if (widget.icon != null)
                  Icon(widget.icon, size: 20, color: Colors.white),
                if (widget.loading || widget.icon != null) const SizedBox(width: 10),
                Text(widget.label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
