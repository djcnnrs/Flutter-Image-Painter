import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'flutterflow_controller.dart';
import 'delegates/text_delegate.dart';
import 'widgets/_color_widget.dart';
import 'widgets/_range_slider.dart';
import 'widgets/_text_dialog.dart';

/// FlutterFlow-compatible Image Painter widget
/// All configuration is done through simple parameters instead of callbacks
class FlutterFlowImagePainter extends StatefulWidget {
  const FlutterFlowImagePainter({
    Key? key,
    this.height = 400,
    this.width = 400,
    this.backgroundType = 'none',
    this.backgroundImageUrl,
    this.backgroundColor = Colors.white,
    this.strokeWidth = 4.0,
    this.paintColor = Colors.red,
    this.showTextTool = true,
    this.showShapesTools = true,
    this.showBrushTool = true,
    this.showColorTool = true,
    this.showStrokeTool = true,
    this.showUndoTool = true,
    this.showClearTool = true,
    this.showSaveTool = false,
    this.controlsAtTop = true,
    this.showControls = true,
    this.controlsBackgroundColor,
    this.isScalable = false,
  }) : super(key: key);

  /// Height of the widget
  final double height;
  
  /// Width of the widget
  final double width;
  
  /// Background type: 'none', 'blank', 'graph', 'lined', 'network'
  final String backgroundType;
  
  /// URL for network image background
  final String? backgroundImageUrl;
  
  /// Background color for blank canvas
  final Color backgroundColor;
  
  /// Initial stroke width
  final double strokeWidth;
  
  /// Initial paint color
  final Color paintColor;
  
  /// Show/hide individual tools
  final bool showTextTool;
  final bool showShapesTools;
  final bool showBrushTool;
  final bool showColorTool;
  final bool showStrokeTool;
  final bool showUndoTool;
  final bool showClearTool;
  final bool showSaveTool;
  
  /// Controls position and visibility
  final bool controlsAtTop;
  final bool showControls;
  final Color? controlsBackgroundColor;
  
  /// Enable scaling/zooming
  final bool isScalable;

  @override
  FlutterFlowImagePainterState createState() => FlutterFlowImagePainterState();
}

class FlutterFlowImagePainterState extends State<FlutterFlowImagePainter> {
  late SimpleImagePainterController _controller;
  late TransformationController _transformationController;
  late TextEditingController _textController;
  late TextDelegate _textDelegate;
  ui.Image? _backgroundImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _transformationController = TransformationController();
    _textController = TextEditingController();
    _textDelegate = TextDelegate();
    
    if (widget.backgroundType == 'network' && widget.backgroundImageUrl != null) {
      _loadNetworkImage();
    }
  }

  void _initializeController() {
    final backgroundType = _stringToBackgroundType(widget.backgroundType);
    
    _controller = SimpleImagePainterController(
      strokeWidth: widget.strokeWidth,
      color: widget.paintColor,
      backgroundType: backgroundType,
      backgroundImageUrl: widget.backgroundImageUrl,
      backgroundColor: widget.backgroundColor,
      showTextTool: widget.showTextTool,
      showShapesTools: widget.showShapesTools,
      showBrushTool: widget.showBrushTool,
      showColorTool: widget.showColorTool,
      showStrokeTool: widget.showStrokeTool,
      showUndoTool: widget.showUndoTool,
      showClearTool: widget.showClearTool,
      showSaveTool: widget.showSaveTool,
    );
  }

  BackgroundType _stringToBackgroundType(String type) {
    switch (type.toLowerCase()) {
      case 'blank':
      case 'canvas':
        return BackgroundType.blankCanvas;
      case 'graph':
      case 'grid':
        return BackgroundType.graphPaper;
      case 'lined':
      case 'notebook':
        return BackgroundType.linedNotebook;
      case 'network':
      case 'image':
        return BackgroundType.networkImage;
      default:
        return BackgroundType.none;
    }
  }

  Future<void> _loadNetworkImage() async {
    if (widget.backgroundImageUrl == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final completer = Completer<ImageInfo>();
      final img = NetworkImage(widget.backgroundImageUrl!);
      img.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((info, _) => completer.complete(info)));
      final imageInfo = await completer.future;
      _backgroundImage = imageInfo.image;
    } catch (e) {
      print('Failed to load background image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Public method to export the image (can be called from FlutterFlow actions)
  Future<Uint8List?> exportImage() async {
    return await _controller.exportImage();
  }

  /// Public method to clear the canvas (can be called from FlutterFlow actions)
  void clearCanvas() {
    _controller.clear();
  }

  /// Public method to undo last action (can be called from FlutterFlow actions)
  void undoLastAction() {
    _controller.undo();
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
        height: widget.height,
        width: widget.width,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Column(
        children: [
          if (widget.controlsAtTop && widget.showControls) _buildControls(),
          Expanded(child: _buildPaintArea()),
          if (!widget.controlsAtTop && widget.showControls) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildPaintArea() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return InteractiveViewer(
          transformationController: _transformationController,
          maxScale: 2.4,
          minScale: 1,
          panEnabled: _controller.mode == PaintMode.none,
          scaleEnabled: widget.isScalable,
          onInteractionStart: _handleInteractionStart,
          onInteractionUpdate: _handleInteractionUpdate,
          onInteractionEnd: _handleInteractionEnd,
          child: Container(
            width: widget.width,
            height: widget.height,
            child: CustomPaint(
              size: Size(widget.width, widget.height),
              painter: SimpleDrawImage(controller: _controller),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(4),
      color: widget.controlsBackgroundColor ?? Colors.grey[200],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showBrushTool) _buildModeButton(),
          if (widget.showColorTool) _buildColorButton(),
          if (widget.showStrokeTool) _buildStrokeButton(),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              if (_controller.canFill()) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _controller.shouldFill,
                      onChanged: (val) => _controller.setFill(val ?? false),
                    ),
                    Text(_textDelegate.fill),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const Spacer(),
          if (widget.showUndoTool) IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => _controller.undo(),
            tooltip: _textDelegate.undo,
          ),
          if (widget.showClearTool) IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _controller.clear(),
            tooltip: _textDelegate.clearAllProgress,
          ),
          if (widget.showSaveTool) IconButton(
            icon: const Icon(Icons.save),
            onPressed: _handleSave,
            tooltip: _textDelegate.save,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final currentMode = _controller.mode;
        IconData icon;
        switch (currentMode) {
          case PaintMode.line:
            icon = Icons.horizontal_rule;
            break;
          case PaintMode.rect:
            icon = Icons.crop_free;
            break;
          case PaintMode.circle:
            icon = Icons.lens_outlined;
            break;
          case PaintMode.freeStyle:
            icon = Icons.edit;
            break;
          case PaintMode.text:
            icon = Icons.text_format;
            break;
          default:
            icon = Icons.zoom_out_map;
        }

        return PopupMenuButton<PaintMode>(
          icon: Icon(icon),
          tooltip: _textDelegate.changeMode,
          onSelected: (mode) {
            _controller.setMode(mode);
            if (mode == PaintMode.text) {
              _openTextDialog();
            }
          },
          itemBuilder: (context) => _buildModeItems(),
        );
      },
    );
  }

  List<PopupMenuEntry<PaintMode>> _buildModeItems() {
    final modes = <PopupMenuEntry<PaintMode>>[];
    
    modes.add(PopupMenuItem(
      value: PaintMode.none,
      child: Row(
        children: [
          Icon(Icons.zoom_out_map),
          SizedBox(width: 8),
          Text(_textDelegate.noneZoom),
        ],
      ),
    ));
    
    modes.add(PopupMenuItem(
      value: PaintMode.freeStyle,
      child: Row(
        children: [
          Icon(Icons.edit),
          SizedBox(width: 8),
          Text(_textDelegate.drawing),
        ],
      ),
    ));
    
    modes.add(PopupMenuItem(
      value: PaintMode.line,
      child: Row(
        children: [
          Icon(Icons.horizontal_rule),
          SizedBox(width: 8),
          Text(_textDelegate.line),
        ],
      ),
    ));
    
    if (widget.showShapesTools) {
      modes.addAll([
        PopupMenuItem(
          value: PaintMode.rect,
          child: Row(
            children: [
              Icon(Icons.crop_free),
              SizedBox(width: 8),
              Text(_textDelegate.rectangle),
            ],
          ),
        ),
        PopupMenuItem(
          value: PaintMode.circle,
          child: Row(
            children: [
              Icon(Icons.lens_outlined),
              SizedBox(width: 8),
              Text(_textDelegate.circle),
            ],
          ),
        ),
      ]);
    }
    
    if (widget.showTextTool) {
      modes.add(PopupMenuItem(
        value: PaintMode.text,
        child: Row(
          children: [
            Icon(Icons.text_format),
            SizedBox(width: 8),
            Text(_textDelegate.text),
          ],
        ),
      ));
    }
    
    return modes;
  }

  Widget _buildColorButton() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
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
          tooltip: _textDelegate.changeColor,
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
                      border: Border.all(
                        color: _controller.color == color ? Colors.black : Colors.grey,
                        width: _controller.color == color ? 2 : 1,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStrokeButton() {
    return PopupMenuButton(
      icon: const Icon(Icons.brush),
      tooltip: _textDelegate.changeBrushSize,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 200,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Slider(
                  value: _controller.strokeWidth,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) => _controller.setStrokeWidth(value),
                );
              },
            ),
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
    
    if (_controller.onTextUpdateMode) {
      _controller.paintHistory
          .lastWhere((element) => element.mode == PaintMode.text)
          .offsets = [offset];
    }
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    _controller.setInProgress(false);
    
    if (_controller.start != null && _controller.end != null) {
      if (_controller.mode == PaintMode.freeStyle) {
        _controller.addOffsets(null);
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
        strokeWidth: _controller.scaledStrokeWidth,
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
        strokeWidth: _controller.scaledStrokeWidth,
      ),
    );
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
                    offsets: [],
                    color: _controller.color,
                    strokeWidth: _controller.scaledStrokeWidth,
                  ),
                );
                _textController.clear();
              }
              Navigator.pop(context);
            },
            child: Text(_textDelegate.done),
          ),
        ],
      ),
    );
  }

  void _handleSave() async {
    try {
      final imageData = await exportImage();
      if (imageData != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
