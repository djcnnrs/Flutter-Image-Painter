# Enhanced Image Painter

A comprehensive Flutter package for drawing, annotating, and editing images with advanced features including customizable backgrounds, export functionality, and FlutterFlow integration.

## ✨ Features

- **Drawing Tools**: Brush, pen, rectangle, circle, line, arrow
- **Text Annotations**: Add text with customizable styles
- **Background Types**: Graph paper, lined notebook, blank canvas, network images
- **Customizable Interface**: Show/hide controls, color picker, brush size slider
- **Export Functionality**: Save as PNG with all annotations and backgrounds
- **Undo/Redo**: Full history management
- **FlutterFlow Ready**: Optimized for FlutterFlow integration

## 🚀 Quick Start

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  enhanced_image_painter: ^1.0.0
```

Or for local development:

```yaml
dependencies:
  enhanced_image_painter:
    path: path/to/enhanced_image_painter
```

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:enhanced_image_painter/enhanced_image_painter.dart';

class MyPainterPage extends StatefulWidget {
  @override
  _MyPainterPageState createState() => _MyPainterPageState();
}

class _MyPainterPageState extends State<MyPainterPage> {
  late EnhancedImagePainterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EnhancedImagePainterController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EnhancedImagePainter(
        controller: _controller,
        width: double.infinity,
        height: double.infinity,
        backgroundType: PainterBackgroundType.graphPaper,
        showControls: true,
        enableSave: true,
        onSave: (imageBytes) async {
          // Handle save functionality
          print('Image saved with ${imageBytes.length} bytes');
        },
      ),
    );
  }
}
```

## 🎨 Background Types

```dart
// Graph paper background
backgroundType: PainterBackgroundType.graphPaper

// Lined notebook background  
backgroundType: PainterBackgroundType.linedNotebook

// Blank white canvas
backgroundType: PainterBackgroundType.blank

// Network image background
backgroundType: PainterBackgroundType.networkImage
backgroundImageUrl: 'https://example.com/image.jpg'
```

## 🛠️ FlutterFlow Integration

For FlutterFlow projects, use the provided custom widget template (`FF_Enhanced_Image_Painter.dart`) that handles all the complexity internally.

See `FF_Enhanced_Setup_Guide.md` for detailed FlutterFlow integration instructions.

## 📚 API Reference

### EnhancedImagePainter Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `controller` | `EnhancedImagePainterController` | Required | Controller for the painter |
| `width` | `double` | Required | Width of the painter canvas |
| `height` | `double` | Required | Height of the painter canvas |
| `backgroundType` | `PainterBackgroundType` | `blank` | Type of background |
| `backgroundImageUrl` | `String?` | `null` | URL for network image background |
| `showControls` | `bool` | `true` | Show/hide the control toolbar |
| `showColorPicker` | `bool` | `true` | Show/hide color picker |
| `showBrushSizeSlider` | `bool` | `true` | Show/hide brush size slider |
| `enableUndo` | `bool` | `true` | Enable undo functionality |
| `enableClear` | `bool` | `true` | Enable clear functionality |
| `enableSave` | `bool` | `true` | Enable save functionality |
| `onSave` | `Function(Uint8List)?` | `null` | Callback when save is triggered |

### Controller Methods

```dart
// Drawing operations
controller.setMode(PainterMode.brush);
controller.setColor(Colors.red);
controller.setBrushSize(5.0);

// History operations
controller.undo();
controller.redo();
controller.clear();

// Export
Uint8List? imageBytes = await controller.exportImage();
```

## 🧪 Running the Example

```bash
cd example
flutter pub get
flutter run
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.