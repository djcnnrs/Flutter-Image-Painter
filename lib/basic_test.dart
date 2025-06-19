// Absolute minimal test for FlutterFlow compatibility
// No imports, just basic enums

enum SimplePaintMode { 
  freeStyle, 
  line, 
  rect, 
  circle 
}

class SimpleConfig {
  final SimplePaintMode mode;
  final double strokeWidth;
  
  const SimpleConfig({
    this.mode = SimplePaintMode.freeStyle,
    this.strokeWidth = 2.0,
  });
}
