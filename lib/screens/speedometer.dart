// lib/widgets/speedometer.dart

import 'package:flutter/material.dart';

class Speedometer extends StatelessWidget {
  final double speed;

  Speedometer({required this.speed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, // Adjust to fit the design
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular segmented border
          CustomPaint(
            size: Size(80, 80),
            painter: SegmentPainter(),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                speed.round().toString(), // Display speed as an integer
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'km/h',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom painter for the segmented border
class SegmentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const int segments = 36;
    const double segmentAngle = 2 * 3.141592653589793 / segments;
    const double gapAngle = segmentAngle * 0.3;

    for (int i = 0; i < segments; i++) {
      final double startAngle = i * segmentAngle;
      final double endAngle = startAngle + segmentAngle - gapAngle;

      canvas.drawArc(
        Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2),
            radius: size.width / 2.5),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
