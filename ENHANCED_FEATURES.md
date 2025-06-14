# Enhanced Image Painter Features

This fork of the Flutter Image Painter package includes the following enhanced features:

## 🎨 New Features

### 1. Customizable Toolbar
Control which tools are visible in the toolbar using `ToolbarConfig`:

```dart
final controller = ImagePainterController(
  toolbarConfig: ToolbarConfig(
    showTextTool: false,      // Hide text tool
    showShapesTools: true,    // Show shape tools (rectangle, circle, arrow, dash line)
    showBrushTool: true,      // Show brush/mode selector
    showColorTool: true,      // Show color picker
    showStrokeTool: true,     // Show stroke width slider
    showUndoTool: true,       // Show undo button
    showClearTool: true,      // Show clear all button
    showSaveTool: true,       // Show save button
  ),
);
```

### 2. Background Support
Support for multiple background types including special patterns and network images:

#### Available Background Types:
- **`BackgroundType.blankCanvas`** - Solid color background (white by default)
- **`BackgroundType.graphPaper`** - Grid pattern background
- **`BackgroundType.linedNotebook`** - Lined paper with margin
- **`BackgroundType.networkImage`** - Image from URL as background
- **`BackgroundType.none`** - No background (transparent)

#### Usage Examples:

**Graph Paper Background:**
```dart
ImagePainter.withBackground(
  controller: controller,
  backgroundType: BackgroundType.graphPaper,
  height: 400,
  width: 400,
)
```

**Network Image Background:**
```dart
ImagePainter.withBackground(
  controller: controller,
  backgroundType: BackgroundType.networkImage,
  backgroundImageUrl: 'https://example.com/image.jpg',
  height: 400,
  width: 400,
)
```

**Lined Notebook Background:**
```dart
ImagePainter.withBackground(
  controller: controller,
  backgroundType: BackgroundType.linedNotebook,
  height: 400,
  width: 400,
)
```

### 3. Enhanced Export Functionality
Export images with all annotations including backgrounds:

```dart
// Export the complete image with all annotations and background
final Uint8List? exportedImage = await controller.exportImage();

if (exportedImage != null) {
  // Save to file, upload to cloud storage, etc.
  File('path/to/save/image.png').writeAsBytesSync(exportedImage);
}
```

### 4. Custom Save Button Logic
Add custom logic to the default toolbar save button:

```dart
final controller = ImagePainterController(
  toolbarConfig: ToolbarConfig(showSaveTool: true),
  onSave: () {
    // Custom save logic
    uploadToFirebase();
    updateFirestore();
    showSuccessDialog();
  },
);

// Or handle save in the widget
ImagePainter.withBackground(
  controller: controller,
  backgroundType: BackgroundType.blankCanvas,
  onSave: () async {
    final imageData = await controller.exportImage();
    // Upload to your preferred service
    await uploadToCloud(imageData);
  },
)
```

### 5. Runtime Configuration Changes
Dynamically change backgrounds and toolbar configuration:

```dart
// Change background at runtime
controller.setBackground(
  type: BackgroundType.graphPaper,
  color: Colors.lightBlue.shade50,
);

// Update toolbar configuration
controller.setToolbarConfig(
  ToolbarConfig(
    showTextTool: false,  // Hide text tool
    showShapesTools: true,
  ),
);

// Set custom save callback
controller.setSaveCallback(() {
  // New save logic
});
```

## 📖 Complete Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';

class MyPainterWidget extends StatefulWidget {
  @override
  _MyPainterWidgetState createState() => _MyPainterWidgetState();
}

class _MyPainterWidgetState extends State<MyPainterWidget> {
  late ImagePainterController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController(
      backgroundType: BackgroundType.graphPaper,
      backgroundColor: Colors.white,
      toolbarConfig: ToolbarConfig(
        showTextTool: true,
        showShapesTools: true,
        showSaveTool: true,
      ),
      onSave: _handleSave,
    );
  }
  
  void _handleSave() async {
    try {
      final imageData = await _controller.exportImage();
      if (imageData != null) {
        // Save to gallery, upload to Firebase, etc.
        await saveToGallery(imageData);
        showSuccessSnackbar();
      }
    } catch (e) {
      showErrorSnackbar(e.toString());
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enhanced Image Painter'),
        actions: [
          PopupMenuButton<BackgroundType>(
            onSelected: (type) {
              _controller.setBackground(type: type);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: BackgroundType.blankCanvas,
                child: Text('Blank Canvas'),
              ),
              PopupMenuItem(
                value: BackgroundType.graphPaper,
                child: Text('Graph Paper'),
              ),
              PopupMenuItem(
                value: BackgroundType.linedNotebook,
                child: Text('Lined Notebook'),
              ),
            ],
          ),
        ],
      ),
      body: ImagePainter.withBackground(
        controller: _controller,
        backgroundType: BackgroundType.graphPaper,
        height: double.infinity,
        width: double.infinity,
        onSave: _handleSave,
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## 🔧 Migration from Original Package

If you're migrating from the original image_painter package:

1. **Basic usage remains the same** - all existing constructors work unchanged
2. **Add new features gradually** - use `ImagePainter.withBackground()` for new features
3. **Toolbar customization is optional** - default `ToolbarConfig()` shows all tools
4. **Export functionality enhanced** - `exportImage()` now includes background rendering

## 🚀 Advanced Features

### Firebase Integration Example
```dart
Future<void> uploadToFirebase() async {
  final imageData = await controller.exportImage();
  if (imageData != null) {
    final ref = FirebaseStorage.instance.ref().child('paintings/${DateTime.now().millisecondsSinceEpoch}.png');
    await ref.putData(imageData);
    final url = await ref.getDownloadURL();
    
    // Save metadata to Firestore
    await FirebaseFirestore.instance.collection('paintings').add({
      'imageUrl': url,
      'createdAt': FieldValue.serverTimestamp(),
      'backgroundType': controller.backgroundType.toString(),
    });
  }
}
```

### Custom Background Patterns
You can extend the background system by modifying `_image_painter.dart` to add your own patterns in the `_drawBackground` method.

## 🚀 FlutterFlow Compatibility

This package now includes **FlutterFlow-compatible** widgets that work within FlutterFlow's limitations (no callbacks, simple parameters only).

### FlutterFlow Usage

```dart
import 'package:image_painter/flutterflow_image_painter.dart';

// In your FlutterFlow custom widget
FlutterFlowImagePainter(
  width: 400,
  height: 400,
  backgroundType: 'graph',  // 'none', 'blank', 'graph', 'lined', 'network'
  backgroundColor: Colors.white,
  strokeWidth: 4.0,
  paintColor: Colors.red,
  showTextTool: true,
  showShapesTools: true,
  // ... other simple parameters
)
```

### FlutterFlow Actions

```dart
// Export image (call from FlutterFlow action)
final imageBytes = await widgetState.exportImage();

// Clear canvas (call from FlutterFlow action)  
widgetState.clearCanvas();

// Undo last action (call from FlutterFlow action)
widgetState.undoLastAction();
```

**📋 See [`FLUTTERFLOW_GUIDE.md`](FLUTTERFLOW_GUIDE.md) for complete FlutterFlow integration instructions.**

---

## 📝 API Reference

### `BackgroundType` Enum
- `BackgroundType.none` - No background
- `BackgroundType.blankCanvas` - Solid color background  
- `BackgroundType.graphPaper` - Grid pattern
- `BackgroundType.linedNotebook` - Lined paper with margin
- `BackgroundType.networkImage` - Network image background

### `ToolbarConfig` Class
Properties to control toolbar visibility:
- `showBrushTool` (bool) - Show/hide brush mode selector
- `showColorTool` (bool) - Show/hide color picker
- `showStrokeTool` (bool) - Show/hide stroke width control
- `showTextTool` (bool) - Show/hide text tool
- `showShapesTools` (bool) - Show/hide shape tools (rect, circle, arrow, dash)
- `showUndoTool` (bool) - Show/hide undo button
- `showClearTool` (bool) - Show/hide clear all button
- `showSaveTool` (bool) - Show/hide save button

### Enhanced `ImagePainterController`
New methods:
- `setBackground({BackgroundType? type, String? imageUrl, Color? color})` - Change background
- `setToolbarConfig(ToolbarConfig config)` - Update toolbar configuration
- `setSaveCallback(VoidCallback? callback)` - Set custom save logic

New properties:
- `backgroundType` - Current background type
- `backgroundImageUrl` - URL for network image background
- `backgroundColor` - Background color
- `toolbarConfig` - Current toolbar configuration
- `onSave` - Custom save callback
