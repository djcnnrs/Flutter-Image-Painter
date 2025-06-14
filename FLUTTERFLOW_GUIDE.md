# FlutterFlow Image Painter Integration Guide

This guide explains how to use the enhanced Image Painter package in FlutterFlow, which doesn't support callbacks or complex state management.

## 🚀 Quick Setup

### 1. Add as Custom Widget in FlutterFlow

1. Go to **Custom Code** → **Custom Widgets**
2. Create a new widget named `ImagePainter`
3. Import: `package:image_painter/flutterflow_image_painter.dart`
4. Copy the widget code below

### 2. Basic FlutterFlow Widget Code

```dart
import 'package:flutter/material.dart';
import 'package:image_painter/flutterflow_image_painter.dart';

class ImagePainter extends StatefulWidget {
  const ImagePainter({
    Key? key,
    this.width = 400,
    this.height = 400,
    this.backgroundType = 'none',
    this.backgroundImageUrl,
    this.backgroundColor = Colors.white,
    this.strokeWidth = 4.0,
    this.paintColor = Colors.red,
    this.showTextTool = true,
    this.showShapesTools = true,
    this.showBrushTool = true,
    this.showColorTool = true,
    this.showStrokeTool = true,
    this.showUndoTool = true,
    this.showClearTool = true,
    this.showSaveTool = false,
    this.controlsAtTop = true,
    this.showControls = true,
    this.controlsBackgroundColor,
    this.isScalable = false,
  }) : super(key: key);

  final double width;
  final double height;
  final String backgroundType; // 'none', 'blank', 'graph', 'lined', 'network'
  final String? backgroundImageUrl;
  final Color backgroundColor;
  final double strokeWidth;
  final Color paintColor;
  final bool showTextTool;
  final bool showShapesTools;
  final bool showBrushTool;
  final bool showColorTool;
  final bool showStrokeTool;
  final bool showUndoTool;
  final bool showClearTool;
  final bool showSaveTool;
  final bool controlsAtTop;
  final bool showControls;
  final Color? controlsBackgroundColor;
  final bool isScalable;

  @override
  ImagePainterState createState() => ImagePainterState();
}

class ImagePainterState extends State<ImagePainter> {
  final GlobalKey<FlutterFlowImagePainterState> _painterKey = 
      GlobalKey<FlutterFlowImagePainterState>();

  @override
  Widget build(BuildContext context) {
    return FlutterFlowImagePainter(
      key: _painterKey,
      width: widget.width,
      height: widget.height,
      backgroundType: widget.backgroundType,
      backgroundImageUrl: widget.backgroundImageUrl,
      backgroundColor: widget.backgroundColor,
      strokeWidth: widget.strokeWidth,
      paintColor: widget.paintColor,
      showTextTool: widget.showTextTool,
      showShapesTools: widget.showShapesTools,
      showBrushTool: widget.showBrushTool,
      showColorTool: widget.showColorTool,
      showStrokeTool: widget.showStrokeTool,
      showUndoTool: widget.showUndoTool,
      showClearTool: widget.showClearTool,
      showSaveTool: widget.showSaveTool,
      controlsAtTop: widget.controlsAtTop,
      showControls: widget.showControls,
      controlsBackgroundColor: widget.controlsBackgroundColor,
      isScalable: widget.isScalable,
    );
  }

  // Public methods that can be called from FlutterFlow actions
  Future<Uint8List?> exportImage() async {
    return await _painterKey.currentState?.exportImage();
  }

  void clearCanvas() {
    _painterKey.currentState?.clearCanvas();
  }

  void undoLastAction() {
    _painterKey.currentState?.undoLastAction();
  }
}
```

## 📋 FlutterFlow Parameter Configuration

### Widget Parameters in FlutterFlow

When adding the custom widget, configure these parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `width` | double | 400 | Widget width |
| `height` | double | 400 | Widget height |
| `backgroundType` | String | 'none' | Background: 'none', 'blank', 'graph', 'lined', 'network' |
| `backgroundImageUrl` | String? | null | URL for network image background |
| `backgroundColor` | Color | Colors.white | Background color for blank canvas |
| `strokeWidth` | double | 4.0 | Initial brush size |
| `paintColor` | Color | Colors.red | Initial paint color |
| `showTextTool` | bool | true | Show/hide text tool |
| `showShapesTools` | bool | true | Show/hide shape tools |
| `showBrushTool` | bool | true | Show/hide brush selector |
| `showColorTool` | bool | true | Show/hide color picker |
| `showStrokeTool` | bool | true | Show/hide stroke width slider |
| `showUndoTool` | bool | true | Show/hide undo button |
| `showClearTool` | bool | true | Show/hide clear button |
| `showSaveTool` | bool | false | Show/hide save button |
| `controlsAtTop` | bool | true | Position controls at top/bottom |
| `showControls` | bool | true | Show/hide toolbar |
| `controlsBackgroundColor` | Color? | null | Toolbar background color |
| `isScalable` | bool | false | Enable zoom/pan |

## 🎨 Background Types

### Available Backgrounds

```dart
// No background (transparent)
backgroundType: 'none'

// Solid color background  
backgroundType: 'blank'
backgroundColor: Colors.lightBlue

// Graph paper pattern
backgroundType: 'graph'

// Lined notebook pattern
backgroundType: 'lined'

// Network image background
backgroundType: 'network'
backgroundImageUrl: 'https://example.com/background.jpg'
```

## 🛠️ FlutterFlow Actions

### Export Image Action

Create a custom action in FlutterFlow:

```dart
import 'dart:typed_data';

Future<Uint8List?> exportPaintedImage() async {
  // Get reference to your Image Painter widget
  final painterState = // Reference to your widget state
  
  try {
    final imageBytes = await painterState.exportImage();
    
    if (imageBytes != null) {
      // Save to device, upload to Firebase, etc.
      // Example: Save to gallery
      // await saveImageToGallery(imageBytes);
      
      // Example: Upload to Firebase Storage
      // await uploadToFirebaseStorage(imageBytes);
      
      return imageBytes;
    }
  } catch (e) {
    print('Export failed: $e');
  }
  
  return null;
}
```

### Clear Canvas Action

```dart
void clearPaintedCanvas() {
  // Get reference to your Image Painter widget
  final painterState = // Reference to your widget state
  
  painterState.clearCanvas();
}
```

### Undo Action

```dart
void undoPaintAction() {
  // Get reference to your Image Painter widget  
  final painterState = // Reference to your widget state
  
  painterState.undoLastAction();
}
```

## 📱 Common FlutterFlow Use Cases

### 1. Simple Drawing App

```dart
// Widget Configuration in FlutterFlow
ImagePainter(
  width: MediaQuery.of(context).size.width,
  height: 400,
  backgroundType: 'blank',
  backgroundColor: Colors.white,
  showTextTool: false,  // Hide text tool
  showShapesTools: true,
  showSaveTool: true,
)
```

### 2. Note-Taking App

```dart
// Widget Configuration for note-taking
ImagePainter(
  width: MediaQuery.of(context).size.width,
  height: 600,
  backgroundType: 'lined',  // Lined notebook background
  showShapesTools: false,   // Hide complex shapes
  showTextTool: true,       // Enable text annotation
  strokeWidth: 2.0,         // Thinner lines for writing
  paintColor: Colors.blue,
)
```

### 3. Photo Annotation

```dart
// Widget Configuration for photo annotation
ImagePainter(
  width: 400,
  height: 300,
  backgroundType: 'network',
  backgroundImageUrl: 'https://example.com/photo.jpg',
  showTextTool: true,
  showShapesTools: true,
  paintColor: Colors.red,   // Annotation color
  strokeWidth: 3.0,
)
```

### 4. Kids Drawing App

```dart
// Widget Configuration for kids
ImagePainter(
  width: MediaQuery.of(context).size.width,
  height: 500,
  backgroundType: 'graph',  // Fun grid background
  showTextTool: false,      // Simplify for kids
  showStrokeTool: false,    // Fixed brush size
  showColorTool: true,      // Let them choose colors
  strokeWidth: 6.0,         // Thick, easy-to-see lines
  isScalable: false,        // Prevent accidental zooming
)
```

## 🔄 State Management in FlutterFlow

Since FlutterFlow doesn't support complex state management, the widget manages its own state internally. You can:

1. **Configure initial state** through widget parameters
2. **Trigger actions** through widget state methods
3. **Handle results** in custom actions

### Example: Save to Firebase

```dart
// Custom Action in FlutterFlow
Future<void> saveDrawingToFirebase() async {
  try {
    // Export the image
    final imageBytes = await painterWidgetState.exportImage();
    
    if (imageBytes != null) {
      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('drawings/${DateTime.now().millisecondsSinceEpoch}.png');
      
      await ref.putData(imageBytes);
      final downloadUrl = await ref.getDownloadURL();
      
      // Save metadata to Firestore
      await FirebaseFirestore.instance.collection('drawings').add({
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': getCurrentUserId(),
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Drawing saved successfully!')),
      );
    }
  } catch (e) {
    // Handle error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save: $e')),
    );
  }
}
```

## ⚠️ FlutterFlow Limitations & Workarounds

### Limitations:
1. **No callback functions** - Use widget state methods instead
2. **No complex objects** - Use simple parameters (String, bool, double)
3. **Limited state sharing** - Widget manages its own state

### Workarounds:
1. **Export functionality** - Use widget state methods called from actions
2. **Configuration** - Use simple parameters instead of config objects
3. **Events** - Use FlutterFlow's action system with widget state methods

## 🧪 Testing in FlutterFlow

1. **Create a test page** with the Image Painter widget
2. **Configure parameters** using FlutterFlow's widget properties panel
3. **Add action buttons** that call the widget state methods
4. **Test different backgrounds** by changing the `backgroundType` parameter
5. **Test toolbar customization** by toggling the show/hide parameters

## 📚 Complete Example

```dart
// FlutterFlow Page with Image Painter
class DrawingPage extends StatefulWidget {
  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final GlobalKey<ImagePainterState> _painterKey = GlobalKey();
  String _backgroundType = 'blank';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drawing App'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveDrawing,
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearDrawing,
          ),
        ],
      ),
      body: Column(
        children: [
          // Background selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _backgroundType = 'blank'),
                child: Text('Blank'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _backgroundType = 'graph'),
                child: Text('Grid'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _backgroundType = 'lined'),
                child: Text('Lined'),
              ),
            ],
          ),
          // Image Painter
          Expanded(
            child: ImagePainter(
              key: _painterKey,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height - 200,
              backgroundType: _backgroundType,
              backgroundColor: Colors.white,
              showTextTool: true,
              showShapesTools: true,
              controlsAtTop: false,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDrawing() async {
    final imageBytes = await _painterKey.currentState?.exportImage();
    if (imageBytes != null) {
      // Handle save (upload to cloud, save to gallery, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Drawing saved!')),
      );
    }
  }

  void _clearDrawing() {
    _painterKey.currentState?.clearCanvas();
  }
}
```

This FlutterFlow-compatible version provides all the enhanced features while working within FlutterFlow's constraints!
