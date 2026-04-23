import 'package:flutter/material.dart';
import 'dart:typed_data';

/// Custom painter for drawing mask outlines on canvas
class MaskPainter extends CustomPainter {
  final List<Offset>? contourPoints;
  final Color strokeColor;
  final double strokeWidth;
  final bool fillMask;
  final Color fillColor;

  MaskPainter({
    this.contourPoints,
    this.strokeColor = Colors.blue,
    this.strokeWidth = 2.0,
    this.fillMask = false,
    this.fillColor = const Color(0x400088D1),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (contourPoints == null || contourPoints!.isEmpty) return;

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw contour
    final path = Path();
    if (contourPoints!.isNotEmpty) {
      path.moveTo(contourPoints![0].dx * size.width, contourPoints![0].dy * size.height);
      for (int i = 1; i < contourPoints!.length; i++) {
        path.lineTo(
          contourPoints![i].dx * size.width,
          contourPoints![i].dy * size.height,
        );
      }
      path.close();
    }

    // Fill if requested
    if (fillMask) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    // Draw outline
    canvas.drawPath(path, paint);

    // Draw control points at vertices
    final pointPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    for (final point in contourPoints!) {
      final x = point.dx * size.width;
      final y = point.dy * size.height;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    return oldDelegate.contourPoints != contourPoints ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fillMask != fillMask ||
        oldDelegate.fillColor != fillColor;
  }
}

/// Widget that displays image with mask overlay
class MaskOverlay extends StatelessWidget {
  final dynamic backgroundImage; // img.Image
  final List<Offset>? contourPoints;
  final bool showMask;

  const MaskOverlay({
    super.key,
    required this.backgroundImage,
    this.contourPoints,
    this.showMask = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.memory(
            _encodeImage(backgroundImage),
            fit: BoxFit.contain,
          ),
        ),

        // Mask overlay
        if (showMask && contourPoints != null)
          Positioned.fill(
            child: CustomPaint(
              painter: MaskPainter(
                contourPoints: contourPoints,
                fillMask: true,
              ),
            ),
          ),
      ],
    );
  }

  Uint8List _encodeImage(dynamic image) {
    // TODO: Implement proper encoding
    return Uint8List(0);
  }
}
