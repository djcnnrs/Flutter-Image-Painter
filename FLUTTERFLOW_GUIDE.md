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

## 🔑 Widget State Reference in FlutterFlow

### Method 1: Using Widget Reference Parameter (Recommended)

In FlutterFlow, when you create a custom action, you can pass your widget as a parameter:

#### Step 1: Create Custom Action with Widget Parameter

```dart
import 'dart:typed_data';

// Custom Action: Export Image
// Parameters: 
// - widgetReference (Widget) - Reference to your ImagePainter widget
Future<Uint8List?> exportPaintedImage(dynamic widgetReference) async {
  try {
    // Cast the widget reference to access the state
    if (widgetReference is GlobalKey<ImagePainterState>) {
      final imageBytes = await widgetReference.currentState?.exportImage();
      return imageBytes;
    }
    
    // Alternative: If widgetReference is the state directly
    if (widgetReference is ImagePainterState) {
      final imageBytes = await widgetReference.exportImage();
      return imageBytes;
    }
  } catch (e) {
    print('Export failed: $e');
  }
  
  return null;
}

// Custom Action: Clear Canvas
// Parameters:
// - widgetReference (Widget) - Reference to your ImagePainter widget
void clearPaintedCanvas(dynamic widgetReference) {
  try {
    if (widgetReference is GlobalKey<ImagePainterState>) {
      widgetReference.currentState?.clearCanvas();
    } else if (widgetReference is ImagePainterState) {
      widgetReference.clearCanvas();
    }
  } catch (e) {
    print('Clear failed: $e');
  }
}

// Custom Action: Undo Last Action
// Parameters:
// - widgetReference (Widget) - Reference to your ImagePainter widget
void undoPaintAction(dynamic widgetReference) {
  try {
    if (widgetReference is GlobalKey<ImagePainterState>) {
      widgetReference.currentState?.undoLastAction();
    } else if (widgetReference is ImagePainterState) {
      widgetReference.undoLastAction();
    }
  } catch (e) {
    print('Undo failed: $e');
  }
}
```

#### Step 2: Pass Widget Reference from FlutterFlow

When calling the action in FlutterFlow:
1. **Create the action**
2. **Add parameter**: `widgetReference` of type `Widget`
3. **When calling the action**: Pass your ImagePainter widget reference

### Method 2: Using Global Key (More Reliable)

This method requires modifying your custom widget to expose a global key:

```dart
// Modified ImagePainter widget for FlutterFlow
class ImagePainter extends StatefulWidget {
  // ...existing parameters...
  
  // Add this static key that can be accessed globally
  static final GlobalKey<ImagePainterState> globalKey = GlobalKey<ImagePainterState>();
  
  const ImagePainter({
    // ...existing parameters...
  }) : super(key: globalKey); // Use the global key
  
  // ...rest of widget code...
}

// Then in your custom actions:
Future<Uint8List?> exportPaintedImage() async {
  try {
    final imageBytes = await ImagePainter.globalKey.currentState?.exportImage();
    return imageBytes;
  } catch (e) {
    print('Export failed: $e');
    return null;
  }
}

void clearPaintedCanvas() {
  ImagePainter.globalKey.currentState?.clearCanvas();
}

void undoPaintAction() {
  ImagePainter.globalKey.currentState?.undoLastAction();
}
```

### Method 3: Using FlutterFlow's Widget State Management

FlutterFlow provides ways to manage widget state. Here's the most FlutterFlow-friendly approach:

```dart
// In your ImagePainter widget, add these public methods:
class ImagePainterState extends State<ImagePainter> {
  // ...existing code...
  
  // Make these methods static so they can be called from anywhere
  static ImagePainterState? _currentInstance;
  
  @override
  void initState() {
    super.initState();
    _currentInstance = this; // Store current instance
  }
  
  @override
  void dispose() {
    if (_currentInstance == this) {
      _currentInstance = null;
    }
    super.dispose();
  }
  
  // Static methods that can be called from FlutterFlow actions
  static Future<Uint8List?> exportCurrentImage() async {
    return await _currentInstance?.exportImage();
  }
  
  static void clearCurrentCanvas() {
    _currentInstance?.clearCanvas();
  }
  
  static void undoCurrentAction() {
    _currentInstance?.undoLastAction();
  }
  
  // ...existing code...
}

// Then your FlutterFlow actions become much simpler:
Future<Uint8List?> exportPaintedImage() async {
  return await ImagePainterState.exportCurrentImage();
}

void clearPaintedCanvas() {
  ImagePainterState.clearCurrentCanvas();
}

void undoPaintAction() {
  ImagePainterState.undoCurrentAction();
}
```

## 🚨 FlutterFlow "Unable to process return parameter" Fix

### The Problem:
FlutterFlow has restrictions on custom action return types. Some types like `Uint8List?` are not supported.

### ✅ Solutions:

#### Option 1: Use FlutterFlow-Compatible Return Types
```dart
// ✅ WORKS - FlutterFlow supports List<int>
Future<List<int>?> exportPaintedImage() async {
  final imageBytes = await ImagePainterWidget.exportCurrentImage();
  return imageBytes?.toList(); // Convert Uint8List to List<int>
}

// ✅ WORKS - FlutterFlow supports bool
Future<bool> clearPaintedCanvas() async {
  try {
    ImagePainterWidget.clearCurrentCanvas();
    return true; // Success
  } catch (e) {
    return false; // Failed
  }
}
```

#### Option 2: Use Void Actions + App State
```dart
// ✅ WORKS - No return type issues
Future<void> exportPaintedImageSimple() async {
  final imageBytes = await ImagePainterWidget.exportCurrentImage();
  if (imageBytes != null) {
    // Store in FlutterFlow app state
    FFAppState().lastExportedImage = imageBytes.toList();
    FFAppState().exportSuccess = true;
  } else {
    FFAppState().exportSuccess = false;
  }
}
```

### 🎯 Recommended FlutterFlow Return Types:

| ✅ Supported | ❌ Not Supported |
|-------------|------------------|
| `Future<void>` | `Future<Uint8List?>` |
| `Future<bool>` | `Future<Uint8List>` |
| `Future<String?>` | Complex objects |
| `Future<List<int>?>` | Custom classes |
| `Future<int>` | `Future<dynamic>` |
| `Future<double>` | Nullable complex types |

### 🔧 How to Handle Image Data:

```dart
// In your action:
Future<List<int>?> exportImage() async {
  final bytes = await ImagePainterWidget.exportCurrentImage();
  return bytes?.toList(); // Convert to List<int>
}

// In your FlutterFlow logic:
final imageData = await exportImage();
if (imageData != null) {
  // Convert back to Uint8List when needed
  final uint8List = Uint8List.fromList(imageData);
  // Now upload to Firebase, save to gallery, etc.
}
```

## 🎯 Practical FlutterFlow Setup Example

### Complete Step-by-Step Implementation

#### Step 1: Create the Custom Widget (Recommended Approach)

```dart
// File: image_painter_widget.dart (in FlutterFlow Custom Widgets)
import 'package:flutter/material.dart';
import 'package:image_painter/flutterflow_image_painter.dart';
import 'dart:typed_data';

class ImagePainterWidget extends StatefulWidget {
  const ImagePainterWidget({
    Key? key,
    this.width = 400,
    this.height = 400,
    this.backgroundType = 'blank',
    this.backgroundColor = Colors.white,
    // ...other parameters
  }) : super(key: key);

  final double width;
  final double height;
  final String backgroundType;
  final Color backgroundColor;
  // ...other parameters

  // IMPORTANT: Static key for global access
  static final GlobalKey<ImagePainterWidgetState> globalKey = 
      GlobalKey<ImagePainterWidgetState>();

  @override
  ImagePainterWidgetState createState() => ImagePainterWidgetState();
}

class ImagePainterWidgetState extends State<ImagePainterWidget> {
  final GlobalKey<FlutterFlowImagePainterState> _painterKey = 
      GlobalKey<FlutterFlowImagePainterState>();

  @override
  Widget build(BuildContext context) {
    return FlutterFlowImagePainter(
      key: _painterKey,
      width: widget.width,
      height: widget.height,
      backgroundType: widget.backgroundType,
      backgroundColor: widget.backgroundColor,
      // ...other parameters
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

  // Static methods for global access (EASIEST FOR FLUTTERFLOW)
  static Future<Uint8List?> exportCurrentImage() async {
    return await ImagePainterWidget.globalKey.currentState?.exportImage();
  }

  static void clearCurrentCanvas() {
    ImagePainterWidget.globalKey.currentState?.clearCanvas();
  }

  static void undoCurrentAction() {
    ImagePainterWidget.globalKey.currentState?.undoLastAction();
  }
}
```

#### Step 2: Create Custom Actions (Simplest Approach)

```dart
// File: export_image_action.dart (in FlutterFlow Custom Actions)
import 'dart:typed_data';
import '/custom_code/widgets/image_painter_widget.dart';

Future<Uint8List?> exportPaintedImage() async {
  try {
    final imageBytes = await ImagePainterWidget.exportCurrentImage();
    
    if (imageBytes != null) {
      // Success! You can now:
      // 1. Save to device storage
      // 2. Upload to Firebase Storage
      // 3. Send via API
      // 4. Share with other apps
      
      return imageBytes;
    }
  } catch (e) {
    print('Export failed: $e');
  }
  
  return null;
}

// File: clear_canvas_action.dart
import '/custom_code/widgets/image_painter_widget.dart';

Future<void> clearPaintedCanvas() async {
  try {
    ImagePainterWidget.clearCurrentCanvas();
  } catch (e) {
    print('Clear failed: $e');
  }
}

// File: undo_action.dart
import '/custom_code/widgets/image_painter_widget.dart';

Future<void> undoPaintAction() async {
  try {
    ImagePainterWidget.undoCurrentAction();
  } catch (e) {
    print('Undo failed: $e');
  }
}
```

#### Step 3: Use in FlutterFlow Page

1. **Add the widget to your page**:
   - Drag "Custom Widget" to your page
   - Select "ImagePainterWidget"
   - Configure parameters in the properties panel

2. **Add action buttons**:
   ```dart
   // Export Button Action:
   // 1. Create button
   // 2. Add "On Tap" action
   // 3. Select "Custom Action" → "exportPaintedImage"
   // 4. Handle the returned Uint8List (save to variable, upload, etc.)

   // Clear Button Action:
   // 1. Create button  
   // 2. Add "On Tap" action
   // 3. Select "Custom Action" → "clearPaintedCanvas"

   // Undo Button Action:
   // 1. Create button
   // 2. Add "On Tap" action  
   // 3. Select "Custom Action" → "undoPaintAction"
   ```

#### Step 4: Handle Export Results

```dart
// In your FlutterFlow page actions:

// Action: Save to Firebase Storage
Future<String?> saveImageToFirebase() async {
  try {
    // 1. Export the image
    final imageBytes = await exportPaintedImage();
    
    if (imageBytes != null) {
      // 2. Upload to Firebase Storage
      final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child('drawings/$fileName');
      
      await ref.putData(imageBytes);
      final downloadUrl = await ref.getDownloadURL();
      
      // 3. Save metadata to Firestore
      await FirebaseFirestore.instance.collection('drawings').add({
        'imageUrl': downloadUrl,
        'fileName': fileName,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FFAppState().userId, // Your user ID
      });
      
      return downloadUrl;
    }
  } catch (e) {
    print('Firebase save failed: $e');
  }
  
  return null;
}

// Action: Save to Device Gallery
Future<bool> saveImageToGallery() async {
  try {
    final imageBytes = await exportPaintedImage();
    
    if (imageBytes != null) {
      // Use gallery_saver or similar package
      final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
      final success = await GallerySaver.saveImage(
        imageBytes,
        albumName: 'My Drawings',
        fileName: fileName,
      );
      
      return success ?? false;
    }
  } catch (e) {
    print('Gallery save failed: $e');
  }
  
  return false;
}
```

### 🎮 FlutterFlow Action Flow Examples

#### Example 1: Save Button with Confirmation

```
User taps "Save" button
    ↓
FlutterFlow Action Chain:
    1. Show loading indicator
    2. Call exportPaintedImage()
    3. Call saveImageToFirebase()
    4. Hide loading indicator
    5. Show success/error snackbar
```

#### Example 2: Clear Button with Confirmation Dialog

```
User taps "Clear" button
    ↓
FlutterFlow Action Chain:
    1. Show confirmation dialog
    2. If confirmed → Call clearPaintedCanvas()
    3. Show success message
```

#### Example 3: Auto-save Every 30 seconds

```
Page Timer (30 seconds)
    ↓
FlutterFlow Action Chain:
    1. Call exportPaintedImage() (silently)
    2. Save to local storage as backup
    3. Optional: Show subtle "Auto-saved" indicator
```
