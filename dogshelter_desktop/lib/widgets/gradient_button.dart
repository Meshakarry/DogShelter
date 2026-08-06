import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Rectangular (no rounding) filled button with a radial gradient - the primary save/submit
/// action on form screens.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.6),
            radius: 1.3,
            colors: [Color(0xFF3D9270), AppTheme.seedColor],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                child: IconTheme.merge(data: const IconThemeData(color: Colors.white), child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
