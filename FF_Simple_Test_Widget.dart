// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Enhanced Image Painter with improved UX
// - Drawing is now properly constrained to canvas area only
// - No more drawing artifacts over toolbar when toolbarAtTop = true
// - ClipRect ensures all drawing stays within bounds

import 'package:enhanced_image_painter/enhanced_image_painter.dart';

class SimpleImagePainter extends StatefulWidget {
  const SimpleImagePainter({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<SimpleImagePainter> createState() => _SimpleImagePainterState();
}

class _SimpleImagePainterState extends State<SimpleImagePainter> {
  late EnhancedImagePainterController _controller;
  List<Offset> _currentStroke = [];
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _controller = EnhancedImagePainterController();
    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (!_isDirty) {
      _isDirty = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isDirty) {
          setState(() {
            _isDirty = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double actualWidth = widget.width ?? 300;
    final double actualHeight = widget.height ?? 200;

    return Container(
      width: actualWidth,
      height: actualHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(actualWidth, actualHeight),
          painter: EnhancedImageCustomPainter(
            controller: _controller,
            size: Size(actualWidth, actualHeight),
          ),
          child: GestureDetector(
            onPanStart: (details) {
              _currentStroke.clear();
              _currentStroke.add(details.localPosition);
              _controller.setStart(details.localPosition);
              _controller.setInProgress(true);
            },
            onPanUpdate: (details) {
              _currentStroke.add(details.localPosition);
              _controller.setEnd(details.localPosition);
              _controller.addOffsets(details.localPosition);
            },
            onPanEnd: (details) {
              _controller.setInProgress(false);
              _controller.addPaintInfo(
                PaintInfo(
                  mode: _controller.mode,
                  offsets: List.from(_currentStroke),
                  color: _controller.color,
                  strokeWidth: _controller.strokeWidth,
                  fill: _controller.fill,
                ),
              );
              _controller.offsets.clear();
              _controller.resetStartAndEnd();
              _currentStroke.clear();
            },
            child: Container(
              width: actualWidth,
              height: actualHeight,
              color: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
