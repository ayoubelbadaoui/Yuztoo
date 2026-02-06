import 'package:flutter/material.dart';

/// Custom painter for QR code pattern display
class QrPatternPainter extends CustomPainter {
  const QrPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final scale = size.width / 100.0; // Scale factor for different sizes

    // Corner markers - scaled
    final corners = [
      (8.0 * scale, 8.0 * scale, 22.0 * scale),   // top-left
      (75.0 * scale, 8.0 * scale, 22.0 * scale),  // top-right
      (8.0 * scale, 75.0 * scale, 22.0 * scale), // bottom-left
    ];

    for (var (x, y, s) in corners) {
      // Outer square
      canvas.drawRect(
        Rect.fromLTWH(x, y, s, s),
        paint..color = color.withOpacity(0.6),
      );
      // Middle square
      canvas.drawRect(
        Rect.fromLTWH(x + 3 * scale, y + 3 * scale, s - 6 * scale, s - 6 * scale),
        paint..color = color.withOpacity(0.4),
      );
      // Inner square
      canvas.drawRect(
        Rect.fromLTWH(
          x + 6 * scale,
          y + 6 * scale,
          s - 12 * scale,
          s - 12 * scale,
        ),
        paint..color = color,
      );
    }

    // Data pattern - more realistic QR pattern
    final cellSize = size.width / 25.0;
    final dataPattern = [
      // Top section
      (35.0 * scale, 35.0 * scale),
      (40.0 * scale, 35.0 * scale),
      (50.0 * scale, 35.0 * scale),
      (55.0 * scale, 35.0 * scale),
      (60.0 * scale, 35.0 * scale),
      (65.0 * scale, 35.0 * scale),
      // Middle section
      (35.0 * scale, 40.0 * scale),
      (45.0 * scale, 40.0 * scale),
      (50.0 * scale, 40.0 * scale),
      (60.0 * scale, 40.0 * scale),
      (35.0 * scale, 50.0 * scale),
      (40.0 * scale, 50.0 * scale),
      (45.0 * scale, 50.0 * scale),
      (55.0 * scale, 50.0 * scale),
      (60.0 * scale, 50.0 * scale),
      (65.0 * scale, 50.0 * scale),
      // Bottom section
      (35.0 * scale, 55.0 * scale),
      (45.0 * scale, 55.0 * scale),
      (50.0 * scale, 55.0 * scale),
      (60.0 * scale, 55.0 * scale),
      (35.0 * scale, 60.0 * scale),
      (40.0 * scale, 60.0 * scale),
      (50.0 * scale, 60.0 * scale),
      (55.0 * scale, 60.0 * scale),
      (65.0 * scale, 60.0 * scale),
      (35.0 * scale, 65.0 * scale),
      (40.0 * scale, 65.0 * scale),
      (50.0 * scale, 65.0 * scale),
      (60.0 * scale, 65.0 * scale),
    ];

    for (var (x, y) in dataPattern) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellSize * 0.8, cellSize * 0.8),
          Radius.circular(cellSize * 0.15),
        ),
        paint..color = color.withOpacity(0.7),
      );
    }
  }

  @override
  bool shouldRepaint(QrPatternPainter oldDelegate) => false;
}

