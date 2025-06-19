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
  static DateTime? _lastClickTime;
  bool _isRepositioning = false; // Track repositioning mode
  Offset? _repositionPreviewPosition; // Track cursor position during repositioning

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
  Future<Uint8List?> exportImage({bool autoCrop = false}) async {
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
        return MouseRegion(
          onHover: (event) {
            // Update preview position during repositioning when mouse moves
            if (_isRepositioning) {
              setState(() {
                _repositionPreviewPosition = event.localPosition;
              });
            }
          },
          child: GestureDetector(
            onTapDown: (details) {
              final offset = details.localPosition;
              
              // Handle repositioning mode first
              if (_isRepositioning && _editingTextIndex != null) {
                _updateTextPosition(offset);
                _isRepositioning = false;
                _repositionPreviewPosition = null;
                return;
              }
              
              // Handle text mode - but check for existing text first
              if (_controller.mode == PaintMode.text) {
                // Check if clicking on existing text for editing
                final textIndex = _findTextAtPosition(offset);
                if (textIndex != null) {
                  // Clicking on existing text - edit it
                  _editTextAtIndex(textIndex);
                  return;
                } else {
                  // Clicking on empty space - add new text
                  _pendingTextPosition = offset;
                  _openTextDialog();
                  return;
                }
              }
            },
          onTapUp: (details) {
            final offset = details.localPosition;
            
            // Skip if we already handled this in onTapDown (text mode or repositioning)
            if (_controller.mode == PaintMode.text || _isRepositioning) {
              return;
            }
            
            // Handle potential text editing (double-click detection) only when NOT in text mode
            _lastTapPosition = offset;
            _lastTapTime = DateTime.now();
            _handleTapForTextEditing();
          },
          onPanStart: (details) {
            final offset = details.localPosition;
            
            // Skip pan gestures in text mode or repositioning mode
            if (_controller.mode == PaintMode.text || _isRepositioning) {
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
            
            // Handle repositioning preview
            if (_isRepositioning) {
              setState(() {
                _repositionPreviewPosition = offset;
              });
              return;
            }
            
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
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(_actualWidth, _actualHeight),
                  painter: EnhancedImageCustomPainter(
                    controller: _controller,
                    size: Size(_actualWidth, _actualHeight),
                    hideTextIndex: _isRepositioning ? _editingTextIndex : null, // Hide original during repositioning
                  ),
                ),
                // Show repositioning preview
                if (_isRepositioning && _repositionPreviewPosition != null && _editingTextIndex != null)
                  Positioned(
                    left: _repositionPreviewPosition!.dx,
                    top: _repositionPreviewPosition!.dy,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        border: Border.all(color: Colors.blue, width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      padding: EdgeInsets.all(2),
                      child: Text(
                        _getTextBeingRepositioned(),
                        style: TextStyle(
                          color: _controller.paintHistory[_editingTextIndex!].color,
                          fontSize: _controller.paintHistory[_editingTextIndex!].strokeWidth * 4,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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
        // No instructions needed - just switch to text mode
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
    if (_lastTapPosition == null || _controller.mode == PaintMode.text) return; // Don't handle in text mode
    
    final now = DateTime.now();
    
    // Check for double-click (within 300ms of previous click)
    if (_lastClickTime != null && now.difference(_lastClickTime!).inMilliseconds < 300) {
      final textIndex = _findTextAtPosition(_lastTapPosition!);
      if (textIndex != null) {
        _editTextAtIndex(textIndex);
        _lastClickTime = null; // Reset to prevent triple-click
        return;
      }
    }
    
    // Store this click time for next double-click check
    _lastClickTime = now;
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
      barrierDismissible: false, // Prevent dismissing accidentally
      builder: (context) => AlertDialog(
        title: Text('Add Text'),
        content: TextField(
          controller: _textController,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter text'),
          onSubmitted: (text) {
            // Allow Enter key to submit
            if (text.trim().isNotEmpty && _pendingTextPosition != null) {
              _addText();
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pendingTextPosition = null; // Clear pending position
              _textController.clear();
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_textController.text.trim().isNotEmpty && _pendingTextPosition != null) {
                _addText();
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addText() {
    if (_textController.text.trim().isNotEmpty && _pendingTextPosition != null) {
      _controller.addPaintInfo(
        PaintInfo(
          mode: PaintMode.text,
          text: _textController.text.trim(),
          offsets: [_pendingTextPosition!],
          color: _controller.color,
          strokeWidth: _controller.strokeWidth,
        ),
      );
      _textController.clear();
      _pendingTextPosition = null;
    }
  }

  void _openTextEditDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => AlertDialog(
        title: Text('Edit Text'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              autofocus: true,
              decoration: InputDecoration(hintText: 'Edit text'),
              onSubmitted: (text) {
                // Allow Enter key to update
                if (text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _updateTextContent();
                }
              },
            ),
            SizedBox(height: 16),
            Text(
              'Use Update to change text, or Reposition to move it',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cleanupTextEditing();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_textController.text.trim().isNotEmpty) {
                _updateTextContent(); // Only update text content, not position
              } else {
                _cleanupTextEditing();
              }
            },
            child: Text('Update'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Start position selection mode
              if (_textController.text.trim().isNotEmpty) {
                _startTextRepositioning();
              } else {
                _cleanupTextEditing();
              }
            },
            child: Text('Reposition'),
          ),
        ],
      ),
    );
  }

  /// Start text repositioning mode
  void _startTextRepositioning() {
    _isRepositioning = true;
    // No dialog - just start repositioning mode immediately
  }

  /// Update only the text content, keep same position
  void _updateTextContent() {
    if (_editingTextIndex == null || _editingTextIndex! >= _controller.paintHistory.length) {
      _cleanupTextEditing();
      return;
    }
    
    final newText = _textController.text.trim();
    if (newText.isEmpty) {
      _cleanupTextEditing();
      return;
    }
    
    try {
      final currentInfo = _controller.paintHistory[_editingTextIndex!];
      
      // Create updated PaintInfo with new text but same position
      final updatedInfo = PaintInfo(
        mode: PaintMode.text,
        text: newText,
        offsets: currentInfo.offsets, // Keep same position
        color: currentInfo.color,
        strokeWidth: currentInfo.strokeWidth,
      );
      
      // Replace the existing text in history
      _controller.paintHistory[_editingTextIndex!] = updatedInfo;
      
      // Force immediate repaint
      _controller.markForRepaint();
      _controller.notifyListeners();
      
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {
      print('Error updating text content: $e');
    } finally {
      _cleanupTextEditing();
    }
  }

  /// Update text position (used when repositioning)
  void _updateTextPosition(Offset newPosition) {
    if (_editingTextIndex == null || _editingTextIndex! >= _controller.paintHistory.length) {
      _cleanupTextEditing();
      return;
    }
    
    try {
      final currentInfo = _controller.paintHistory[_editingTextIndex!];
      
      // Create updated PaintInfo with new position but same text
      final updatedInfo = PaintInfo(
        mode: PaintMode.text,
        text: currentInfo.text, // Keep same text
        offsets: [newPosition], // New position
        color: currentInfo.color,
        strokeWidth: currentInfo.strokeWidth,
      );
      
      // Replace the existing text in history
      _controller.paintHistory[_editingTextIndex!] = updatedInfo;
      
      // Force immediate repaint
      _controller.markForRepaint();
      _controller.notifyListeners();
      
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {
      print('Error updating text position: $e');
    } finally {
      _cleanupTextEditing();
    }
  }

  /// Clean up text editing state
  void _cleanupTextEditing() {
    _editingTextIndex = null;
    _pendingTextPosition = null;
    _textController.clear();
    _isRepositioning = false; // Reset repositioning mode
    _repositionPreviewPosition = null; // Reset preview position
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

  /// Get the text content being repositioned
  String _getTextBeingRepositioned() {
    if (_editingTextIndex != null && _editingTextIndex! < _controller.paintHistory.length) {
      final textInfo = _controller.paintHistory[_editingTextIndex!];
      return textInfo.text ?? '';
    }
    return '';
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
