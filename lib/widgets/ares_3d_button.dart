import 'package:flutter/material.dart';
import '../theme/ares_theme.dart';

class Ares3DButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color color;
  final Color shadowColor;

  const Ares3DButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color = AresColors.primary,
    this.shadowColor = AresColors.primaryDark,
  });

  @override
  State<Ares3DButton> createState() => _Ares3DButtonState();
}

class _Ares3DButtonState extends State<Ares3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double height = 52.0;
    const double depth = 5.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        height: height,
        margin: EdgeInsets.only(top: _isPressed ? depth : 0.0),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: const Offset(0, depth),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: AresColors.textPrimary),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: const TextStyle(
                  color: AresColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
