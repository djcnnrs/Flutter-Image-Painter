import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'enhanced_controller.dart';

/// Configuration for the Enhanced Image Painter
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
    this.defaultStrokeWidth = 4.0,
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

/// Enhanced Image Painter Widget with all functionality
class EnhancedImagePainter extends StatefulWidget {
  const EnhancedImagePainter({
    Key? key,
    required this.width,
    required this.height,
    required this.bgImage,
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
  late TransformationController _transformationController;
  late TextEditingController _textController;
  
  bool _isLoading = false;
  double _actualWidth = 0;
  double _actualHeight = 0;
  
  // Performance optimization variables
  DateTime _lastUpdateTime = DateTime.now();
  static const _updateThreshold = Duration(milliseconds: 16); // ~60 FPS
  List<Offset> _currentStroke = [];

  @override
  void initState() {
    super.initState();
    _controller = EnhancedImagePainterController();
    _transformationController = TransformationController();
    _textController = TextEditingController();
    
    // Set initial values from config
    _controller.setColor(widget.config.defaultColor);
    _controller.setStrokeWidth(widget.config.defaultStrokeWidth);
    
    _initializeCanvas();
  }

  Future<void> _initializeCanvas() async {
    setState(() => _isLoading = true);

    try {
      await _setupBackground();
    } catch (e) {
      print('Error initializing canvas: $e');
      _actualWidth = widget.width;
      _actualHeight = widget.height;
      _controller.setBackgroundType(BackgroundType.blankCanvas);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setupBackground() async {
    final bgImage = widget.bgImage?.trim();
    
    if (bgImage == null || bgImage.isEmpty || bgImage == "Blank Canvas") {
      _controller.setBackgroundType(BackgroundType.blankCanvas);
      _actualWidth = widget.width;
      _actualHeight = widget.height;
    } else if (bgImage == "Graph Paper") {
      _controller.setBackgroundType(BackgroundType.graphPaper);
      _actualWidth = widget.width;
      _actualHeight = widget.height;
    } else if (bgImage == "Lined Notebook") {
      _controller.setBackgroundType(BackgroundType.linedNotebook);
      _actualWidth = widget.width;
      _actualHeight = widget.height;
    } else {
      // Network image
      try {
        await _controller.loadBackgroundImage(bgImage);
        _controller.setBackgroundType(BackgroundType.networkImage);
        _controller.setBackgroundImageUrl(bgImage);
        
        if (_controller.backgroundImage != null) {
          _actualWidth = _controller.backgroundImage!.width.toDouble();
          _actualHeight = _controller.backgroundImage!.height.toDouble();
        } else {
          _actualWidth = widget.width;
          _actualHeight = widget.height;
        }
      } catch (e) {
        print('Failed to load network image: $e');
        _controller.setBackgroundType(BackgroundType.blankCanvas);
        _actualWidth = widget.width;
        _actualHeight = widget.height;
      }
    }
  }

  /// Public method to export the image
  Future<Uint8List?> exportImage() async {
    return await _controller.exportImage(Size(_actualWidth, _actualHeight));
  }

  /// Public method to undo last action
  void undoLastAction() {
    _controller.undo();
    if (widget.config.onUndo != null) widget.config.onUndo!();
  }

  /// Public method to clear canvas
  void clearCanvas() {
    _controller.clear();
    if (widget.config.onClear != null) widget.config.onClear!();
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: _actualWidth,
      height: _actualHeight + 60,
      child: Column(
        children: [
          if (widget.config.toolbarAtTop) _buildToolbar(),
          Expanded(child: _buildCanvas()),
          if (!widget.config.toolbarAtTop) _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return InteractiveViewer(
          transformationController: _transformationController,
          maxScale: 2.4,
          minScale: 1,
          panEnabled: _controller.mode == PaintMode.none,
          scaleEnabled: _controller.mode == PaintMode.none,
          onInteractionStart: _handleInteractionStart,
          onInteractionUpdate: _handleInteractionUpdate,
          onInteractionEnd: _handleInteractionEnd,
          child: Container(
            width: _actualWidth,
            height: _actualHeight,
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size(_actualWidth, _actualHeight),
                painter: EnhancedImageCustomPainter(
                  controller: _controller,
                  size: Size(_actualWidth, _actualHeight),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(4),
      color: widget.config.toolbarBackgroundColor ?? Colors.grey[200],
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeSelector(),
              if (widget.config.showColorTool) _buildColorSelector(),
              if (widget.config.showStrokeTool) _buildStrokeSelector(),
              if (widget.config.showFillOption && _controller.canFill()) ...[
                Checkbox(
                  value: _controller.fill,
                  onChanged: (val) => _controller.setFill(val ?? false),
                ),
                Text('Fill'),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: undoLastAction,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: clearCanvas,
                tooltip: 'Clear',
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () async {
                  if (widget.config.onSave != null) {
                    await widget.config.onSave!();
                  }
                },
                tooltip: 'Save',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeSelector() {
    return PopupMenuButton<PaintMode>(
      icon: Icon(_getModeIcon(_controller.mode)),
      tooltip: 'Drawing Mode',
      onSelected: (mode) {
        _controller.setMode(mode);
        // Don't automatically open text dialog - wait for user to click
      },
      itemBuilder: (context) => widget.config.enabledModes.map((mode) {
        return PopupMenuItem(
          value: mode,
          child: Row(
            children: [
              Icon(_getModeIcon(mode)),
              SizedBox(width: 8),
              Text(_getModeLabel(mode)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector() {
    return PopupMenuButton(
      icon: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _controller.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
      tooltip: 'Color',
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Wrap(
            children: [
              Colors.red, Colors.blue, Colors.green, Colors.yellow,
              Colors.orange, Colors.purple, Colors.pink, Colors.brown,
              Colors.black, Colors.grey, Colors.white,
            ].map((color) => GestureDetector(
              onTap: () {
                _controller.setColor(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 30,
                height: 30,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStrokeSelector() {
    return PopupMenuButton(
      icon: const Icon(Icons.brush),
      tooltip: 'Brush Size',
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setSliderState) => SizedBox(
              width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Stroke Width: ${_controller.strokeWidth.toInt()}'),
                  Slider(
                    value: _controller.strokeWidth,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) {
                      _controller.setStrokeWidth(value);
                      setSliderState(() {}); // Update the slider UI immediately
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleInteractionStart(ScaleStartDetails details) {
    final offset = _transformationController.toScene(details.localFocalPoint);
    _controller.setStart(offset);
    
    // Handle text mode specially
    if (_controller.mode == PaintMode.text) {
      _openTextDialog(offset);
      return;
    }
    
    _controller.addOffsets(offset);
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    final offset = _transformationController.toScene(details.localFocalPoint);
    
    // Lighter throttling for shape modes to enable real-time preview
    final now = DateTime.now();
    Duration threshold = _controller.mode == PaintMode.freeStyle ? _updateThreshold : Duration(milliseconds: 8);
    if (now.difference(_lastUpdateTime) < threshold) {
      return; // Skip this update for performance
    }
    _lastUpdateTime = now;
    
    _controller.setInProgress(true);
    
    if (_controller.start == null) {
      _controller.setStart(offset);
      if (_controller.mode == PaintMode.freeStyle) {
        _currentStroke.clear();
        _currentStroke.add(offset);
      }
    }
    _controller.setEnd(offset);
    
    if (_controller.mode == PaintMode.freeStyle) {
      _currentStroke.add(offset);
      _controller.addOffsets(offset);
    }
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    _controller.setInProgress(false);
    
    if (_controller.start != null && _controller.end != null) {
      if (_controller.mode == PaintMode.freeStyle) {
        _controller.addOffsets(null); // End stroke marker
        // Use the collected stroke points for better performance
        _addFreeStylePoints();
        _controller.offsets.clear();
        _currentStroke.clear();
      } else if (_controller.mode != PaintMode.text) {
        _addEndPoints();
      }
    }
    _controller.resetStartAndEnd();
  }

  void _addEndPoints() {
    _controller.addPaintInfo(
      PaintInfo(
        offsets: [_controller.start, _controller.end],
        mode: _controller.mode,
        color: _controller.color,
        strokeWidth: _controller.strokeWidth,
        fill: _controller.fill,
      ),
    );
  }

  void _addFreeStylePoints() {
    // Use the collected stroke points for better performance and consistency
    final strokePoints = _currentStroke.isNotEmpty ? List<Offset?>.from(_currentStroke) : [..._controller.offsets];
    
    _controller.addPaintInfo(
      PaintInfo(
        offsets: strokePoints,
        mode: PaintMode.freeStyle,
        color: _controller.color,
        strokeWidth: _controller.strokeWidth,
      ),
    );
  }

  void _openTextDialog([Offset? position]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Text'),
        content: TextField(
          controller: _textController,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_textController.text.isNotEmpty && position != null) {
                _controller.addPaintInfo(
                  PaintInfo(
                    mode: PaintMode.text,
                    text: _textController.text,
                    offsets: [position],
                    color: _controller.color,
                    strokeWidth: _controller.strokeWidth,
                  ),
                );
                _textController.clear();
              }
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(PaintMode mode) {
    switch (mode) {
      case PaintMode.none: return Icons.zoom_out_map;
      case PaintMode.freeStyle: return Icons.edit;
      case PaintMode.line: return Icons.horizontal_rule;
      case PaintMode.rect: return Icons.crop_free;
      case PaintMode.circle: return Icons.lens_outlined;
      case PaintMode.text: return Icons.text_format;
      case PaintMode.arrow: return Icons.arrow_forward;
      case PaintMode.dashedLine: return Icons.more_horiz;
    }
  }

  String _getModeLabel(PaintMode mode) {
    switch (mode) {
      case PaintMode.none: return 'Pan/Zoom';
      case PaintMode.freeStyle: return 'Draw';
      case PaintMode.line: return 'Line';
      case PaintMode.rect: return 'Rectangle';
      case PaintMode.circle: return 'Circle';
      case PaintMode.text: return 'Text';
      case PaintMode.arrow: return 'Arrow';
      case PaintMode.dashedLine: return 'Dashed Line';
    }
  }
}
