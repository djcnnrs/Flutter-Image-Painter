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
    
    // Set up a test scenario with network image and text
    _setupTestScenario();
  }
  
  void _setupTestScenario() {
    // Set a network image background
    _controller.setBackgroundType(BackgroundType.networkImage);
    _controller.setBackgroundImageUrl('https://picsum.photos/400/300');
    
    // Add some test annotations that will be exported
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a text annotation
      final textInfo = PaintInfo(
        mode: PaintMode.text,
        text: 'Test Export Text',
        offsets: [const Offset(50, 50)],
        color: Colors.red,
        strokeWidth: 3.0,
      );
      _controller.paintHistory.add(textInfo);
      
      // Add a simple line
      final lineInfo = PaintInfo(
        mode: PaintMode.line,
        offsets: [const Offset(100, 100), const Offset(200, 150)],
        color: Colors.blue,
        strokeWidth: 5.0,
      );
      _controller.paintHistory.add(lineInfo);
      
      _controller.notifyListeners();
    });
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

    return Column(
      children: [
        // Export test button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: _testExport,
            child: const Text('Test Export'),
          ),
        ),
        Container(
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
        ),
      ],
    );
  }

  void _testExport() async {
    print('Starting export test...');
    try {
      final size = Size(widget.width ?? 300, widget.height ?? 200);
      final result = await _controller.exportImage(size);
      
      if (result != null) {
        print('Export successful! Image size: ${result.lengthInBytes} bytes');
        
        // Show a success dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Export Success'),
              content: Text('Image exported successfully!\nSize: ${result.lengthInBytes} bytes'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        print('Export failed: result is null');
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => const AlertDialog(
              title: Text('Export Failed'),
              content: Text('Export returned null - check debug console for details'),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Export test error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Error'),
            content: Text('Export failed with error:\n$e'),
          ),
        );
      }
    }
  }
}
