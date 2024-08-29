import 'package:flutter/material.dart';

class EllipseClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(
        size.width * 0.6, size.height, size.width, size.height * 0.9);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BackgroundShape extends StatelessWidget {
  const BackgroundShape({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
