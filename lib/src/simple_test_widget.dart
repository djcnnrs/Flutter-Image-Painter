import 'package:flutter/material.dart';

/// Minimal enums for testing
enum PaintMode { freeStyle, line }

/// Simple paint data
class SimplePaintInfo {
  final List<Offset> offsets;
  final PaintMode mode;
  final Color color;
  final double strokeWidth;

  SimplePaintInfo({
    required this.offsets,
    required this.mode,
    required this.color,
    required this.strokeWidth,
  });
}

/// Minimal controller for testing FlutterFlow compatibility
class SimpleImagePainterController extends ChangeNotifier {
  final List<SimplePaintInfo> _paintHistory = [];
  PaintMode _mode = PaintMode.freeStyle;
  Color _color = Colors.black;
  double _strokeWidth = 3.0;
  
  List<SimplePaintInfo> get paintHistory => _paintHistory;
  PaintMode get mode => _mode;
  Color get color => _color;
  double get strokeWidth => _strokeWidth;
  
  void setMode(PaintMode mode) {
    _mode = mode;
    notifyListeners();
  }
  
  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }
  
  void addStroke(List<Offset> offsets) {
    _paintHistory.add(SimplePaintInfo(
      offsets: offsets,
      mode: _mode,
      color: _color,
      strokeWidth: _strokeWidth,
    ));
    notifyListeners();
  }
  
  void clear() {
    _paintHistory.clear();
    notifyListeners();
  }
}

/// Minimal config
class SimpleImagePainterConfig {
  final List<PaintMode> enabledModes;
  final double defaultStrokeWidth;
  final Color defaultColor;
  
  const SimpleImagePainterConfig({
    this.enabledModes = const [PaintMode.freeStyle, PaintMode.line],
    this.defaultStrokeWidth = 3.0,
    this.defaultColor = Colors.black,
  });
}

/// Minimal painter widget - testing FlutterFlow compatibility
class SimpleImagePainter extends StatefulWidget {
  const SimpleImagePainter({
    Key? key,
    required this.width,
    required this.height,
    this.config = const SimpleImagePainterConfig(),
  }) : super(key: key);

  final double width;
  final double height;
  final SimpleImagePainterConfig config;

  @override
  State<SimpleImagePainter> createState() => SimpleImagePainterState();
}

class SimpleImagePainterState extends State<SimpleImagePainter> {
  late SimpleImagePainterController _controller;
  List<Offset> _currentStroke = [];

  @override
  void initState() {
    super.initState();
    _controller = SimpleImagePainterController();
    _controller.setColor(widget.config.defaultColor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: Column(
        children: [
          // Simple toolbar
          Container(
            height: 50,
            color: Colors.grey[800],
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.brush, color: Colors.white),
                  onPressed: () => _controller.setMode(PaintMode.freeStyle),
                ),
                IconButton(
                  icon: Icon(Icons.remove, color: Colors.white),
                  onPressed: () => _controller.setMode(PaintMode.line),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.white),
                  onPressed: () => _controller.clear(),
                ),
              ],
            ),
          ),
          // Canvas
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                _currentStroke = [details.localPosition];
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentStroke.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                _controller.addStroke(List.from(_currentStroke));
                _currentStroke = [];
              },
              child: CustomPaint(
                painter: SimpleCanvasPainter(_controller, _currentStroke),
                size: Size(widget.width, widget.height - 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal custom painter
class SimpleCanvasPainter extends CustomPainter {
  final SimpleImagePainterController controller;
  final List<Offset> currentStroke;

  SimpleCanvasPainter(this.controller, this.currentStroke) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final info in controller.paintHistory) {
      final paint = Paint()
        ..color = info.color
        ..strokeWidth = info.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < info.offsets.length - 1; i++) {
        canvas.drawLine(info.offsets[i], info.offsets[i + 1], paint);
      }
    }

    // Draw current stroke
    if (currentStroke.length > 1) {
      final paint = Paint()
        ..color = controller.color
        ..strokeWidth = controller.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
