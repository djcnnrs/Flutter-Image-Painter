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
    debugPrint('Exporting image with size: ${size.width}x${size.height}');
    debugPrint('Background type: $backgroundType');
    debugPrint('Background image: ${backgroundImage != null ? '${backgroundImage!.width}x${backgroundImage!.height}' : 'null'}');
    debugPrint('Background image URL: $_backgroundImageUrl');
    debugPrint('Paint history length: ${_paintHistory.length}');
    
    try {
      // Ensure background image is loaded for network images
      if (_backgroundType == BackgroundType.networkImage && 
          _backgroundImageUrl != null && 
          _backgroundImage == null) {
        debugPrint('Loading background image before export...');
        await loadBackgroundImage(_backgroundImageUrl!);
        if (_backgroundImage == null) {
          debugPrint('Warning: Failed to load background image for export');
        } else {
          debugPrint('Background image loaded successfully for export: ${_backgroundImage!.width}x${_backgroundImage!.height}');
        }
      }
      
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      
      debugPrint('Starting export drawing...');
      
      // Step 1: Only draw white background for non-network images
      if (_backgroundType != BackgroundType.networkImage) {
        canvas.drawRect(rect, Paint()..color = Colors.white);
        debugPrint('Drew white background base (non-network image)');
      }
      
      // Step 2: Draw background image if we have one
      if (_backgroundType == BackgroundType.networkImage && _backgroundImage != null) {
        debugPrint('Drawing network image: ${_backgroundImage!.width}x${_backgroundImage!.height}');
        
        // Calculate scaling to fit the canvas while maintaining aspect ratio
        final imageWidth = _backgroundImage!.width.toDouble();
        final imageHeight = _backgroundImage!.height.toDouble();
        final scaleX = size.width / imageWidth;
        final scaleY = size.height / imageHeight;
        final scale = math.min(scaleX, scaleY);
        
        final scaledWidth = imageWidth * scale;
        final scaledHeight = imageHeight * scale;
        final offsetX = (size.width - scaledWidth) / 2;
        final offsetY = (size.height - scaledHeight) / 2;
        
        final destRect = Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
        final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);
        
        // First fill the area with white to avoid transparent edges
        canvas.drawRect(rect, Paint()..color = Colors.white);
        
        // Use explicit paint settings to ensure proper rendering
        final imagePaint = Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high;
        
        canvas.drawImageRect(_backgroundImage!, srcRect, destRect, imagePaint);
        debugPrint('Network image drawn: ${scaledWidth}x${scaledHeight} at (${offsetX}, ${offsetY})');
        
        // Verify the image was drawn by checking a sample pixel
        // This is a debugging step that will help us understand if the image is actually being rendered
        debugPrint('Image drawn to canvas - Scale: $scale, DestRect: $destRect');
      } else if (_backgroundType == BackgroundType.graphPaper) {
        // Draw graph paper
        canvas.drawRect(rect, Paint()..color = Colors.white);
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
        debugPrint('Drew graph paper background');
      } else if (_backgroundType == BackgroundType.linedNotebook) {
        // Draw lined notebook
        canvas.drawRect(rect, Paint()..color = Colors.white);
        final paint = Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = 1;
        const lineSpacing = 25.0;
        for (double y = lineSpacing; y <= size.height; y += lineSpacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        debugPrint('Drew lined notebook background');
      } else if (_backgroundType == BackgroundType.blankCanvas) {
        canvas.drawRect(rect, Paint()..color = _backgroundColor);
        debugPrint('Drew blank canvas background');
      }
      
      // Step 3: Draw all annotations with proper blend modes
      debugPrint('Drawing ${_paintHistory.length} annotations');
      for (int i = 0; i < _paintHistory.length; i++) {
        final info = _paintHistory[i];
        debugPrint('Drawing item $i: ${info.mode}');
        
        switch (info.mode) {
          case PaintMode.freeStyle:
            if (info.offsets.isNotEmpty) {
              final paint = Paint()
                ..color = info.color
                ..strokeWidth = info.strokeWidth
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke
                ..blendMode = BlendMode.srcOver;
              
              final path = Path();
              bool hasMovedTo = false;
              for (final offset in info.offsets) {
                if (offset == null) {
                  hasMovedTo = false;
                } else {
                  if (!hasMovedTo) {
                    path.moveTo(offset.dx, offset.dy);
                    hasMovedTo = true;
                  } else {
                    path.lineTo(offset.dx, offset.dy);
                  }
                }
              }
              canvas.drawPath(path, paint);
              debugPrint('Drew freeStyle path with ${info.offsets.length} points');
            }
            break;
            
          case PaintMode.line:
            if (info.offsets.length >= 2 && info.offsets[0] != null && info.offsets[1] != null) {
              final paint = Paint()
                ..color = info.color
                ..strokeWidth = info.strokeWidth
                ..strokeCap = StrokeCap.round
                ..blendMode = BlendMode.srcOver;
              canvas.drawLine(info.offsets[0]!, info.offsets[1]!, paint);
              debugPrint('Drew line from ${info.offsets[0]} to ${info.offsets[1]}');
            }
            break;
            
          case PaintMode.rect:
            if (info.offsets.length >= 2 && info.offsets[0] != null && info.offsets[1] != null) {
              final paint = Paint()
                ..color = info.color
                ..strokeWidth = info.strokeWidth
                ..style = info.fill ? PaintingStyle.fill : PaintingStyle.stroke
                ..blendMode = BlendMode.srcOver;
              final rect = Rect.fromPoints(info.offsets[0]!, info.offsets[1]!);
              canvas.drawRect(rect, paint);
              debugPrint('Drew rectangle: $rect');
            }
            break;
            
          case PaintMode.circle:
            if (info.offsets.length >= 2 && info.offsets[0] != null && info.offsets[1] != null) {
              final paint = Paint()
                ..color = info.color
                ..strokeWidth = info.strokeWidth
                ..style = info.fill ? PaintingStyle.fill : PaintingStyle.stroke
                ..blendMode = BlendMode.srcOver;
              final center = info.offsets[0]!;
              final radius = (info.offsets[1]! - center).distance;
              canvas.drawCircle(center, radius, paint);
              debugPrint('Drew circle at $center with radius $radius');
            }
            break;
            
          case PaintMode.text:
            if (info.text != null && info.offsets.isNotEmpty && info.offsets[0] != null) {
              debugPrint('Drawing text: "${info.text}" at ${info.offsets[0]} with fontSize ${info.strokeWidth * 4}');
              
              final textSpan = TextSpan(
                text: info.text!,
                style: TextStyle(
                  color: info.color,
                  fontSize: info.strokeWidth * 4,
                  fontWeight: FontWeight.bold,
                ),
              );
              
              final textPainter = TextPainter(
                text: textSpan,
                textDirection: TextDirection.ltr,
              );
              
              textPainter.layout();
              final textSize = Size(textPainter.width, textPainter.height);
              textPainter.paint(canvas, info.offsets[0]!);
              textPainter.dispose();
              
              debugPrint('Text painted successfully with size: ${textSize.width}x${textSize.height}');
            }
            break;
            
          case PaintMode.arrow:
            if (info.offsets.length >= 2 && info.offsets[0] != null && info.offsets[1] != null) {
              final paint = Paint()
                ..color = info.color
                ..strokeWidth = info.strokeWidth
                ..strokeCap = StrokeCap.round
                ..blendMode = BlendMode.srcOver;
              
              final start = info.offsets[0]!;
              final end = info.offsets[1]!;
              
              // Draw main line
              canvas.drawLine(start, end, paint);
              
              // Draw arrow head
              const arrowHeadLength = 20.0;
              const arrowHeadAngle = 0.5;
              final direction = (end - start);
              final length = direction.distance;
              
              if (length > 0) {
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
              debugPrint('Drew arrow from $start to $end');
            }
            break;
            
          case PaintMode.dashedLine:
            if (info.offsets.length >= 2 && info.offsets[0] != null && info.offsets[1] != null) {
              final paint = Paint()
                ..color = info.color
                ..strokeWidth = info.strokeWidth
                ..strokeCap = StrokeCap.round
                ..blendMode = BlendMode.srcOver;
              
              final start = info.offsets[0]!;
              final end = info.offsets[1]!;
              final dashLength = 8.0 + (info.strokeWidth * 2);
              final dashGap = 4.0 + (info.strokeWidth * 1.5);
              final direction = end - start;
              final distance = direction.distance;
              
              if (distance > 0) {
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
              debugPrint('Drew dashed line from $start to $end');
            }
            break;
            
          default:
            debugPrint('Skipping unsupported paint mode: ${info.mode}');
            break;
        }
      }
      
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      
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
          return byteData?.buffer.asUint8List();
        }
      }
      
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      debugPrint('Export completed, final image size: ${byteData?.lengthInBytes} bytes');
      return byteData?.buffer.asUint8List();
      
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
    try {
      final completer = Completer<ui.Image>();
      final img = NetworkImage(url);
      img.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) {
          completer.complete(info.image);
        }, onError: (error, stackTrace) {
          completer.completeError(error);
        })
      );
      _backgroundImage = await completer.future;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load background image: $e');
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
    // Always draw background first, before any annotations
    _drawBackground(canvas, size);
    
    // Draw all completed strokes
    for (final info in controller.paintHistory) {
      _drawPaintInfo(canvas, info);
    }
    
    // Draw current stroke being drawn (real-time preview)
    if (controller.inProgress && controller.start != null && controller.end != null) {
      _drawCurrentStroke(canvas);
    }
    
    controller._clearRepaintFlag();
  }

  void _drawBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    switch (controller.backgroundType) {
      case BackgroundType.blankCanvas:
        canvas.drawRect(rect, Paint()..color = controller.backgroundColor);
        break;
      case BackgroundType.graphPaper:
        _drawGraphPaper(canvas, size);
        break;
      case BackgroundType.linedNotebook:
        _drawLinedNotebook(canvas, size);
        break;
      case BackgroundType.networkImage:
        if (controller.backgroundImage != null) {
          // First, fill the background with white to ensure no transparency
          canvas.drawRect(rect, Paint()..color = Colors.white);
          
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
        } else {
          // Fallback to white background if image failed to load
          canvas.drawRect(rect, Paint()..color = Colors.white);
        }
        break;
      case BackgroundType.none:
      default:
        canvas.drawRect(rect, Paint()..color = Colors.white);
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
    final paint = Paint()
      ..color = info.color
      ..strokeWidth = info.strokeWidth
      ..style = info.fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.srcOver; // Ensure annotations draw over background

    switch (info.mode) {
      case PaintMode.freeStyle:
        _drawFreeStyle(canvas, info.offsets, paint);
        break;
      case PaintMode.line:
        if (info.offsets.length >= 2) {
          canvas.drawLine(info.offsets[0]!, info.offsets[1]!, paint);
        }
        break;
      case PaintMode.rect:
        if (info.offsets.length >= 2) {
          final rect = Rect.fromPoints(info.offsets[0]!, info.offsets[1]!);
          canvas.drawRect(rect, paint);
        }
        break;
      case PaintMode.circle:
        if (info.offsets.length >= 2) {
          final center = info.offsets[0]!;
          final radius = (info.offsets[1]! - center).distance;
          canvas.drawCircle(center, radius, paint);
        }
        break;
      case PaintMode.text:
        if (info.text != null && info.offsets.isNotEmpty) {
          _drawText(canvas, info.text!, info.offsets[0]!, info.color, info.strokeWidth);
        }
        break;
      case PaintMode.arrow:
        if (info.offsets.length >= 2) {
          _drawArrow(canvas, info.offsets[0]!, info.offsets[1]!, paint);
        }
        break;
      case PaintMode.dashedLine:
        if (info.offsets.length >= 2) {
          _drawDashedLine(canvas, info.offsets[0]!, info.offsets[1]!, paint);
        }
        break;
      default:
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
    textPainter.paint(canvas, offset);
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