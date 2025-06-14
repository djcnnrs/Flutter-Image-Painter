// COPY THIS CODE INTO FLUTTERFLOW CUSTOM WIDGET
// Widget Name: ImagePainterWidget

import 'package:flutter/material.dart';
import 'package:image_painter/flutterflow_image_painter.dart';
import 'dart:typed_data';

class ImagePainterWidget extends StatefulWidget {
  const ImagePainterWidget({
    Key? key,
    this.width = 400,
    this.height = 400,
    this.backgroundType = 'blank',
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

  final double width;
  final double height;
  final String backgroundType; // 'none', 'blank', 'graph', 'lined', 'network'
  final String? backgroundImageUrl;
  final Color backgroundColor;
  final double strokeWidth;
  final Color paintColor;
  final bool showTextTool;
  final bool showShapesTools;
  final bool showBrushTool;
  final bool showColorTool;
  final bool showStrokeTool;
  final bool showUndoTool;
  final bool showClearTool;
  final bool showSaveTool;
  final bool controlsAtTop;
  final bool showControls;
  final Color? controlsBackgroundColor;
  final bool isScalable;

  // CRITICAL: Global key for FlutterFlow actions to access this widget
  static final GlobalKey<ImagePainterWidgetState> globalKey = 
      GlobalKey<ImagePainterWidgetState>();

  @override
  ImagePainterWidgetState createState() => ImagePainterWidgetState();
}

class ImagePainterWidgetState extends State<ImagePainterWidget> {
  final GlobalKey<FlutterFlowImagePainterState> _painterKey = 
      GlobalKey<FlutterFlowImagePainterState>();

  @override
  void initState() {
    super.initState();
    // Register this instance globally so actions can find it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ImagePainterWidget.globalKey.currentState == null) {
        // Update the global key to point to this instance
        (ImagePainterWidget.globalKey as GlobalKey<ImagePainterWidgetState>)
            .currentState = this;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ImagePainterWidget.globalKey,
      child: FlutterFlowImagePainter(
        key: _painterKey,
        width: widget.width,
        height: widget.height,
        backgroundType: widget.backgroundType,
        backgroundImageUrl: widget.backgroundImageUrl,
        backgroundColor: widget.backgroundColor,
        strokeWidth: widget.strokeWidth,
        paintColor: widget.paintColor,
        showTextTool: widget.showTextTool,
        showShapesTools: widget.showShapesTools,
        showBrushTool: widget.showBrushTool,
        showColorTool: widget.showColorTool,
        showStrokeTool: widget.showStrokeTool,
        showUndoTool: widget.showUndoTool,
        showClearTool: widget.showClearTool,
        showSaveTool: widget.showSaveTool,
        controlsAtTop: widget.controlsAtTop,
        showControls: widget.showControls,
        controlsBackgroundColor: widget.controlsBackgroundColor,
        isScalable: widget.isScalable,
      ),
    );
  }

  // Instance methods (can be called if you have direct widget reference)
  Future<Uint8List?> exportImage() async {
    try {
      return await _painterKey.currentState?.exportImage();
    } catch (e) {
      print('Export failed: $e');
      return null;
    }
  }

  void clearCanvas() {
    try {
      _painterKey.currentState?.clearCanvas();
    } catch (e) {
      print('Clear failed: $e');
    }
  }

  void undoLastAction() {
    try {
      _painterKey.currentState?.undoLastAction();
    } catch (e) {
      print('Undo failed: $e');
    }
  }

  // Static methods for FlutterFlow actions (RECOMMENDED APPROACH)
  static Future<Uint8List?> exportCurrentImage() async {
    try {
      final state = ImagePainterWidget.globalKey.currentState;
      if (state != null) {
        return await state.exportImage();
      } else {
        print('ImagePainter widget not found. Make sure the widget is rendered.');
        return null;
      }
    } catch (e) {
      print('Static export failed: $e');
      return null;
    }
  }

  static void clearCurrentCanvas() {
    try {
      final state = ImagePainterWidget.globalKey.currentState;
      if (state != null) {
        state.clearCanvas();
      } else {
        print('ImagePainter widget not found. Make sure the widget is rendered.');
      }
    } catch (e) {
      print('Static clear failed: $e');
    }
  }

  static void undoCurrentAction() {
    try {
      final state = ImagePainterWidget.globalKey.currentState;
      if (state != null) {
        state.undoLastAction();
      } else {
        print('ImagePainter widget not found. Make sure the widget is rendered.');
      }
    } catch (e) {
      print('Static undo failed: $e');
    }
  }

  static bool isWidgetReady() {
    return ImagePainterWidget.globalKey.currentState != null;
  }
}
