import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Core enums for the enhanced image painter
enum PaintMode { none, freeStyle, line, rect, circle, text, arrow, dashedLine }
enum BackgroundType { none, blankCanvas, graphPaper, linedNotebook, networkImage }

/// Paint information for storing drawing data
class PaintInfo {
  final List<Offset?> offsets;
  final PaintMode mode;
  final Color color;
  final double strokeWidth;
  final bool fill;
  final String? text;

  PaintInfo({
    required this.offsets,
    required this.mode,
    required this.color,
    required this.strokeWidth,
    this.fill = false,
    this.text,
  });
}

/// Enhanced Image Painter Controller with all functionality
class EnhancedImagePainterController extends ChangeNotifier {
  PaintMode _mode = PaintMode.freeStyle;
  Color _color = Colors.black;
  double _strokeWidth = 2.0;
  bool _fill = false;
  final List<PaintInfo> _paintHistory = [];
  final List<Offset?> _offsets = [];
  Offset? _start, _end;
  bool _inProgress = false;
  BackgroundType _backgroundType = BackgroundType.none;
  String? _backgroundImageUrl;
  Color _backgroundColor = Colors.white;
  ui.Image? _backgroundImage;
  bool _shouldRepaint = false;

  // Getters
  PaintMode get mode => _mode;
  Color get color => _color;
  double get strokeWidth => _strokeWidth;
  bool get fill => _fill;
  List<PaintInfo> get paintHistory => List.unmodifiable(_paintHistory);
  List<Offset?> get offsets => _offsets;
  Offset? get start => _start;
  Offset? get end => _end;
  bool get inProgress => _inProgress;
  BackgroundType get backgroundType => _backgroundType;
  String? get backgroundImageUrl => _backgroundImageUrl;
  Color get backgroundColor => _backgroundColor;
  ui.Image? get backgroundImage => _backgroundImage;
  bool get shouldRepaint => _shouldRepaint;

  // Setters
  void setMode(PaintMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void setFill(bool fill) {
    _fill = fill;
    notifyListeners();
  }

  void setBackgroundType(BackgroundType type) {
    _backgroundType = type;
    notifyListeners();
  }

  void setBackgroundImageUrl(String? url) {
    _backgroundImageUrl = url;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }

  void setBackgroundImage(ui.Image? image) {
    _backgroundImage = image;
    notifyListeners();
  }

  void setStart(Offset? offset) {
    _start = offset;
    _markForRepaint();
  }
  
  void setEnd(Offset? offset) {
    _end = offset;
    _markForRepaint();
  }
  
  void setInProgress(bool inProgress) {
    _inProgress = inProgress;
    _markForRepaint();
  }

  void _markForRepaint() {
    _shouldRepaint = true;
  }

  void _clearRepaintFlag() {
    _shouldRepaint = false;
  }

  void addOffsets(Offset? offset) {
    _offsets.add(offset);
    _markForRepaint();
    notifyListeners();
  }

  void addPaintInfo(PaintInfo info) {
    _paintHistory.add(info);
    _markForRepaint();
    notifyListeners();
  }

  void resetStartAndEnd() {
    _start = null;
    _end = null;
  }

  bool canFill() {
    return _mode == PaintMode.rect || _mode == PaintMode.circle;
  }

  void undo() {
    if (_paintHistory.isNotEmpty) {
      _paintHistory.removeLast();
      _markForRepaint();
      notifyListeners();
    }
  }

  void clear() {
    _paintHistory.clear();
    _offsets.clear();
    resetStartAndEnd();
    _markForRepaint();
    notifyListeners();
  }

  Future<Uint8List?> exportImage(Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = EnhancedImageCustomPainter(controller: this, size: size);
    painter.paint(canvas, size);
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> loadBackgroundImage(String url) async {
    try {
      final completer = Completer<ui.Image>();
      final img = NetworkImage(url);
      img.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) {
          completer.complete(info.image);
        }, onError: (error, stackTrace) {
          completer.completeError(error);
        })
      );
      _backgroundImage = await completer.future;
      notifyListeners();
    } catch (e) {
      print('Failed to load background image: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Enhanced Custom Painter with all drawing capabilities
class EnhancedImageCustomPainter extends CustomPainter {
  final EnhancedImagePainterController controller;
  final Size size;

  EnhancedImageCustomPainter({required this.controller, required this.size});

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    
    for (final info in controller.paintHistory) {
      _drawPaintInfo(canvas, info);
    }
    
    if (controller.inProgress && controller.start != null && controller.end != null) {
      _drawCurrentStroke(canvas);
    }
    
    // Clear the repaint flag after painting
    controller._clearRepaintFlag();
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    switch (controller.backgroundType) {
      case BackgroundType.blankCanvas:
        canvas.drawRect(rect, Paint()..color = controller.backgroundColor);
        break;
      case BackgroundType.graphPaper:
        _drawGraphPaper(canvas, size);
        break;
      case BackgroundType.linedNotebook:
        _drawLinedNotebook(canvas, size);
        break;
      case BackgroundType.networkImage:
        if (controller.backgroundImage != null) {
          canvas.drawImageRect(
            controller.backgroundImage!,
            Rect.fromLTWH(0, 0, controller.backgroundImage!.width.toDouble(), controller.backgroundImage!.height.toDouble()),
            rect,
            Paint(),
          );
        }
        break;
      case BackgroundType.none:
      default:
        canvas.drawRect(rect, Paint()..color = Colors.white);
        break;
    }
  }

  void _drawGraphPaper(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    const gridSize = 20.0;
    
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLinedNotebook(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    const lineSpacing = 25.0;
    
    for (double y = lineSpacing; y <= size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawPaintInfo(Canvas canvas, PaintInfo info) {
    final paint = Paint()
      ..color = info.color
      ..strokeWidth = info.strokeWidth
      ..style = info.fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (info.mode) {
      case PaintMode.freeStyle:
        _drawFreeStyle(canvas, info.offsets, paint);
        break;
      case PaintMode.line:
        if (info.offsets.length >= 2) {
          canvas.drawLine(info.offsets[0]!, info.offsets[1]!, paint);
        }
        break;
      case PaintMode.rect:
        if (info.offsets.length >= 2) {
          final rect = Rect.fromPoints(info.offsets[0]!, info.offsets[1]!);
          canvas.drawRect(rect, paint);
        }
        break;
      case PaintMode.circle:
        if (info.offsets.length >= 2) {
          final center = info.offsets[0]!;
          final radius = (info.offsets[1]! - center).distance;
          canvas.drawCircle(center, radius, paint);
        }
        break;
      case PaintMode.text:
        if (info.text != null && info.offsets.isNotEmpty) {
          _drawText(canvas, info.text!, info.offsets[0]!, info.color, info.strokeWidth);
        }
        break;
      case PaintMode.arrow:
        if (info.offsets.length >= 2) {
          _drawArrow(canvas, info.offsets[0]!, info.offsets[1]!, paint);
        }
        break;
      case PaintMode.dashedLine:
        if (info.offsets.length >= 2) {
          _drawDashedLine(canvas, info.offsets[0]!, info.offsets[1]!, paint);
        }
        break;
      default:
        break;
    }
  }

  void _drawFreeStyle(Canvas canvas, List<Offset?> offsets, Paint paint) {
    if (offsets.isEmpty) return;
    
    final path = Path();
    bool hasMovedTo = false;
    
    for (int i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      if (offset == null) {
        hasMovedTo = false;
      } else {
        if (!hasMovedTo) {
          path.moveTo(offset.dx, offset.dy);
          hasMovedTo = true;
        } else {
          // Use quadratic bezier curves for smoother lines
          if (i > 0 && offsets[i - 1] != null) {
            final prevOffset = offsets[i - 1]!;
            final midPoint = Offset(
              (prevOffset.dx + offset.dx) / 2,
              (prevOffset.dy + offset.dy) / 2,
            );
            path.quadraticBezierTo(prevOffset.dx, prevOffset.dy, midPoint.dx, midPoint.dy);
          } else {
            path.lineTo(offset.dx, offset.dy);
          }
        }
      }
    }
    
    canvas.drawPath(path, paint);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize * 4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    
    const arrowHeadLength = 20.0;
    const arrowHeadAngle = 0.5;
    
    final direction = (end - start);
    final length = direction.distance;
    if (length <= 0) return;
    
    final unitVector = direction / length;
    final angle = math.atan2(unitVector.dy, unitVector.dx);
    
    final arrowHead1 = end - Offset(
      arrowHeadLength * math.cos(angle - arrowHeadAngle),
      arrowHeadLength * math.sin(angle - arrowHeadAngle),
    );
    final arrowHead2 = end - Offset(
      arrowHeadLength * math.cos(angle + arrowHeadAngle),
      arrowHeadLength * math.sin(angle + arrowHeadAngle),
    );
    
    canvas.drawLine(end, arrowHead1, paint);
    canvas.drawLine(end, arrowHead2, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 10.0;
    const dashGap = 5.0;
    
    final direction = end - start;
    final distance = direction.distance;
    if (distance <= 0) return;
    
    final unitVector = direction / distance;
    
    double currentDistance = 0;
    bool drawDash = true;
    
    while (currentDistance < distance) {
      final segmentLength = drawDash ? dashLength : dashGap;
      final nextDistance = math.min(currentDistance + segmentLength, distance);
      
      if (drawDash) {
        final segmentStart = start + unitVector * currentDistance;
        final segmentEnd = start + unitVector * nextDistance;
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }
      
      currentDistance = nextDistance;
      drawDash = !drawDash;
    }
  }

  void _drawCurrentStroke(Canvas canvas) {
    final paint = Paint()
      ..color = controller.color
      ..strokeWidth = controller.strokeWidth
      ..style = controller.fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (controller.mode) {
      case PaintMode.line:
        canvas.drawLine(controller.start!, controller.end!, paint);
        break;
      case PaintMode.rect:
        final rect = Rect.fromPoints(controller.start!, controller.end!);
        canvas.drawRect(rect, paint);
        break;
      case PaintMode.circle:
        final radius = (controller.end! - controller.start!).distance;
        canvas.drawCircle(controller.start!, radius, paint);
        break;
      case PaintMode.freeStyle:
        // For freestyle, draw the current stroke being drawn
        if (controller.offsets.isNotEmpty) {
          _drawFreeStyle(canvas, controller.offsets, paint);
        }
        break;
      case PaintMode.arrow:
        _drawArrow(canvas, controller.start!, controller.end!, paint);
        break;
      case PaintMode.dashedLine:
        _drawDashedLine(canvas, controller.start!, controller.end!, paint);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! EnhancedImageCustomPainter) return true;
    
    return controller.shouldRepaint ||
           oldDelegate.controller.paintHistory.length != controller.paintHistory.length ||
           oldDelegate.controller.inProgress != controller.inProgress ||
           oldDelegate.controller.start != controller.start ||
           oldDelegate.controller.end != controller.end ||
           oldDelegate.controller.offsets.length != controller.offsets.length;
  }
}
