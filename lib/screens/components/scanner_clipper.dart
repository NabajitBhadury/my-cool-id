import 'package:flutter/material.dart';

class ScannerClipper extends CustomClipper<Path> {
  final double squareSize;

  ScannerClipper(this.squareSize);

  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: squareSize,
            height: squareSize,
          ),
          const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
