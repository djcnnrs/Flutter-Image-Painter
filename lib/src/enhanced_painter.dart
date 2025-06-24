import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'enhanced_controller.dart';

/// Custom painter for drawing on images
class EnhancedImagePainter extends CustomPainter {
  final EnhancedImagePainterController controller;
  
  EnhancedImagePainter({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    if (controller.backgroundImage != null) {
      canvas.drawImageRect(
        controller.backgroundImage!,
        Rect.fromLTWH(0, 0, controller.backgroundImage!.width.toDouble(), controller.backgroundImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );
    }

    // Draw all freeStyle paths
    for (var path in controller.paths) {
      if (path.length > 1) {
        final paint = Paint()
          ..color = controller.color
          ..strokeWidth = controller.strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        for (int i = 0; i < path.length - 1; i++) {
          canvas.drawLine(path[i], path[i + 1], paint);
        }
      }
    }

    // Draw all other paint history
    for (var info in controller.paintHistory) {
      if (info.mode != PaintMode.freeStyle) {
        _drawPaintInfo(canvas, info);
      }
    }
  }

  void _drawPaintInfo(Canvas canvas, PaintInfo info) {
    switch (info.mode) {
      case PaintMode.line:
        if (info.offset2 != null) {
          canvas.drawLine(info.offset, info.offset2!, info.paint);
        }
        break;
      case PaintMode.arrow:
        if (info.offset2 != null) {
          _drawArrow(canvas, info.offset, info.offset2!, info.paint);
        }
        break;
      case PaintMode.dashedLine:
        if (info.offset2 != null) {
          _drawDashedLine(canvas, info.offset, info.offset2!, info.paint);
        }
        break;
      case PaintMode.rect:
        if (info.offset2 != null) {
          canvas.drawRect(
            Rect.fromPoints(info.offset, info.offset2!),
            info.paint,
          );
        }
        break;
      case PaintMode.circle:
        if (info.offset2 != null) {
          final radius = (info.offset2! - info.offset).distance;
          canvas.drawCircle(info.offset, radius, info.paint);
        }
        break;
      case PaintMode.text:
        if (info.text != null) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: info.text,
              style: TextStyle(
                color: info.paint.color,
                fontSize: info.paint.strokeWidth * 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, info.offset);
        }
        break;
      case PaintMode.freeStyle:
      case PaintMode.none:
        break;
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    
    const arrowSize = 15.0;
    final angle = (end - start).direction;
    
    final arrowP1 = Offset(
      end.dx - arrowSize * math.cos(angle - math.pi / 6),
      end.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    
    final arrowP2 = Offset(
      end.dx - arrowSize * math.cos(angle + math.pi / 6),
      end.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    
    canvas.drawLine(end, arrowP1, paint);
    canvas.drawLine(end, arrowP2, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    
    for (int i = 0; i < dashCount; i++) {
      final startOffset = start + (end - start) * (i * (dashWidth + dashSpace) / distance);
      final endOffset = start + (end - start) * ((i * (dashWidth + dashSpace) + dashWidth) / distance);
      canvas.drawLine(startOffset, endOffset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
