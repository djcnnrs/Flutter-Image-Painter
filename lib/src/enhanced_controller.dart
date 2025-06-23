import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Core enums for the enhanced image painter
enum PaintMode { none, freeStyle, line, rect, circle, text, arrow, dashedLine }
enum BackgroundType { none, blankCanvas, graphPaper, linedNotebook, networkImage }

/// Paint information for storing drawing data
class PaintInfo {
  final List<Offset?> offsets;
  final PaintMode mode;
  final Color color;
  final double strokeWidth;
  final bool fill;
  final String? text;

  PaintInfo({
    required this.offsets,
    required this.mode,
    required this.color,
    required this.strokeWidth,
    this.fill = false,
    this.text,
  });
}
  final String? text;

  PaintInfo({
    required this.offsets,
    required this.mode,
    required this.color,
    required this.strokeWidth,
    this.fill = false,
    this.text,
  });
}

/// Enhanced Image Painter Controller with all functionality
class EnhancedImagePainterController extends ChangeNotifier {
  PaintMode _mode = PaintMode.freeStyle;
  Color _color = Colors.black;
  double _strokeWidth = 2.0;
  bool _fill = false;
  final List<PaintInfo> _paintHistory = [];
  final List<Offset?> _offsets = [];
  Offset? _start, _end;
  bool _inProgress = false;
  BackgroundType _backgroundType = BackgroundType.none;
  String? _backgroundImageUrl;
  Color _backgroundColor = Colors.white;
  ui.Image? _backgroundImage;
  bool _shouldRepaint = false;

  // Getters
  PaintMode get mode => _mode;
  Color get color => _color;
  double get strokeWidth => _strokeWidth;
  bool get fill => _fill;
  List<PaintInfo> get paintHistory => _paintHistory; // Make directly accessible for editing
  List<Offset?> get offsets => _offsets;
  Offset? get start => _start;
  Offset? get end => _end;
  bool get inProgress => _inProgress;
  BackgroundType get backgroundType => _backgroundType;
  String? get backgroundImageUrl => _backgroundImageUrl;
  Color get backgroundColor => _backgroundColor;
  ui.Image? get backgroundImage => _backgroundImage;
  bool get shouldRepaint => _shouldRepaint;

  // Setters
  void setMode(PaintMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void setFill(bool fill) {
    _fill = fill;
    notifyListeners();
  }

  void setBackgroundType(BackgroundType type) {
    _backgroundType = type;
    notifyListeners();
  }

  void setBackgroundImageUrl(String? url) {
    _backgroundImageUrl = url;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }

  void setBackgroundImage(ui.Image? image) {
    if (_backgroundImage != image) {  // Only update if actually different
      _backgroundImage = image;
      notifyListeners();
    }
  }

  void setStart(Offset? offset) {
    _start = offset;
    notifyListeners();
  }
  
  void setEnd(Offset? offset) {
    _end = offset;
    notifyListeners();
  }
  
  void setInProgress(bool inProgress) {
    _inProgress = inProgress;
    notifyListeners();
  }

  void markForRepaint() {
    _shouldRepaint = true;
  }

  void _markForRepaint() {
    markForRepaint();
  }

  void _clearRepaintFlag() {
    _shouldRepaint = false;
  }

  void addOffsets(Offset? offset) {
    _offsets.add(offset);
    _markForRepaint();
    notifyListeners();
  }

  void addPaintInfo(PaintInfo info) {
    // Optimize stroke points for freeStyle to prevent memory issues
    PaintInfo optimizedInfo = info;
    if (info.mode == PaintMode.freeStyle && info.offsets.length > 100) {
      optimizedInfo = PaintInfo(
        offsets: _optimizeStrokePoints(info.offsets),
        mode: info.mode,
        color: info.color,
        strokeWidth: info.strokeWidth,
        fill: info.fill,
        text: info.text,
      );
    }
    
    _paintHistory.add(optimizedInfo);
    _markForRepaint();
    notifyListeners();
  }

  /// Optimizes stroke points by removing redundant points while maintaining visual quality
  List<Offset?> _optimizeStrokePoints(List<Offset?> points) {
    if (points.length <= 100) return points;
    
    final optimized = <Offset?>[];
    const minDistance = 2.0; // Minimum distance between points
    
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      if (point == null) {
        optimized.add(null);
        continue;
      }
      
      // Always keep first and last points
      if (i == 0 || i == points.length - 1) {
        optimized.add(point);
        continue;
      }
      
      // Keep point if it's far enough from the previous kept point
      final lastKept = optimized.isEmpty ? null : optimized.last;
      if (lastKept == null || (point - lastKept).distance >= minDistance) {
        optimized.add(point);
      }
    }
    
    return optimized;
  }

  void resetStartAndEnd() {
    _start = null;
    _end = null;
  }

  bool canFill() {
    return _mode == PaintMode.rect || _mode == PaintMode.circle;
  }

  void undo() {
    if (_paintHistory.isNotEmpty) {
      _paintHistory.removeLast();
      _markForRepaint();
      notifyListeners();
    }
  }

  void clear() {
    _paintHistory.clear();
    _offsets.clear();
    resetStartAndEnd();
    _markForRepaint();
    notifyListeners();
  }

  Future<Uint8List?> exportImage(Size size, {bool autoCrop = false}) async {
    debugPrint('=== EXPORT START ===');
    debugPrint('Exporting image with size: ${size.width}x${size.height}');
    debugPrint('Background type: $backgroundType');
    debugPrint('Background image: ${backgroundImage != null ? '${backgroundImage!.width}x${backgroundImage!.height}' : 'null'}');
    debugPrint('Background image URL: $_backgroundImageUrl');
    debugPrint('Paint history length: ${_paintHistory.length}');
    debugPrint('Background color: $_backgroundColor');
    debugPrint('Controller mode: $_mode');
    debugPrint('Controller color: $_color');
    debugPrint('Controller stroke width: $_strokeWidth');
    
    // Debug paint history details
    for (int i = 0; i < _paintHistory.length; i++) {
      final info = _paintHistory[i];
      debugPrint('Paint history [$i]: mode=${info.mode}, color=${info.color}, strokeWidth=${info.strokeWidth}, offsets=${info.offsets.length}, text="${info.text}"');
    }
    
    try {
      // Detailed debug info about the current state
      debugPrint('=== EXPORT STATE ANALYSIS ===');
      debugPrint('Background type: $_backgroundType');
      debugPrint('Background image URL: $_backgroundImageUrl');
      debugPrint('Background image loaded: ${_backgroundImage != null}');
      if (_backgroundImage != null) {
        debugPrint('Background image dimensions: ${_backgroundImage!.width}x${_backgroundImage!.height}');
        debugPrint('Background image hashCode: ${_backgroundImage.hashCode}');
      }
      debugPrint('Paint history has ${_paintHistory.length} items');
      debugPrint('Current in-progress state: $_inProgress');
      debugPrint('Current mode: $_mode');
      debugPrint('================================');
      
      // Ensure background image is loaded for network images
      if (_backgroundType == BackgroundType.networkImage && 
          _backgroundImageUrl != null && 
          _backgroundImage == null) {
        debugPrint('EXPORT: Loading background image before export...');
        await loadBackgroundImage(_backgroundImageUrl!);
        if (_backgroundImage == null) {
          debugPrint('EXPORT ERROR: Failed to load background image for export');
        } else {
          debugPrint('EXPORT: Background image loaded successfully for export: ${_backgroundImage!.width}x${_backgroundImage!.height}');
        }
      } else if (_backgroundType == BackgroundType.networkImage && _backgroundImage != null) {
        debugPrint('EXPORT: Background image already loaded: ${_backgroundImage!.width}x${_backgroundImage!.height}');
      } else if (_backgroundType == BackgroundType.networkImage) {
        debugPrint('EXPORT WARNING: Network image background but no URL or image loaded');
      }
      
      // Create a CustomPainter instance and use it to draw
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      debugPrint('EXPORT: Created canvas recorder and canvas');
      debugPrint('EXPORT: Starting export drawing using CustomPainter approach...');
      
      // Temporarily disable the current stroke for export
      final originalInProgress = _inProgress;
      final originalStart = _start;
      final originalEnd = _end;
      _inProgress = false;
      _start = null;
      _end = null;
      
      debugPrint('EXPORT: Temporarily disabled in-progress drawing (was: $originalInProgress)');
      
      // Create a temporary CustomPainter to do the drawing
      final painter = EnhancedImageCustomPainter(
        controller: this,
        size: size,
      );
      
      debugPrint('EXPORT: Created CustomPainter instance');
      
      // Use the CustomPainter's paint method to draw everything
      debugPrint('EXPORT: About to call painter.paint()...');
      painter.paint(canvas, size);
      debugPrint('EXPORT: painter.paint() completed');
      
      // Restore the original in-progress state
      _inProgress = originalInProgress;
      _start = originalStart;
      _end = originalEnd;
      
      debugPrint('EXPORT: Restored original drawing state');
      debugPrint('EXPORT: Finished drawing all elements using CustomPainter methods');
      
      debugPrint('EXPORT: About to record picture...');
      final picture = recorder.endRecording();
      debugPrint('EXPORT: Picture recorded successfully');
      
      debugPrint('EXPORT: Converting picture to image: ${size.width.toInt()}x${size.height.toInt()}');
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      debugPrint('EXPORT: Image created successfully: ${img.width}x${img.height}');
      
      // CRITICAL DEBUG: Create a simple test image to verify the export pipeline works
      debugPrint('=== CREATING TEST IMAGE FOR COMPARISON ===');
      final testRecorder = ui.PictureRecorder();
      final testCanvas = Canvas(testRecorder);
      
      // Draw a simple test pattern that should definitely be visible
      testCanvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.yellow);
      testCanvas.drawCircle(Offset(100, 100), 50, Paint()..color = Colors.red);
      testCanvas.drawRect(Rect.fromLTWH(50, 200, 200, 100), Paint()..color = Colors.blue);
      
      final testPicture = testRecorder.endRecording();
      final testImg = await testPicture.toImage(size.width.toInt(), size.height.toInt());
      final testByteData = await testImg.toByteData(format: ui.ImageByteFormat.png);
      debugPrint('Test image created, size: ${testByteData?.lengthInBytes} bytes');
      debugPrint('=========================================');
      
      if (autoCrop && _paintHistory.isNotEmpty) {
        final bounds = _calculateContentBounds();
        if (bounds != null && bounds.width > 0 && bounds.height > 0) {
          const padding = 20.0;
          final cropRect = Rect.fromLTRB(
            math.max(0, bounds.left - padding),
            math.max(0, bounds.top - padding),
            math.min(size.width, bounds.right + padding),
            math.min(size.height, bounds.bottom + padding),
          );
          
          final croppedImg = await _cropImage(img, cropRect);
          final byteData = await croppedImg.toByteData(format: ui.ImageByteFormat.png);
          debugPrint('Cropped export completed, final image size: ${byteData?.lengthInBytes} bytes');
          return byteData?.buffer.asUint8List();
        }
      }
      
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      debugPrint('Export completed, final image size: ${byteData?.lengthInBytes} bytes');
      
      // Additional debugging: Try to verify the image has content
      if (byteData != null) {
        debugPrint('ByteData is not null, length: ${byteData.lengthInBytes}');
        final bytes = byteData.buffer.asUint8List();
        debugPrint('Uint8List created, length: ${bytes.length}');
        
        // Check if it's not just a blank image by examining some bytes
        if (bytes.length > 100) {
          var hasContent = false;
          // Sample a few bytes to see if there's actual image data
          for (int i = 50; i < math.min(bytes.length, 200); i += 10) {
            if (bytes[i] != 0 && bytes[i] != 255) {
              hasContent = true;
              break;
            }
          }
          debugPrint('Image appears to have content: $hasContent');
        }
        
        return bytes;
      } else {
        debugPrint('ERROR: ByteData is null after image conversion');
        return null;
      }
      
    } catch (e, stackTrace) {
      debugPrint('Export error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  Rect? _calculateContentBounds() {
    if (_paintHistory.isEmpty) return null;
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final info in _paintHistory) {
      for (final offset in info.offsets) {
        if (offset != null) {
          minX = math.min(minX, offset.dx);
          minY = math.min(minY, offset.dy);
          maxX = math.max(maxX, offset.dx);
          maxY = math.max(maxY, offset.dy);
        }
      }
      
      // For text, account for text size
      if (info.mode == PaintMode.text && info.offsets.isNotEmpty && info.text != null) {
        final textSize = _estimateTextSize(info.text!, info.strokeWidth * 4);
        final offset = info.offsets[0]!;
        maxX = math.max(maxX, offset.dx + textSize.width);
        maxY = math.max(maxY, offset.dy + textSize.height);
      }
    }
    
    if (minX == double.infinity) return null;
    
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Size _estimateTextSize(String text, double fontSize) {
    // Rough estimation of text size
    return Size(text.length * fontSize * 0.6, fontSize);
  }

  Future<ui.Image> _cropImage(ui.Image original, Rect cropRect) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final srcRect = Rect.fromLTWH(
      cropRect.left,
      cropRect.top,
      cropRect.width,
      cropRect.height,
    );
    
    final dstRect = Rect.fromLTWH(0, 0, cropRect.width, cropRect.height);
    
    canvas.drawImageRect(original, srcRect, dstRect, Paint());
    
    final picture = recorder.endRecording();
    return await picture.toImage(cropRect.width.toInt(), cropRect.height.toInt());
  }

  Future<void> loadBackgroundImage(String url) async {
    debugPrint('=== loadBackgroundImage START ===');
    debugPrint('Loading image from URL: $url');
    
    try {
      final completer = Completer<ui.Image>();
      final img = NetworkImage(url);
      
      debugPrint('Created NetworkImage, resolving...');
      img.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) {
          debugPrint('Image loaded successfully: ${info.image.width}x${info.image.height}');
          completer.complete(info.image);
        }, onError: (error, stackTrace) {
          debugPrint('Image loading error: $error');
          debugPrint('Stack trace: $stackTrace');
          completer.completeError(error);
        })
      );
      
      debugPrint('Waiting for image to load...');
      _backgroundImage = await completer.future;
      debugPrint('Background image set successfully: ${_backgroundImage!.width}x${_backgroundImage!.height}');
      notifyListeners();
      debugPrint('=== loadBackgroundImage END ===');
    } catch (e) {
      debugPrint('Failed to load background image: $e');
      debugPrint('=== loadBackgroundImage END (ERROR) ===');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Enhanced Custom Painter with all drawing capabilities
class EnhancedImageCustomPainter extends CustomPainter {
  final EnhancedImagePainterController controller;
  final Size size;

  EnhancedImageCustomPainter({
    required this.controller, 
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('=== CustomPainter.paint START ===');
    debugPrint('Canvas size: ${size.width}x${size.height}');
    debugPrint('Background type: ${controller.backgroundType}');
    debugPrint('Background image: ${controller.backgroundImage != null ? '${controller.backgroundImage!.width}x${controller.backgroundImage!.height}' : 'null'}');
    debugPrint('Paint history count: ${controller.paintHistory.length}');
    debugPrint('In progress: ${controller.inProgress}');
    
    // Draw background first
    debugPrint('About to draw background...');
    _drawBackground(canvas, size);
    debugPrint('Background drawing completed');
    
    // Draw all completed strokes
    debugPrint('About to draw paint history (${controller.paintHistory.length} items)...');
    for (int i = 0; i < controller.paintHistory.length; i++) {
      final info = controller.paintHistory[i];
      debugPrint('Drawing paint history item $i: ${info.mode}');
      _drawPaintInfo(canvas, info);
    }
    debugPrint('Paint history drawing completed');
    
    // Draw current stroke being drawn (real-time preview)
    if (controller.inProgress && controller.start != null && controller.end != null) {
      debugPrint('Drawing current in-progress stroke...');
      _drawCurrentStroke(canvas);
      debugPrint('Current stroke drawing completed');
    } else {
      debugPrint('No in-progress stroke to draw');
    }
    
    debugPrint('=== CustomPainter.paint END ===');
    controller._clearRepaintFlag();
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    debugPrint('Drawing background - Type: ${controller.backgroundType}, Size: ${size.width}x${size.height}');
    
    switch (controller.backgroundType) {
      case BackgroundType.blankCanvas:
        canvas.drawRect(rect, Paint()..color = controller.backgroundColor);
        debugPrint('Drew blank canvas background');
        break;
      case BackgroundType.graphPaper:
        _drawGraphPaper(canvas, size);
        debugPrint('Drew graph paper background');
        break;
      case BackgroundType.linedNotebook:
        _drawLinedNotebook(canvas, size);
        debugPrint('Drew lined notebook background');
        break;
      case BackgroundType.networkImage:
        if (controller.backgroundImage != null) {
          debugPrint('Drawing network image: ${controller.backgroundImage!.width}x${controller.backgroundImage!.height}');
          
          // First, fill the background with white to ensure no transparency
          canvas.drawRect(rect, Paint()..color = Colors.white);
          debugPrint('Drew white background base');
          
          // Calculate how to fit the image within the canvas while maintaining aspect ratio
          final imageWidth = controller.backgroundImage!.width.toDouble();
          final imageHeight = controller.backgroundImage!.height.toDouble();
          final canvasWidth = rect.width;
          final canvasHeight = rect.height;
          
          // Calculate scaling factor to fit image within canvas
          final scaleX = canvasWidth / imageWidth;
          final scaleY = canvasHeight / imageHeight;
          final scale = math.min(scaleX, scaleY); // Use smaller scale to maintain aspect ratio
          
          // Calculate the actual dimensions after scaling
          final scaledWidth = imageWidth * scale;
          final scaledHeight = imageHeight * scale;
          
          // Center the image within the canvas
          final offsetX = (canvasWidth - scaledWidth) / 2;
          final offsetY = (canvasHeight - scaledHeight) / 2;
          
          // Draw the image with proper scaling and centering
          final destRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
          final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
          
          debugPrint('Image rects - Src: $srcRect, Dest: $destRect');
          
          // Create paint with explicit settings for proper rendering
          final imagePaint = Paint()
            ..isAntiAlias = true
            ..filterQuality = FilterQuality.high;
          
          canvas.drawImageRect(
            controller.backgroundImage!,
            srcRect,
            destRect,
            imagePaint,
          );
          debugPrint('Network image drawn with scale: $scale');
          
        } else {
          // Fallback to white background if image failed to load
          canvas.drawRect(rect, Paint()..color = Colors.white);
          debugPrint('Network image is null, drew white fallback background');
        }
        break;
      case BackgroundType.none:
      default:
        canvas.drawRect(rect, Paint()..color = Colors.white);
        debugPrint('Drew default white background');
        break;
    }
  }

  void _drawGraphPaper(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    const gridSize = 20.0;
    
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLinedNotebook(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);
    
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    const lineSpacing = 25.0;
    
    for (double y = lineSpacing; y <= size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawPaintInfo(Canvas canvas, PaintInfo info) {
    debugPrint('Drawing paint info: ${info.mode}, color: ${info.color}, strokeWidth: ${info.strokeWidth}');
    
    final paint = Paint()
      ..color = info.color
      ..strokeWidth = info.strokeWidth
      ..style = info.fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.srcOver; // Ensure annotations draw over background

    switch (info.mode) {
      case PaintMode.freeStyle:
        _drawFreeStyle(canvas, info.offsets, paint);
        debugPrint('Drew freeStyle with ${info.offsets.length} points');
        break;
      case PaintMode.line:
        if (info.offsets.length >= 2) {
          canvas.drawLine(info.offsets[0]!, info.offsets[1]!, paint);
          debugPrint('Drew line from ${info.offsets[0]} to ${info.offsets[1]}');
        }
        break;
      case PaintMode.rect:
        if (info.offsets.length >= 2) {
          final rect = Rect.fromPoints(info.offsets[0]!, info.offsets[1]!);
          canvas.drawRect(rect, paint);
          debugPrint('Drew rectangle: $rect');
        }
        break;
      case PaintMode.circle:
        if (info.offsets.length >= 2) {
          final center = info.offsets[0]!;
          final radius = (info.offsets[1]! - center).distance;
          canvas.drawCircle(center, radius, paint);
          debugPrint('Drew circle at $center with radius $radius');
        }
        break;
      case PaintMode.text:
        if (info.text != null && info.offsets.isNotEmpty) {
          debugPrint('Drawing text: "${info.text}" at ${info.offsets[0]}');
          _drawText(canvas, info.text!, info.offsets[0]!, info.color, info.strokeWidth);
          debugPrint('Text drawing completed');
        }
        break;
      case PaintMode.arrow:
        if (info.offsets.length >= 2) {
          _drawArrow(canvas, info.offsets[0]!, info.offsets[1]!, paint);
          debugPrint('Drew arrow from ${info.offsets[0]} to ${info.offsets[1]}');
        }
        break;
      case PaintMode.dashedLine:
        if (info.offsets.length >= 2) {
          _drawDashedLine(canvas, info.offsets[0]!, info.offsets[1]!, paint);
          debugPrint('Drew dashed line from ${info.offsets[0]} to ${info.offsets[1]}');
        }
        break;
      default:
        debugPrint('Skipping unsupported paint mode: ${info.mode}');
        break;
    }
  }

  void _drawFreeStyle(Canvas canvas, List<Offset?> offsets, Paint paint) {
    if (offsets.isEmpty) return;
    
    final path = Path();
    bool hasMovedTo = false;
    
    for (int i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      if (offset == null) {
        hasMovedTo = false;
      } else {
        if (!hasMovedTo) {
          path.moveTo(offset.dx, offset.dy);
          hasMovedTo = true;
        } else {
          // Use quadratic bezier curves for smoother lines
          if (i > 0 && offsets[i - 1] != null) {
            final prevOffset = offsets[i - 1]!;
            final midPoint = Offset(
              (prevOffset.dx + offset.dx) / 2,
              (prevOffset.dy + offset.dy) / 2,
            );
            path.quadraticBezierTo(prevOffset.dx, prevOffset.dy, midPoint.dx, midPoint.dy);
          } else {
            path.lineTo(offset.dx, offset.dy);
          }
        }
      }
    }
    
    canvas.drawPath(path, paint);
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize) {
    debugPrint('=== Drawing Text ===');
    debugPrint('Text: "$text"');
    debugPrint('Offset: $offset');
    debugPrint('Color: $color');
    debugPrint('Font size: $fontSize (will be scaled to ${fontSize * 4})');
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize * 4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    debugPrint('Text painter layout size: ${textPainter.size}');
    debugPrint('About to paint text at offset: $offset');
    
    textPainter.paint(canvas, offset);
    debugPrint('Text painting completed');
    
    textPainter.dispose(); // Prevent memory leaks
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    
    const arrowHeadLength = 20.0;
    const arrowHeadAngle = 0.5;
    
    final direction = (end - start);
    final length = direction.distance;
    if (length <= 0) return;
    
    final unitVector = direction / length;
    final angle = math.atan2(unitVector.dy, unitVector.dx);
    
    final arrowHead1 = end - Offset(
      arrowHeadLength * math.cos(angle - arrowHeadAngle),
      arrowHeadLength * math.sin(angle - arrowHeadAngle),
    );
    final arrowHead2 = end - Offset(
      arrowHeadLength * math.cos(angle + arrowHeadAngle),
      arrowHeadLength * math.sin(angle + arrowHeadAngle),
    );
    
    canvas.drawLine(end, arrowHead1, paint);
    canvas.drawLine(end, arrowHead2, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Scale dash length and gap based on stroke width
    final dashLength = 8.0 + (paint.strokeWidth * 2);
    final dashGap = 4.0 + (paint.strokeWidth * 1.5);
    
    final direction = end - start;
    final distance = direction.distance;
    if (distance <= 0) return;
    
    final unitVector = direction / distance;
    
    double currentDistance = 0;
    bool drawDash = true;
    
    while (currentDistance < distance) {
      final segmentLength = drawDash ? dashLength : dashGap;
      final nextDistance = math.min(currentDistance + segmentLength, distance);
      
      if (drawDash) {
        final segmentStart = start + unitVector * currentDistance;
        final segmentEnd = start + unitVector * nextDistance;
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }
      
      currentDistance = nextDistance;
      drawDash = !drawDash;
    }
  }

  void _drawCurrentStroke(Canvas canvas) {
    final paint = Paint()
      ..color = controller.color.withOpacity(0.9)
      ..strokeWidth = controller.strokeWidth // Same stroke width as final
      ..style = controller.fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.srcOver; // Ensure current stroke draws over background
    
    switch (controller.mode) {
      case PaintMode.line:
        canvas.drawLine(controller.start!, controller.end!, paint);
        break;
      case PaintMode.rect:
        final rect = Rect.fromPoints(controller.start!, controller.end!);
        canvas.drawRect(rect, paint);
        break;
      case PaintMode.circle:
        final radius = (controller.end! - controller.start!).distance;
        canvas.drawCircle(controller.start!, radius, paint);
        break;
      case PaintMode.freeStyle:
        // For freestyle, draw the current stroke being drawn
        if (controller.offsets.isNotEmpty) {
          _drawFreeStyle(canvas, controller.offsets, paint);
        }
        break;
      case PaintMode.arrow:
        _drawArrow(canvas, controller.start!, controller.end!, paint);
        break;
      case PaintMode.dashedLine:
        _drawDashedLine(canvas, controller.start!, controller.end!, paint);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Always repaint during active drawing for real-time preview
    if (controller.inProgress) {
      return true;
    }
    
    if (oldDelegate is! EnhancedImageCustomPainter) return true;
    
    return controller.shouldRepaint ||
           oldDelegate.controller.paintHistory.length != controller.paintHistory.length ||
           oldDelegate.controller.inProgress != controller.inProgress ||
           oldDelegate.controller.start != controller.start ||
           oldDelegate.controller.end != controller.end ||
           oldDelegate.controller.offsets.length != controller.offsets.length;
  }
}