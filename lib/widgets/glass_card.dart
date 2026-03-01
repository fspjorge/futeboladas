import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.05,
    this.borderRadius = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: (color ?? Colors.white).withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GridBackdropPainter extends CustomPainter {
  final Color color;
  final double spacing;

  GridBackdropPainter({this.color = Colors.white, this.spacing = 40});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
