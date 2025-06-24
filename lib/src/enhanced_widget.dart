import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'enhanced_controller.dart';
import 'enhanced_painter.dart';

class EnhancedImagePainterConfig {
  final List<PaintMode> enabledModes;
  final double defaultStrokeWidth;
  final Color defaultColor;
  final bool showColorTool;
  final bool showStrokeTool;
  final bool showFillOption;
  final bool toolbarAtTop;
  final Color? toolbarBackgroundColor;
  final Future<void> Function()? onSave;
  final void Function()? onUndo;
  final void Function()? onClear;

  const EnhancedImagePainterConfig({
    this.enabledModes = const [PaintMode.freeStyle, PaintMode.line, PaintMode.rect, PaintMode.circle, PaintMode.text],
    this.defaultStrokeWidth = 2.0,
    this.defaultColor = Colors.red,
    this.showColorTool = true,
    this.showStrokeTool = true,
    this.showFillOption = true,
    this.toolbarAtTop = false,
    this.toolbarBackgroundColor,
    this.onSave,
    this.onUndo,
    this.onClear,
  });
}

class EnhancedImagePainter extends StatefulWidget {
  const EnhancedImagePainter({
    Key? key,
    required this.width,
    required this.height,
    this.bgImage,
    this.config = const EnhancedImagePainterConfig(),
  }) : super(key: key);

  final double width;
  final double height;
  final String? bgImage;
  final EnhancedImagePainterConfig config;

  @override
  EnhancedImagePainterState createState() => EnhancedImagePainterState();
}

class EnhancedImagePainterState extends State<EnhancedImagePainter> {
  late EnhancedImagePainterController _controller;
  late TextEditingController _textController;
  
  Offset? _startPoint;
  Offset? _currentPoint;
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    _controller = EnhancedImagePainterController();
    _textController = TextEditingController();
    
    // Initialize with config
    _controller.setColor(widget.config.defaultColor);
    _controller.setStrokeWidth(widget.config.defaultStrokeWidth);
    
    // Load background image if provided
    if (widget.bgImage != null && widget.bgImage!.isNotEmpty) {
      _loadNetworkImage(widget.bgImage!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadNetworkImage(String url) async {
    try {
      final imageProvider = NetworkImage(url);
      final imageStream = imageProvider.resolve(const ImageConfiguration());
      final completer = Completer<ImageInfo>();
      
      imageStream.addListener(ImageStreamListener((info, _) {
        if (!completer.isCompleted) {
          completer.complete(info);
        }
      }));
      
      final imageInfo = await completer.future;
      _controller.setBackgroundImage(imageInfo.image);
    } catch (e) {
      // Handle error silently for FlutterFlow compatibility
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.config.toolbarAtTop) _buildToolbar(),
        Expanded(
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTap: _onTap,
                child: CustomPaint(
                  size: Size(widget.width, widget.height),
                  painter: EnhancedImagePainter(controller: _controller),
                ),
              ),
            ),
          ),
        ),
        if (!widget.config.toolbarAtTop) _buildToolbar(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: widget.config.toolbarBackgroundColor ?? Colors.grey[200],
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          // Mode selection
          PopupMenuButton<PaintMode>(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(_getModeIcon(_controller.mode)),
            ),
            itemBuilder: (context) => widget.config.enabledModes
                .map((mode) => PopupMenuItem(
                      value: mode,
                      child: Row(
                        children: [
                          Icon(_getModeIcon(mode)),
                          const SizedBox(width: 8),
                          Text(_getModeLabel(mode)),
                        ],
                      ),
                    ))
                .toList(),
            onSelected: (mode) {
              _controller.setMode(mode);
              if (mode == PaintMode.text) {
                _showTextDialog();
              }
            },
          ),
          
          const SizedBox(width: 8),
          
          // Color picker
          if (widget.config.showColorTool)
            GestureDetector(
              onTap: _showColorPicker,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _controller.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            ),
          
          const SizedBox(width: 8),
          
          // Stroke width
          if (widget.config.showStrokeTool) ...[
            Icon(Icons.brush, size: 16, color: Colors.grey[600]),
            Expanded(
              child: Slider(
                value: _controller.strokeWidth,
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (value) => _controller.setStrokeWidth(value),
              ),
            ),
          ],
          
          const Spacer(),
          
          // Actions
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () {
              _controller.undo();
              widget.config.onUndo?.call();
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              widget.config.onClear?.call();
            },
          ),
          if (widget.config.onSave != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => widget.config.onSave?.call(),
            ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_controller.mode == PaintMode.none) return;
    
    _startPoint = details.localPosition;
    _currentPoint = details.localPosition;
    _isDrawing = true;
    
    if (_controller.mode == PaintMode.freeStyle) {
      _controller.startPath(details.localPosition);
      _controller.addPoint(details.localPosition);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing || _controller.mode == PaintMode.none) return;
    
    _currentPoint = details.localPosition;
    
    if (_controller.mode == PaintMode.freeStyle) {
      _controller.addPoint(details.localPosition);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing || _controller.mode == PaintMode.none) return;
    
    _isDrawing = false;
    
    if (_startPoint != null && _currentPoint != null && _controller.mode != PaintMode.freeStyle) {
      _controller.addPoint(_startPoint!, endPoint: _currentPoint!);
    }
    
    if (_controller.mode == PaintMode.freeStyle) {
      _controller.endPath();
    }
    
    _startPoint = null;
    _currentPoint = null;
  }

  void _onTap() {
    if (_controller.mode == PaintMode.text) {
      _showTextDialog();
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Colors.black,
              Colors.red,
              Colors.green,
              Colors.blue,
              Colors.orange,
              Colors.purple,
              Colors.pink,
              Colors.teal,
              Colors.brown,
              Colors.grey,
            ].map((color) => GestureDetector(
              onTap: () {
                _controller.setColor(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color == _controller.color 
                        ? Colors.white 
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _showTextDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Text'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(
            hintText: 'Type your text here...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                final centerX = widget.width / 2;
                final centerY = widget.height / 2;
                
                _controller.addPoint(
                  Offset(centerX, centerY),
                  text: _textController.text,
                );
                
                _textController.clear();
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(PaintMode mode) {
    switch (mode) {
      case PaintMode.none:
        return Icons.pan_tool;
      case PaintMode.freeStyle:
        return Icons.edit;
      case PaintMode.line:
        return Icons.horizontal_rule;
      case PaintMode.rect:
        return Icons.crop_free;
      case PaintMode.circle:
        return Icons.circle_outlined;
      case PaintMode.text:
        return Icons.text_fields;
      case PaintMode.arrow:
        return Icons.arrow_right_alt;
      case PaintMode.dashedLine:
        return Icons.more_horiz;
    }
  }

  String _getModeLabel(PaintMode mode) {
    switch (mode) {
      case PaintMode.none:
        return 'Pan/Zoom';
      case PaintMode.freeStyle:
        return 'Free Draw';
      case PaintMode.line:
        return 'Line';
      case PaintMode.rect:
        return 'Rectangle';
      case PaintMode.circle:
        return 'Circle';
      case PaintMode.text:
        return 'Text';
      case PaintMode.arrow:
        return 'Arrow';
      case PaintMode.dashedLine:
        return 'Dashed Line';
    }
  }

  /// Export the current drawing as PNG bytes
  Future<Uint8List?> exportImage() async {
    return await _controller.exportImage(widget.width, widget.height);
  }
}