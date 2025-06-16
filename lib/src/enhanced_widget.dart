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
    
    // Show feedback message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Canvas cleared'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );
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
      tooltip: 'Drawing Mode: ${_getModeLabel(_controller.mode)}',
      onSelected: (mode) {
        _controller.setMode(mode);
        // Open text dialog immediately when text mode is selected, just like original
        if (mode == PaintMode.text) {
          _openTextDialog();
        }
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
      icon: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.brush),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_controller.strokeWidth.toInt()}',
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
            ),
          ),
        ],
      ),
      tooltip: 'Brush Size: ${_controller.strokeWidth.toInt()}',
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setSliderState) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return SizedBox(
                    width: 220,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Stroke Width: ${_controller.strokeWidth.toInt()}px',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Slider(
                          value: _controller.strokeWidth,
                          min: 2,
                          max: 40,
                          divisions: 19,
                          label: '${_controller.strokeWidth.toInt()}px',
                          onChanged: (value) {
                            _controller.setStrokeWidth(value);
                            setSliderState(() {}); // Force immediate update
                          },
                        ),
                        // Visual preview of stroke width
                        Container(
                          height: 30,
                          child: Center(
                            child: Container(
                              width: 100,
                              height: _controller.strokeWidth,
                              decoration: BoxDecoration(
                                color: _controller.color,
                                borderRadius: BorderRadius.circular(_controller.strokeWidth / 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleInteractionStart(ScaleStartDetails details) {
    final offset = _transformationController.toScene(details.localFocalPoint);
    _controller.setStart(offset);
    _controller.addOffsets(offset);
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    final offset = _transformationController.toScene(details.localFocalPoint);
    
    _controller.setInProgress(true);
    if (_controller.start == null) {
      _controller.setStart(offset);
    }
    _controller.setEnd(offset);
    
    if (_controller.mode == PaintMode.freeStyle) {
      _controller.addOffsets(offset);
    }
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    _controller.setInProgress(false);
    
    if (_controller.start != null && _controller.end != null) {
      if (_controller.mode == PaintMode.freeStyle) {
        _controller.addOffsets(null); // End stroke marker
        _addFreeStylePoints();
        _controller.offsets.clear();
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
    _controller.addPaintInfo(
      PaintInfo(
        offsets: [..._controller.offsets],
        mode: PaintMode.freeStyle,
        color: _controller.color,
        strokeWidth: _controller.strokeWidth,
      ),
    );
  }

  void _openTextDialog() {
    final fontSize = 6 * _controller.strokeWidth;
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
              if (_textController.text.isNotEmpty) {
                _controller.addPaintInfo(
                  PaintInfo(
                    mode: PaintMode.text,
                    text: _textController.text,
                    offsets: [], // Empty offsets for now - positioning handled differently
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
