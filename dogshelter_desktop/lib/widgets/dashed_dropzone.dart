import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Light-grey, dashed-border dropzone used for every image picker in this app.
class DashedDropzone extends StatelessWidget {
  const DashedDropzone({
    super.key,
    required this.width,
    required this.height,
    required this.onTap,
    required this.child,
    this.borderColor,
  });

  final double width;
  final double height;
  final VoidCallback onTap;
  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: borderColor ?? Theme.of(context).colorScheme.outlineVariant,
          radius: AppTheme.cardRadius,
        ),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final dashed = Path();
    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashed.addPath(metric.extractPath(distance, distance + dashWidth), Offset.zero);
        distance += dashWidth + dashGap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}
