# Enhanced Image Painter

A **production-ready** Flutter package for drawing, annotating, and editing images with advanced real-time features and seamless FlutterFlow integration.

## ✨ **Advanced Features**

### 🎨 **Complete Drawing Toolkit**
- **Freehand Drawing**: Smooth brush strokes with pressure sensitivity
- **Geometric Shapes**: Rectangle, Circle, Line with **real-time preview**
- **Advanced Tools**: Arrows and Dashed Lines with customizable patterns
- **Text Annotations**: Click-to-add text with **drag-and-drop repositioning**

### 🔄 **Real-Time Interactive Features**
- **Live Shape Preview**: See shapes as you draw them before committing
- **Text Drag & Drop**: Click to add text, then drag to reposition anywhere
- **Instant Visual Feedback**: All tools provide immediate visual response
- **Smooth Gesture Handling**: Optimized for touch and mouse interactions

### 🎛️ **Professional UI Controls**
- **Full Toolbar**: Save, Undo, Clear with visual feedback
- **Color Palette**: Rich color picker with custom colors
- **Brush Controls**: Adjustable stroke width and fill options
- **Mode Switching**: Seamless tool switching with clear visual indicators

### 💾 **Production Export Features**
- **High-Quality PNG Export**: Full resolution with all annotations
- **Background Integration**: Preserve background images in exports
- **Undo System**: Complete action history management

### 📱 **FlutterFlow Ready**
- **Zero Configuration**: Drop-in widget for FlutterFlow projects
- **Firebase Integration**: Built-in Firestore and Storage support
- **Custom Parameters**: Width, height, background image support
- **Production Tested**: Stable and reliable for commercial applications

## 🚀 **Quick Start**

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  enhanced_image_painter: ^1.2.4
```

### Basic Usage

```dart
import 'package:enhanced_image_painter/enhanced_image_painter.dart';

EnhancedImagePainter(
  width: 400,
  height: 300,
  bgImage: 'https://example.com/background.jpg', // Optional
  config: EnhancedImagePainterConfig(
    enabledModes: [
      PaintMode.freeStyle,
      PaintMode.line,
      PaintMode.rect,
      PaintMode.circle,
      PaintMode.text,
      PaintMode.arrow,
      PaintMode.dashedLine,
    ],
    defaultStrokeWidth: 3.0,
    defaultColor: Colors.red,
    showColorTool: true,
    showStrokeTool: true,
    toolbarAtTop: false,
    onSave: () async {
      // Custom save logic
      print('Save button pressed');
    },
    onUndo: () => print('Undo pressed'),
    onClear: () => print('Clear pressed'),
  ),
)
```

## 🔥 **Advanced Features in Action**

### Real-Time Shape Preview
```dart
// Shapes appear as you draw them
// Perfect visual feedback for precise drawing
PaintMode.rect     // Rectangle with live preview
PaintMode.circle   // Circle with live preview  
PaintMode.line     // Line with live preview
PaintMode.arrow    // Arrow with live preview
```

### Interactive Text System
```dart
// 1. Select text mode
// 2. Click anywhere to add text
// 3. Drag text to reposition
// 4. All text remains interactive and moveable
PaintMode.text  // Click to add, drag to move
```

### Professional Toolbar
```dart
EnhancedImagePainterConfig(
  toolbarAtTop: true,              // Position toolbar
  toolbarBackgroundColor: Colors.black87,
  showColorTool: true,             // Color picker
  showStrokeTool: true,            // Brush size
  showFillOption: true,            // Fill shapes
)
```

## � **FlutterFlow Integration**

### Ready-to-Use Widget
Use the included `FF_Simple_Test_Widget.dart` for instant FlutterFlow integration:

```dart
// In FlutterFlow Custom Widget
ImagePainterWidget(
  width: 400,
  height: 300,
  bgImage: 'https://example.com/image.jpg',
)
```

### Features Included:
- ✅ **Firebase Storage Integration**: Image upload capable
- ✅ **All Drawing Tools**: Complete toolkit ready to use
- ✅ **Production Ready**: Tested and stable for commercial apps

## 🎛️ **Configuration Options**

### Available Paint Modes
```dart
PaintMode.freeStyle    // Brush drawing
PaintMode.line         // Straight lines with preview
PaintMode.rect         // Rectangles with preview  
PaintMode.circle       // Circles with preview
PaintMode.text         // Drag-and-drop text
PaintMode.arrow        // Arrow lines with preview
PaintMode.dashedLine   // Dashed lines with preview
```

### Toolbar Customization
```dart
EnhancedImagePainterConfig(
  enabledModes: [...],           // Choose which tools to show
  defaultStrokeWidth: 3.0,       // Default brush size
  defaultColor: Colors.red,      // Default color
  showColorTool: true,           // Show color picker
  showStrokeTool: true,          // Show brush size control
  showFillOption: true,          // Show fill option for shapes
  toolbarAtTop: false,           // Toolbar position
  toolbarBackgroundColor: Colors.grey[800], // Toolbar styling
)
```

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 **Contributing**

Contributions are welcome! This is a production-ready package that powers real applications.

---

**Built for production use with real-time features and FlutterFlow integration.**