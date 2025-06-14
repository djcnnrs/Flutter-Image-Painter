/// FlutterFlow-compatible Image Painter
/// 
/// This library provides a simplified version of the Image Painter
/// specifically designed for FlutterFlow custom widgets.
/// 
/// Features:
/// - No callbacks required (FlutterFlow doesn't support them)
/// - Simple parameter-based configuration
/// - Background patterns (graph paper, lined notebook, blank canvas)
/// - Customizable toolbar
/// - Export functionality accessible via widget state
/// 
/// Usage in FlutterFlow:
/// 1. Add this as a custom widget
/// 2. Configure using the simple parameters
/// 3. Use widget state methods for export/clear actions
/// 
library flutterflow_image_painter;

export 'src/flutterflow_widget.dart';
export 'src/flutterflow_controller.dart';
export 'src/controller.dart' show BackgroundType, PaintMode, PaintInfo;
