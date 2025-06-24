import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum PaintMode {
  none,
  freeStyle,
  arrow,
  line,
  rect,
  circle,
  dashedLine,
  text,
}

class PaintInfo {
  final Offset offset;
  final Paint paint;
  final PaintMode mode;
  final Offset? offset2;
  final String? text;

  PaintInfo({
    required this.offset,
    required this.paint,
    required this.mode,
    this.offset2,
    this.text,
  });
}

class EnhancedImagePainterController extends ChangeNotifier {
  Color _paintColor = Colors.black;
  double _strokeWidth = 3.0;
  PaintMode _paintMode = PaintMode.freeStyle;
  final List<PaintInfo> _paintHistory = <PaintInfo>[];
  final List<List<Offset>> _paths = <List<Offset>>[];
  ui.Image? _backgroundImage;

  // Getters
  Color get color => _paintColor;
  double get strokeWidth => _strokeWidth;
  PaintMode get mode => _paintMode;
  List<PaintInfo> get paintHistory => List.unmodifiable(_paintHistory);
  List<List<Offset>> get paths => List.unmodifiable(_paths);
  ui.Image? get backgroundImage => _backgroundImage;

  // Setters
  void setColor(Color color) {
    _paintColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void setMode(PaintMode mode) {
    _paintMode = mode;
    notifyListeners();
  }

  void setBackgroundImage(ui.Image? image) {
    _backgroundImage = image;
    notifyListeners();
  }

  // Drawing methods
  void addPoint(Offset point, {Offset? endPoint, String? text}) {
    final paint = Paint()
      ..color = _paintColor
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _paintHistory.add(PaintInfo(
      offset: point,
      paint: paint,
      mode: _paintMode,
      offset2: endPoint,
      text: text,
    ));

    if (_paintMode == PaintMode.freeStyle) {
      if (_paths.isEmpty || _paths.last.isEmpty) {
        _paths.add([point]);
      } else {
        _paths.last.add(point);
      }
    }

    notifyListeners();
  }

  void startPath(Offset point) {
    if (_paintMode == PaintMode.freeStyle) {
      _paths.add([point]);
    }
  }

  void endPath() {
    // Path ended, ready for next path
  }

  void undo() {
    if (_paintHistory.isNotEmpty) {
      _paintHistory.removeLast();
      // Rebuild paths from history
      _rebuildPaths();
      notifyListeners();
    }
  }

  void clear() {
    _paintHistory.clear();
    _paths.clear();
    notifyListeners();
  }

  void _rebuildPaths() {
    _paths.clear();
    List<Offset> currentPath = [];
    
    for (var info in _paintHistory) {
      if (info.mode == PaintMode.freeStyle) {
        if (currentPath.isEmpty) {
          currentPath = [info.offset];
          _paths.add(currentPath);
        } else {
          currentPath.add(info.offset);
        }
      } else {
        if (currentPath.isNotEmpty) {
          currentPath = [];
        }
      }
    }
  }

  Future<Uint8List?> exportImage(double width, double height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background if available
    if (_backgroundImage != null) {
      canvas.drawImageRect(
        _backgroundImage!,
        Rect.fromLTWH(0, 0, _backgroundImage!.width.toDouble(), _backgroundImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, width, height),
        Paint(),
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()..color = Colors.white,
      );
    }

    // Draw all paint history
    for (var info in _paintHistory) {
      _drawPaintInfo(canvas, info);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData?.buffer.asUint8List();
  }

  void _drawPaintInfo(Canvas canvas, PaintInfo info) {
    switch (info.mode) {
      case PaintMode.freeStyle:
        // Handled by paths
        break;
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
          final radius = (info.offset2! - info.offset).distance / 2;
          final center = Offset(
            (info.offset.dx + info.offset2!.dx) / 2,
            (info.offset.dy + info.offset2!.dy) / 2,
          );
          canvas.drawCircle(center, radius, info.paint);
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
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, info.offset);
        }
        break;
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
}