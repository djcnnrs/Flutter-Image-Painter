import 'package:flutter/material.dart';
import 'enhanced_controller.dart';

/// Simplified Image Painter Config for FlutterFlow
class SimpleImagePainterConfig {
  final List<PaintMode> enabledModes;
  final double defaultStrokeWidth;
  final Color defaultColor;
  final bool showColorTool;
  
  const SimpleImagePainterConfig({
    this.enabledModes = const [PaintMode.freeStyle, PaintMode.line, PaintMode.rect, PaintMode.circle],
    this.defaultStrokeWidth = 3.0,
    this.defaultColor = Colors.red,
    this.showColorTool = true,
  });
}

/// Simplified Image Painter Widget for FlutterFlow
class SimpleImagePainter extends StatefulWidget {
  const SimpleImagePainter({
    Key? key,
    required this.width,
    required this.height,
    this.bgImage,
    this.config = const SimpleImagePainterConfig(),
  }) : super(key: key);

  final double width;
  final double height;
  final String? bgImage;
  final SimpleImagePainterConfig config;

  @override
  State<SimpleImagePainter> createState() => SimpleImagePainterState();
}

class SimpleImagePainterState extends State<SimpleImagePainter> {
  late EnhancedImagePainterController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = EnhancedImagePainterController();
    _controller.setColor(widget.config.defaultColor);
    _controller.setStrokeWidth(widget.config.defaultStrokeWidth);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
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
                IconButton(
                  icon: Icon(Icons.crop_square, color: Colors.white),
                  onPressed: () => _controller.setMode(PaintMode.rect),
                ),
                IconButton(
                  icon: Icon(Icons.circle_outlined, color: Colors.white),
                  onPressed: () => _controller.setMode(PaintMode.circle),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.undo, color: Colors.white),
                  onPressed: () => _controller.undo(),
                ),
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
                _controller.startStroke(details.localPosition);
              },
              onPanUpdate: (details) {
                _controller.updateStroke(details.localPosition);
              },
              onPanEnd: (details) {
                _controller.endStroke();
              },
              child: CustomPaint(
                painter: EnhancedImagePainterPainter(
                  controller: _controller,
                  size: Size(widget.width, widget.height),
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
