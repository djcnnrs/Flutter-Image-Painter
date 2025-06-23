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
  // Constants
  static const double _toolbarHeight = 60.0;
  static const double _textSizeMultiplier = 4.0;
  static const int _doubleClickTimeoutMs = 300;
  static const double _dragThreshold = 5.0;
  static const double _textBoundsPadding = 8.0;
  
  late EnhancedImagePainterController _controller;
  late TextEditingController _textController;
  
  bool _isLoading = false;
  double _actualWidth = 0;
  double _actualHeight = 0;
  
  // Text positioning
  Offset? _pendingTextPosition;
  
  // Text editing
  int? _editingTextIndex;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  DateTime? _lastClickTime;
  
  // Text dragging
  bool _isDraggingText = false;
  int? _draggingTextIndex;
  Offset? _dragStartPosition;
  Offset? _repositionPreviewPosition; // Used for drag preview

  @override
  void initState() {
    super.initState();
    
    try {
      _controller = EnhancedImagePainterController();
      _textController = TextEditingController();
      
      // Set initial values from config
      _controller.setColor(widget.config.defaultColor);
      _controller.setStrokeWidth(widget.config.defaultStrokeWidth);
      
      // Initialize canvas with proper background
      _initializeCanvas();
      
    } catch (e) {
      debugPrint('Error in initState: $e');
      rethrow;
    }
  }

  Future<void> _initializeCanvas() async {
    setState(() => _isLoading = true);

    try {
      await _setupBackground();
    } catch (e) {
      debugPrint('Error initializing canvas: $e');
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
    // Calculate the correct canvas dimensions for export using helper methods
    final double exportWidth = _getCanvasWidth();
    final double exportHeight = _getCanvasHeight();
    
    return await _controller.exportImage(Size(exportWidth, exportHeight), autoCrop: autoCrop);
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
      const SnackBar(
        content: Text('Canvas cleared'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  /// Helper method to determine if we're using a network image
  bool _isNetworkImage() {
    final bgImage = widget.bgImage?.trim();
    return bgImage != null && 
           bgImage.isNotEmpty && 
           bgImage != "Blank Canvas" && 
           bgImage != "Graph Paper" && 
           bgImage != "Lined Notebook";
  }

  /// Helper method to get canvas width
  double _getCanvasWidth() {
    return _isNetworkImage() ? _actualWidth : widget.width;
  }  /// Helper method to get canvas height
  double _getCanvasHeight() {
    return _isNetworkImage() ? _actualHeight : (widget.height - _toolbarHeight);
  }

  /// Helper method to get container width
  double _getContainerWidth() {
    return _isNetworkImage() ? _actualWidth : widget.width;
  }

  /// Helper method to get container height
  double _getContainerHeight() {
    return _isNetworkImage() ? (_actualHeight + _toolbarHeight) : widget.height;
  }

  /// Helper method to calculate text font size from stroke width
  double _getTextFontSize(double strokeWidth) {
    return strokeWidth * _textSizeMultiplier;
  }

  /// Helper method to check if a position is within the canvas bounds
  bool _isPositionInCanvasBounds(Offset position) {
    final canvasWidth = _getCanvasWidth();
    final canvasHeight = _getCanvasHeight();
    return position.dx >= 0 && 
           position.dx <= canvasWidth && 
           position.dy >= 0 && 
           position.dy <= canvasHeight;
  }

  /// Helper method to clamp a position to canvas bounds
  Offset _clampPositionToCanvasBounds(Offset position) {
    final canvasWidth = _getCanvasWidth();
    final canvasHeight = _getCanvasHeight();
    return Offset(
      position.dx.clamp(0.0, canvasWidth),
      position.dy.clamp(0.0, canvasHeight),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _getContainerWidth(),
      height: _getContainerHeight(),
      child: Column(
        children: [
          if (widget.config.toolbarAtTop) _buildToolbar(),
          Container(
            width: _getContainerWidth(),
            height: _getCanvasHeight(),
            child: _buildCanvas(),
          ),
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
          onTapDown: (details) {
            final offset = details.localPosition;
            
            // Check if the tap is within canvas bounds
            if (!_isPositionInCanvasBounds(offset)) {
              return;
            }
            
            // Always check for text first (in any mode)
            final textIndex = _findTextAtPosition(offset);
            
            // Handle text mode
            if (_controller.mode == PaintMode.text) {
              if (textIndex != null) {
                // Clicking on existing text - prepare for potential drag or edit
                _dragStartPosition = offset;
                _draggingTextIndex = textIndex;
                return;
              } else {
                // Clicking on empty space - add new text
                _pendingTextPosition = offset;
                _openTextDialog();
                return;
              }
            }
            
            // Handle non-text modes
            if (textIndex != null) {
              // Clicking on text in non-text mode - prepare for potential drag
              _dragStartPosition = offset;
              _draggingTextIndex = textIndex;
              // Don't start drawing gestures when clicking on text
              return;
            }
            
            // No text clicked - clear any text drag state
            _draggingTextIndex = null;
            _dragStartPosition = null;
          },
          onTapUp: (details) {
            final offset = details.localPosition;
            
            // If we were potentially dragging text but didn't actually drag
            if (_draggingTextIndex != null && !_isDraggingText) {
              if (_controller.mode == PaintMode.text) {
                // In text mode, single tap on text opens edit dialog
                _editTextAtIndex(_draggingTextIndex!);
              }
              // Clear drag state
              _draggingTextIndex = null;
              _dragStartPosition = null;
            }
            
            // Handle potential text editing (double-click detection) for all modes
            _lastTapPosition = offset;
            _lastTapTime = DateTime.now();
            _handleTapForTextEditing();
          },
          onPanStart: (details) {
            final offset = details.localPosition;
            
            // Check if the pan start is within canvas bounds
            if (!_isPositionInCanvasBounds(offset)) {
              return;
            }
            
            // If we have a potential text drag, just mark that we're starting a pan
            if (_draggingTextIndex != null && _dragStartPosition != null) {
              // Don't set _isDraggingText yet - wait for onPanUpdate to detect actual movement
              return;
            }
            
            // Only allow drawing gestures if we're not potentially dragging text
            if (_draggingTextIndex != null) {
              // We're on text but starting a pan - wait to see if it's a drag
              return;
            }
            
            // Skip drawing gestures in text mode when not dragging text
            if (_controller.mode == PaintMode.text) {
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
            
            // Always clamp the position to canvas bounds to prevent drawing outside
            final clampedOffset = _clampPositionToCanvasBounds(offset);
            
            // Check if we should start dragging text (detect actual movement here)
            if (_draggingTextIndex != null && !_isDraggingText && _dragStartPosition != null) {
              final dragDistance = (_dragStartPosition! - clampedOffset).distance;
              if (dragDistance > _dragThreshold) { // Threshold to differentiate tap from drag
                _isDraggingText = true;
                setState(() {
                  _repositionPreviewPosition = clampedOffset;
                });
                return;
              }
            }
            
            // Handle ongoing text dragging
            if (_isDraggingText && _draggingTextIndex != null) {
              setState(() {
                _repositionPreviewPosition = clampedOffset;
              });
              return;
            }
            
            // Don't update drawing if we're potentially dragging text
            if (_draggingTextIndex != null) {
              return;
            }
            
            // Skip other pan updates in text mode 
            if (_controller.mode == PaintMode.text) {
              return;
            }
            
            // Ensure we're still in progress
            _controller.setInProgress(true);
            
            // Always update the end position for real-time preview (using clamped position)
            _controller.setEnd(clampedOffset);
            
            if (_controller.mode == PaintMode.freeStyle) {
              _controller.addOffsets(clampedOffset);
            }
          },
          onPanEnd: (details) {
            // Handle text dragging completion
            if (_isDraggingText && _draggingTextIndex != null && _repositionPreviewPosition != null) {
              // Clamp the final position to canvas bounds
              final clampedPosition = _clampPositionToCanvasBounds(_repositionPreviewPosition!);
              _updateTextPosition(clampedPosition);
              _isDraggingText = false;
              _draggingTextIndex = null;
              _dragStartPosition = null;
              _repositionPreviewPosition = null;
              return;
            }
            
            // Clear any potential drag state
            _isDraggingText = false;
            _draggingTextIndex = null;
            _dragStartPosition = null;
            _repositionPreviewPosition = null;
            
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
            width: _getCanvasWidth(),
            height: _getCanvasHeight(),
            color: Colors.white,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(_getCanvasWidth(), _getCanvasHeight()),
                  painter: EnhancedImageCustomPainter(
                    controller: _controller,
                    size: Size(_getCanvasWidth(), _getCanvasHeight()),
                  ),
                ),
                // Show text dragging preview
                if (_isDraggingText && _repositionPreviewPosition != null && _draggingTextIndex != null)
                  Positioned(
                    left: _repositionPreviewPosition!.dx,
                    top: _repositionPreviewPosition!.dy,
                    child: Opacity(
                      opacity: 0.7,
                      child: Text(
                        _getTextBeingDragged(),
                        style: TextStyle(
                          color: _controller.paintHistory[_draggingTextIndex!].color,
                          fontSize: _getTextFontSize(_controller.paintHistory[_draggingTextIndex!].strokeWidth),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: _toolbarHeight,
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
                tooltip: _controller.paintHistory.isEmpty ? 'Canvas is Empty' : 'Save',
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
    if (_lastTapPosition == null) return;
    
    final now = DateTime.now();
    
    // Check for double-click (within timeout period)
    if (_lastClickTime != null && now.difference(_lastClickTime!).inMilliseconds < _doubleClickTimeoutMs) {
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
        content: TextField(
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
        ],
      ),
    );
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
      debugPrint('Error updating text content: $e');
    } finally {
      _cleanupTextEditing();
    }
  }

  /// Update text position (used when repositioning)
  /// Update text position (used when repositioning via drag-and-drop)
  void _updateTextPosition(Offset newPosition) {
    final textIndex = _draggingTextIndex ?? _editingTextIndex;
    if (textIndex == null || textIndex >= _controller.paintHistory.length) {
      _cleanupTextEditing();
      return;
    }
    
    try {
      final currentInfo = _controller.paintHistory[textIndex];
      
      // Create updated PaintInfo with new position but same text
      final updatedInfo = PaintInfo(
        mode: PaintMode.text,
        text: currentInfo.text, // Keep same text
        offsets: [newPosition], // New position
        color: currentInfo.color,
        strokeWidth: currentInfo.strokeWidth,
      );
      
      // Replace the existing text in history
      _controller.paintHistory[textIndex] = updatedInfo;
      
      // Force immediate repaint
      _controller.markForRepaint();
      _controller.notifyListeners();
      
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {
      debugPrint('Error updating text position: $e');
    } finally {
      _cleanupTextEditing();
    }
  }

  /// Clean up text editing state
  void _cleanupTextEditing() {
    _editingTextIndex = null;
    _pendingTextPosition = null;
    _textController.clear();
    _isDraggingText = false;
    _draggingTextIndex = null;
    _dragStartPosition = null;
    _repositionPreviewPosition = null;
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

  /// Get the text content being dragged
  String _getTextBeingDragged() {
    if (_draggingTextIndex != null && _draggingTextIndex! < _controller.paintHistory.length) {
      final textInfo = _controller.paintHistory[_draggingTextIndex!];
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
        final textBounds = _calculateTextBounds(info.text!, textPosition, _getTextFontSize(info.strokeWidth));
        
        if (textBounds.contains(position)) {
          return i;
        }
      }
    }
    return null;
  }

  /// Calculate the bounds of a text element more accurately
  Rect _calculateTextBounds(String text, Offset position, double fontSize) {
    // Create a TextPainter to measure the actual text size
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Add some padding to make selection easier
    const padding = _textBoundsPadding;
    
    final bounds = Rect.fromLTWH(
      position.dx - padding,
      position.dy - padding,
      textPainter.width + (padding * 2),
      textPainter.height + (padding * 2),
    );
    
    // Dispose the text painter to prevent memory leaks
    textPainter.dispose();
    
    return bounds;
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