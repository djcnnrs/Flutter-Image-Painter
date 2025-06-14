import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'controller.dart';
import '_image_painter.dart';

/// FlutterFlow-compatible simple controller that manages state internally
/// without requiring external callbacks
class SimpleImagePainterController extends ChangeNotifier {
  late double _strokeWidth;
  late Color _color;
  late PaintMode _mode;
  late bool _fill;
  
  // Background properties
  BackgroundType _backgroundType = BackgroundType.none;
  String? _backgroundImageUrl;
  Color _backgroundColor = Colors.white;
  
  // Simplified toolbar config using individual booleans
  bool _showTextTool = true;
  bool _showShapesTools = true;
  bool _showBrushTool = true;
  bool _showColorTool = true;
  bool _showStrokeTool = true;
  bool _showUndoTool = true;
  bool _showClearTool = true;
  bool _showSaveTool = false;

  final List<Offset?> _offsets = [];
  final List<PaintInfo> _paintHistory = [];
  
  Offset? _start, _end;
  int _strokeMultiplier = 1;
  bool _paintInProgress = false;
  
  // Getters
  double get strokeWidth => _strokeWidth;
  Color get color => _color;
  PaintMode get mode => _mode;
  bool get fill => _fill;
  BackgroundType get backgroundType => _backgroundType;
  String? get backgroundImageUrl => _backgroundImageUrl;
  Color get backgroundColor => _backgroundColor;
  
  // Toolbar getters
  bool get showTextTool => _showTextTool;
  bool get showShapesTools => _showShapesTools;
  bool get showBrushTool => _showBrushTool;
  bool get showColorTool => _showColorTool;
  bool get showStrokeTool => _showStrokeTool;
  bool get showUndoTool => _showUndoTool;
  bool get showClearTool => _showClearTool;
  bool get showSaveTool => _showSaveTool;
  
  List<PaintInfo> get paintHistory => _paintHistory;
  List<Offset?> get offsets => _offsets;
  Offset? get start => _start;
  Offset? get end => _end;
  bool get busy => _paintInProgress;
  double get scaledStrokeWidth => _strokeWidth * _strokeMultiplier;

  SimpleImagePainterController({
    double strokeWidth = 4.0,
    Color color = Colors.red,
    PaintMode mode = PaintMode.freeStyle,
    bool fill = false,
    BackgroundType backgroundType = BackgroundType.none,
    String? backgroundImageUrl,
    Color backgroundColor = Colors.white,
    bool showTextTool = true,
    bool showShapesTools = true,
    bool showBrushTool = true,
    bool showColorTool = true,
    bool showStrokeTool = true,
    bool showUndoTool = true,
    bool showClearTool = true,
    bool showSaveTool = false,
  }) {
    _strokeWidth = strokeWidth;
    _color = color;
    _mode = mode;
    _fill = fill;
    _backgroundType = backgroundType;
    _backgroundImageUrl = backgroundImageUrl;
    _backgroundColor = backgroundColor;
    _showTextTool = showTextTool;
    _showShapesTools = showShapesTools;
    _showBrushTool = showBrushTool;
    _showColorTool = showColorTool;
    _showStrokeTool = showStrokeTool;
    _showUndoTool = showUndoTool;
    _showClearTool = showClearTool;
    _showSaveTool = showSaveTool;
  }

  Paint get brush => Paint()
    ..color = _color
    ..strokeWidth = _strokeWidth * _strokeMultiplier
    ..style = shouldFill ? PaintingStyle.fill : PaintingStyle.stroke;

  bool get shouldFill {
    if (mode == PaintMode.circle || mode == PaintMode.rect) {
      return _fill;
    } else {
      return false;
    }
  }

  bool get onTextUpdateMode =>
      _mode == PaintMode.text &&
      _paintHistory
          .where((element) => element.mode == PaintMode.text)
          .isNotEmpty;

  void setStrokeWidth(double val) {
    _strokeWidth = val;
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  void setMode(PaintMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setFill(bool fill) {
    _fill = fill;
    notifyListeners();
  }

  void addPaintInfo(PaintInfo paintInfo) {
    _paintHistory.add(paintInfo);
    notifyListeners();
  }

  void undo() {
    if (_paintHistory.isNotEmpty) {
      _paintHistory.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    if (_paintHistory.isNotEmpty) {
      _paintHistory.clear();
      notifyListeners();
    }
  }

  void addOffsets(Offset? offset) {
    _offsets.add(offset);
    notifyListeners();
  }

  void setStart(Offset? offset) {
    _start = offset;
    notifyListeners();
  }

  void setEnd(Offset? offset) {
    _end = offset;
    notifyListeners();
  }

  void resetStartAndEnd() {
    _start = null;
    _end = null;
    notifyListeners();
  }

  void setInProgress(bool val) {
    _paintInProgress = val;
    notifyListeners();
  }

  void setStrokeMultiplier(int multiplier) {
    _strokeMultiplier = multiplier;
    notifyListeners();
  }

  /// Simple export method that returns image bytes
  Future<Uint8List?> exportImage() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = SimpleDrawImage(controller: this);
      
      // Use default size if no specific size available
      const size = Size(800, 600);
      
      painter.paint(canvas, size);
      final convertedImage = await recorder
          .endRecording()
          .toImage(size.width.floor(), size.height.floor());
      final byteData =
          await convertedImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Export error: $e');
      return null;
    }
  }

  bool canFill() {
    return mode == PaintMode.circle || mode == PaintMode.rect;
  }
}

/// Simplified painter that works with SimpleImagePainterController
class SimpleDrawImage extends CustomPainter {
  final SimpleImagePainterController controller;

  SimpleDrawImage({required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    _drawBackground(canvas, size);

    // Draw paint history
    for (final item in controller.paintHistory) {
      final offsets = item.offsets;
      final painter = item.paint;
      
      switch (item.mode) {
        case PaintMode.rect:
          if (offsets.length >= 2 && offsets[0] != null && offsets[1] != null) {
            canvas.drawRect(Rect.fromPoints(offsets[0]!, offsets[1]!), painter);
          }
          break;
        case PaintMode.line:
          if (offsets.length >= 2 && offsets[0] != null && offsets[1] != null) {
            canvas.drawLine(offsets[0]!, offsets[1]!, painter);
          }
          break;
        case PaintMode.circle:
          if (offsets.length >= 2 && offsets[0] != null && offsets[1] != null) {
            final path = Path();
            path.addOval(
              Rect.fromCircle(
                  center: offsets[1]!,
                  radius: (offsets[0]! - offsets[1]!).distance),
            );
            canvas.drawPath(path, painter);
          }
          break;
        case PaintMode.freeStyle:
          for (int i = 0; i < offsets.length - 1; i++) {
            if (offsets[i] != null && offsets[i + 1] != null) {
              final path = Path()
                ..moveTo(offsets[i]!.dx, offsets[i]!.dy)
                ..lineTo(offsets[i + 1]!.dx, offsets[i + 1]!.dy);
              canvas.drawPath(path, painter..strokeCap = StrokeCap.round);
            } else if (offsets[i] != null && offsets[i + 1] == null) {
              canvas.drawPoints(PointMode.points, [offsets[i]!],
                  painter..strokeCap = StrokeCap.round);
            }
          }
          break;
        case PaintMode.text:
          if (item.text != null) {
            final textSpan = TextSpan(
              text: item.text,
              style: TextStyle(
                color: painter.color,
                fontSize: 6 * painter.strokeWidth,
                fontWeight: FontWeight.bold,
              ),
            );
            final textPainter = TextPainter(
              text: textSpan,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
            );
            textPainter.layout(minWidth: 0, maxWidth: size.width);
            final textOffset = offsets.isEmpty
                ? Offset(size.width / 2 - textPainter.width / 2,
                    size.height / 2 - textPainter.height / 2)
                : Offset(offsets[0]!.dx - textPainter.width / 2,
                    offsets[0]!.dy - textPainter.height / 2);
            textPainter.paint(canvas, textOffset);
          }
          break;
        default:
          break;
      }
    }
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
        // For FlutterFlow, network images should be handled externally
        canvas.drawRect(rect, Paint()..color = controller.backgroundColor);
        break;
      case BackgroundType.none:
        break;
    }
  }
  
  void _drawGraphPaper(Canvas canvas, Size size) {
    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;
    
    const gridSize = 20.0;
    
    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  void _drawLinedNotebook(Canvas canvas, Size size) {
    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 1;
    
    const lineSpacing = 30.0;
    
    // Draw horizontal lines
    for (double y = lineSpacing; y <= size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw left margin line
    final marginPaint = Paint()
      ..color = Colors.red.withOpacity(0.4)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(40, 0),
      Offset(40, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
