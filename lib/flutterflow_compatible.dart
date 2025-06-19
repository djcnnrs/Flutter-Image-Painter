import 'package:flutter/material.dart';

/// FlutterFlow Compatible Paint Modes - using old-style enums
enum FlutterFlowPaintMode { freeStyle, line, rect, circle }

/// FlutterFlow Compatible Image Painter Configuration
class FlutterFlowImagePainterConfig {
  final List<FlutterFlowPaintMode> enabledModes;
  final double defaultStrokeWidth;
  final Color defaultColor;
  final bool showColorTool;
  
  const FlutterFlowImagePainterConfig({
    this.enabledModes = const [FlutterFlowPaintMode.freeStyle, FlutterFlowPaintMode.line],
    this.defaultStrokeWidth = 3.0,
    this.defaultColor = Colors.black,
    this.showColorTool = true,
  });
}

/// FlutterFlow Compatible Simple Image Painter
class FlutterFlowImagePainter extends StatefulWidget {
  const FlutterFlowImagePainter({
    Key? key,
    this.width = 300.0,
    this.height = 200.0,
    this.config = const FlutterFlowImagePainterConfig(),
  }) : super(key: key);

  final double width;
  final double height;
  final FlutterFlowImagePainterConfig config;

  @override
  _FlutterFlowImagePainterState createState() => _FlutterFlowImagePainterState();
}

class _FlutterFlowImagePainterState extends State<FlutterFlowImagePainter> {
  FlutterFlowPaintMode _currentMode = FlutterFlowPaintMode.freeStyle;
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 3.0;
  List<Offset> _points = <Offset>[];

  @override
  void initState() {
    super.initState();
    _currentMode = widget.config.enabledModes.isNotEmpty 
        ? widget.config.enabledModes[0] 
        : FlutterFlowPaintMode.freeStyle;
    _currentColor = widget.config.defaultColor;
    _currentStrokeWidth = widget.config.defaultStrokeWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Simple toolbar
          Container(
            height: 50,
            color: Colors.grey[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.brush, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _currentMode = FlutterFlowPaintMode.freeStyle;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.palette, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _currentColor = _currentColor == Colors.black 
                          ? Colors.red 
                          : Colors.black;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _points.clear();
                    });
                  },
                ),
              ],
            ),
          ),
          // Canvas area
          Expanded(            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    _points.add(renderBox.globalToLocal(details.globalPosition));
                  }
                });
              },
              onPanEnd: (details) {
                _points.add(Offset.infinite);
              },
              child: CustomPaint(
                painter: _FlutterFlowPainter(_points, _currentColor, _currentStrokeWidth),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlutterFlowPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  _FlutterFlowPainter(this.points, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.infinite && points[i + 1] != Offset.infinite) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FlutterFlowPainter oldDelegate) => oldDelegate.points != points;
}
