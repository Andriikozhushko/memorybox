import 'package:flutter/material.dart';

class ThumbsSlider extends SliderComponentShape {
  ThumbsSlider();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size.fromRadius(3.0);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.red
      ..style = PaintingStyle.fill;

    double height = 25;
    double width = 35;

    final path = Path();

    path.moveTo(center.dx - height / 2, center.dy);
    path.quadraticBezierTo(
      center.dx,
      center.dy + width / 4,
      center.dx + height / 2,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx,
      center.dy - width / 4,
      center.dx - height / 2,
      center.dy,
    );

    canvas.drawPath(path, paint);
  }
}
