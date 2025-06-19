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
  
  // Text positioning
  Offset? _pendingTextPosition;
  
  // Text editing
  int? _editingTextIndex;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;

  @override
  void initState() {
    super.initState();
    
    try {
      _controller = EnhancedImagePainterController();
      _transformationController = TransformationController();
      _textController = TextEditingController();
      
      // Set initial values from config
      _controller.setColor(widget.config.defaultColor);
      _controller.setStrokeWidth(widget.config.defaultStrokeWidth);
      
      // Initialize canvas with proper background
      _initializeCanvas();
      
    } catch (e) {
      print('Error in initState: $e');
      rethrow;
    }
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
        _controller.setBackgroundType(BackgroundType.blankCanvas);
        _actualWidth = widget.width;
        _actualHeight = widget.height;
      }
    }
  }

  /// Public method to export the image
  Future<Uint8List?> exportImage({bool autoCrop = true}) async {
    return await _controller.exportImage(Size(_actualWidth, _actualHeight), autoCrop: autoCrop);
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
        return GestureDetector(
          onTap: () {
            // Handle potential text editing (double-click detection)
            _handleTapForTextEditing();
          },
          onPanStart: (details) {
            final offset = details.localPosition;
            
            // Store tap info for double-click detection
            _lastTapPosition = offset;
            _lastTapTime = DateTime.now();
            
            // Handle text mode differently - store position and open dialog
            if (_controller.mode == PaintMode.text) {
              _pendingTextPosition = offset;
              _openTextDialog();
              return;
            }
            
            _controller.setStart(offset);
            _controller.setInProgress(true);
            
            if (_controller.mode == PaintMode.freeStyle) {
              _controller.addOffsets(offset);
            } else {
              // For shape modes, set the end position same as start initially for immediate preview
              _controller.setEnd(offset);
            }
          },
          onPanUpdate: (details) {
            final offset = details.localPosition;
            
            // Ensure we're still in progress
            _controller.setInProgress(true);
            
            // Always update the end position for real-time preview
            _controller.setEnd(offset);
            
            if (_controller.mode == PaintMode.freeStyle) {
              _controller.addOffsets(offset);
            }
          },
          onPanEnd: (details) {
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
          },
          child: Container(
            width: _actualWidth,
            height: _actualHeight,
            color: Colors.white,
            child: CustomPaint(
              size: Size(_actualWidth, _actualHeight),
              painter: EnhancedImageCustomPainter(
                controller: _controller,
                size: Size(_actualWidth, _actualHeight),
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
      color: widget.config.toolbarBackgroundColor ?? Colors.grey[800], // Darker background
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _controller.fill,
                      onChanged: (val) => _controller.setFill(val ?? false),
                      fillColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.blue;
                        }
                        return Colors.white;
                      }),
                    ),
                    Text('Fill', style: TextStyle(color: Colors.white)), // White text for dark background
                  ],
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.undo, color: Colors.white),
                onPressed: undoLastAction,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: clearCanvas,
                tooltip: 'Clear',
              ),
              IconButton(
                icon: Icon(Icons.save, color: _controller.paintHistory.isEmpty ? Colors.grey : Colors.white),
                onPressed: _controller.paintHistory.isEmpty ? null : () async {
                  if (widget.config.onSave != null) {
                    await widget.config.onSave!();
                  }
                },
                tooltip: _controller.paintHistory.isEmpty ? 'Canvas is empty' : 'Save',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeSelector() {
    return PopupMenuButton<PaintMode>(
      icon: Icon(_getModeIcon(_controller.mode), color: Colors.white),
      tooltip: 'Drawing Mode: ${_getModeLabel(_controller.mode)}',
      onSelected: (mode) {
        _controller.setMode(mode);
        // Show instruction for text mode
        if (mode == PaintMode.text) {
          _showTextModeInstructions();
        }
      },
      itemBuilder: (context) {
        return widget.config.enabledModes.map((mode) {
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
        }).toList();
      },
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
          const Icon(Icons.brush, color: Colors.white),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StrokeSliderWidget(
                controller: _controller,
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  /// Handle tap events for potential text editing
  void _handleTapForTextEditing() {
    if (_lastTapPosition == null || _lastTapTime == null) return;
    
    // If we're in text repositioning mode, handle that first
    if (_editingTextIndex != null) {
      _pendingTextPosition = _lastTapPosition;
      _updateExistingText();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      return;
    }
    
    final now = DateTime.now();
    final timeDiff = now.difference(_lastTapTime!).inMilliseconds;
    
    // Check for double-click (within 500ms)
    if (timeDiff < 500) {
      final textIndex = _findTextAtPosition(_lastTapPosition!);
      if (textIndex != null) {
        _editTextAtIndex(textIndex);
      }
    }
  }

  /// Edit existing text at the given index
  void _editTextAtIndex(int index) {
    final textInfo = _controller.paintHistory[index];
    if (textInfo.mode != PaintMode.text || textInfo.text == null) return;
    
    _editingTextIndex = index;
    _textController.text = textInfo.text!;
    _pendingTextPosition = textInfo.offsets.isNotEmpty ? textInfo.offsets[0] : Offset.zero;
    
    _openTextEditDialog();
  }

  void _openTextDialog() {
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
            onPressed: () {
              _pendingTextPosition = null; // Clear pending position
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_textController.text.isNotEmpty && _pendingTextPosition != null) {
                _controller.addPaintInfo(
                  PaintInfo(
                    mode: PaintMode.text,
                    text: _textController.text,
                    offsets: [_pendingTextPosition!], // Use the stored click position
                    color: _controller.color,
                    strokeWidth: _controller.strokeWidth,
                  ),
                );
                _textController.clear();
                _pendingTextPosition = null; // Clear pending position
              }
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _openTextEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Text'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              autofocus: true,
              decoration: InputDecoration(hintText: 'Edit text'),
            ),
            SizedBox(height: 16),
            Text(
              'Tap anywhere on the canvas to reposition the text',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _editingTextIndex = null;
              _pendingTextPosition = null;
              _textController.clear();
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Start position selection mode
              _startTextRepositioning();
            },
            child: Text('Reposition'),
          ),
          TextButton(
            onPressed: () {
              if (_textController.text.isNotEmpty && _editingTextIndex != null) {
                _updateExistingText();
              }
              Navigator.pop(context);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  /// Start text repositioning mode
  void _startTextRepositioning() {
    // Switch to a temporary mode for repositioning
    final originalMode = _controller.mode;
    _controller.setMode(PaintMode.none); // Disable drawing
    
    _showTextPositionInstructions(
      onCancel: () {
        _editingTextIndex = null;
        _pendingTextPosition = null;
        _textController.clear();
        _controller.setMode(originalMode);
      },
    );
  }

  /// Show text mode instructions when user selects text mode
  void _showTextModeInstructions() {
    _showTextPositionInstructions();
  }

  /// Show instructions for text positioning (used for both new text and repositioning)
  void _showTextPositionInstructions({VoidCallback? onCancel}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tap anywhere to place the text at that location'),
        duration: Duration(seconds: 4),
        action: onCancel != null 
          ? SnackBarAction(
              label: 'Cancel',
              onPressed: onCancel,
            )
          : null,
      ),
    );
  }

  /// Update existing text with new content and/or position
  void _updateExistingText() {
    if (_editingTextIndex == null) return;
    
    final newText = _textController.text;
    final currentInfo = _controller.paintHistory[_editingTextIndex!];
    final newPosition = _pendingTextPosition ?? (currentInfo.offsets.isNotEmpty ? currentInfo.offsets[0] : Offset.zero);
    
    // Create updated PaintInfo
    final updatedInfo = PaintInfo(
      mode: PaintMode.text,
      text: newText,
      offsets: [newPosition],
      color: currentInfo.color,
      strokeWidth: currentInfo.strokeWidth,
    );
    
    // Replace the existing text in history
    _controller.paintHistory[_editingTextIndex!] = updatedInfo;
    _controller.notifyListeners();
    
    // Clean up
    _editingTextIndex = null;
    _pendingTextPosition = null;
    _textController.clear();
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

  /// Check if a tap position hits any existing text
  int? _findTextAtPosition(Offset position) {
    for (int i = _controller.paintHistory.length - 1; i >= 0; i--) {
      final info = _controller.paintHistory[i];
      if (info.mode == PaintMode.text && info.text != null && info.offsets.isNotEmpty) {
        final textPosition = info.offsets[0]!;
        final textBounds = _calculateTextBounds(info.text!, textPosition, info.strokeWidth * 4);
        
        if (textBounds.contains(position)) {
          return i;
        }
      }
    }
    return null;
  }

  /// Calculate the bounds of a text element
  Rect _calculateTextBounds(String text, Offset position, double fontSize) {
    // Estimate text dimensions
    final width = text.length * fontSize * 0.6;
    final height = fontSize;
    
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      width,
      height,
    );
  }
}

/// Separate stateful widget for stroke slider to handle state properly
class _StrokeSliderWidget extends StatefulWidget {
  final EnhancedImagePainterController controller;
  
  const _StrokeSliderWidget({required this.controller});
  
  @override
  _StrokeSliderWidgetState createState() => _StrokeSliderWidgetState();
}

class _StrokeSliderWidgetState extends State<_StrokeSliderWidget> {
  late double _currentStrokeWidth;
  
  @override
  void initState() {
    super.initState();
    _currentStrokeWidth = widget.controller.strokeWidth;
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Stroke Width: ${_currentStrokeWidth.toInt()}px',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Slider(
            value: _currentStrokeWidth,
            min: 2,
            max: 20,
            divisions: 18,
            label: '${_currentStrokeWidth.toInt()}px',
            onChanged: (value) {
              setState(() {
                _currentStrokeWidth = value;
              });
              widget.controller.setStrokeWidth(value);
            },
          ),
          // Visual preview of stroke width
          Container(
            height: 30,
            child: Center(
              child: Container(
                width: 100,
                height: _currentStrokeWidth,
                decoration: BoxDecoration(
                  color: widget.controller.color,
                  borderRadius: BorderRadius.circular(_currentStrokeWidth / 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
