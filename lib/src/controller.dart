import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../image_painter.dart';
import '_signature_painter.dart';

// Enum for background types
enum BackgroundType {
  graphPaper,
  linedNotebook,
  blankCanvas,
  networkImage,
  none
}

// Toolbar configuration class
class ToolbarConfig {
  final bool showBrushTool;
  final bool showColorTool;
  final bool showStrokeTool;
  final bool showTextTool;
  final bool showShapesTools;
  final bool showUndoTool;
  final bool showClearTool;
  final bool showSaveTool;
  
  const ToolbarConfig({
    this.showBrushTool = true,
    this.showColorTool = true,
    this.showStrokeTool = true,
    this.showTextTool = true,
    this.showShapesTools = true,
    this.showUndoTool = true,
    this.showClearTool = true,
    this.showSaveTool = false,
  });
}

class ImagePainterController extends ChangeNotifier {
  late double _strokeWidth;
  late Color _color;
  late PaintMode _mode;
  late String _text;
  late bool _fill;
  late ui.Image? _image;
  Rect _rect = Rect.zero;

  // Background properties
  BackgroundType _backgroundType = BackgroundType.none;
  String? _backgroundImageUrl;
  Color _backgroundColor = Colors.white;
  
  // Toolbar configuration
  ToolbarConfig _toolbarConfig = const ToolbarConfig();
  
  // Custom save callback
  VoidCallback? _onSave;

  final List<Offset?> _offsets = [];

  final List<PaintInfo> _paintHistory = [];

  Offset? _start, _end;

  int _strokeMultiplier = 1;
  bool _paintInProgress = false;
  bool _isSignature = false;

  ui.Image? get image => _image;
  BackgroundType get backgroundType => _backgroundType;
  String? get backgroundImageUrl => _backgroundImageUrl;
  Color get backgroundColor => _backgroundColor;
  ToolbarConfig get toolbarConfig => _toolbarConfig;
  VoidCallback? get onSave => _onSave;

  Paint get brush => Paint()
    ..color = _color
    ..strokeWidth = _strokeWidth * _strokeMultiplier
    ..style = shouldFill ? PaintingStyle.fill : PaintingStyle.stroke;

  PaintMode get mode => _mode;

  double get strokeWidth => _strokeWidth;

  double get scaledStrokeWidth => _strokeWidth * _strokeMultiplier;

  bool get busy => _paintInProgress;

  bool get fill => _fill;

  Color get color => _color;

  List<PaintInfo> get paintHistory => _paintHistory;

  List<Offset?> get offsets => _offsets;

  Offset? get start => _start;

  Offset? get end => _end;

  bool get onTextUpdateMode =>
      _mode == PaintMode.text &&
      _paintHistory
          .where((element) => element.mode == PaintMode.text)
          .isNotEmpty;

  ImagePainterController({
    double strokeWidth = 4.0,
    Color color = Colors.red,
    PaintMode mode = PaintMode.freeStyle,
    String text = '',
    bool fill = false,
    BackgroundType backgroundType = BackgroundType.none,
    String? backgroundImageUrl,
    Color backgroundColor = Colors.white,
    ToolbarConfig? toolbarConfig,
    VoidCallback? onSave,
  }) {
    _strokeWidth = strokeWidth;
    _color = color;
    _mode = mode;
    _text = text;
    _fill = fill;
    _backgroundType = backgroundType;
    _backgroundImageUrl = backgroundImageUrl;
    _backgroundColor = backgroundColor;
    _toolbarConfig = toolbarConfig ?? const ToolbarConfig();
    _onSave = onSave;
  }

  void setImage(ui.Image image) {
    _image = image;
    notifyListeners();
  }

  void setRect(Size size) {
    _rect = Rect.fromLTWH(0, 0, size.width, size.height);
    _isSignature = true;
    notifyListeners();
  }

  void addPaintInfo(PaintInfo paintInfo) {
    _paintHistory.add(paintInfo);
    notifyListeners();
  }

  void undo() {
    if (_paintHistory.isNotEmpty) {
      _paintHistory.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    if (_paintHistory.isNotEmpty) {
      _paintHistory.clear();
      notifyListeners();
    }
  }

  void setStrokeWidth(double val) {
    _strokeWidth = val;
    notifyListeners();
  }

  void setColor(Color color) {
    _color = color;
    notifyListeners();
  }

  void setMode(PaintMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setText(String val) {
    _text = val;
    notifyListeners();
  }

  void addOffsets(Offset? offset) {
    _offsets.add(offset);
    notifyListeners();
  }

  void setStart(Offset? offset) {
    _start = offset;
    notifyListeners();
  }

  void setEnd(Offset? offset) {
    _end = offset;
    notifyListeners();
  }

  void resetStartAndEnd() {
    _start = null;
    _end = null;
    notifyListeners();
  }

  void update({
    double? strokeWidth,
    Color? color,
    bool? fill,
    PaintMode? mode,
    String? text,
    int? strokeMultiplier,
    BackgroundType? backgroundType,
    String? backgroundImageUrl,
    Color? backgroundColor,
    ToolbarConfig? toolbarConfig,
  }) {
    _strokeWidth = strokeWidth ?? _strokeWidth;
    _color = color ?? _color;
    _fill = fill ?? _fill;
    _mode = mode ?? _mode;
    _text = text ?? _text;
    _strokeMultiplier = strokeMultiplier ?? _strokeMultiplier;
    _backgroundType = backgroundType ?? _backgroundType;
    _backgroundImageUrl = backgroundImageUrl ?? _backgroundImageUrl;
    _backgroundColor = backgroundColor ?? _backgroundColor;
    _toolbarConfig = toolbarConfig ?? _toolbarConfig;
    notifyListeners();
  }

  void setInProgress(bool val) {
    _paintInProgress = val;
    notifyListeners();
  }

  void setBackground({
    BackgroundType? type,
    String? imageUrl,
    Color? color,
  }) {
    _backgroundType = type ?? _backgroundType;
    _backgroundImageUrl = imageUrl;
    _backgroundColor = color ?? _backgroundColor;
    notifyListeners();
  }
  
  void setToolbarConfig(ToolbarConfig config) {
    _toolbarConfig = config;
    notifyListeners();
  }
  
  void setSaveCallback(VoidCallback? callback) {
    _onSave = callback;
    notifyListeners();
  }

  bool get shouldFill {
    if (mode == PaintMode.circle || mode == PaintMode.rect) {
      return _fill;
    } else {
      return false;
    }
  }

  /// Generates [Uint8List] of the [ui.Image] generated by the [renderImage()] method.
  /// Can be converted to image file by writing as bytes.
  Future<Uint8List?> _renderImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = DrawImage(controller: this);
    Size size;
    
    if (_image != null) {
      size = Size(_image!.width.toDouble(), _image!.height.toDouble());
    } else {
      // Use a default size for background-only images
      size = const Size(800, 600);
    }
    
    painter.paint(canvas, size);
    final _convertedImage = await recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());
    final byteData =
        await _convertedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<Uint8List?> _renderSignature() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    SignaturePainter painter =
        SignaturePainter(controller: this, backgroundColor: Colors.blue);

    Size size = Size(_rect.width, _rect.height);

    painter.paint(canvas, size);
    final _convertedImage = await recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());
    final byteData =
        await _convertedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<Uint8List?> exportImage() {
    if (_isSignature) {
      return _renderSignature();
    } else {
      return _renderImage();
    }
  }
}

extension ControllerExt on ImagePainterController {
  bool canFill() {
    return mode == PaintMode.circle || mode == PaintMode.rect;
  }
}
