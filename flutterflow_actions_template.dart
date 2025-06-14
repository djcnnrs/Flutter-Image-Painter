// COPY THIS CODE INTO FLUTTERFLOW CUSTOM ACTION
// Action Name: exportPaintedImage
// Return Type: Future<Uint8List?>
// No parameters needed

import 'dart:typed_data';

Future<Uint8List?> exportPaintedImage() async {
  try {
    // Check if widget is ready
    if (!ImagePainterWidget.isWidgetReady()) {
      print('ImagePainter widget is not ready. Make sure it is displayed on the page.');
      return null;
    }

    // Export the image
    final imageBytes = await ImagePainterWidget.exportCurrentImage();
    
    if (imageBytes != null) {
      print('Image exported successfully: ${imageBytes.length} bytes');
      return imageBytes;
    } else {
      print('Export returned null - no image data');
      return null;
    }
  } catch (e) {
    print('Export action failed: $e');
    return null;
  }
}

// COPY THIS CODE INTO FLUTTERFLOW CUSTOM ACTION
// Action Name: clearPaintedCanvas
// Return Type: Future<void>
// No parameters needed

Future<void> clearPaintedCanvas() async {
  try {
    // Check if widget is ready
    if (!ImagePainterWidget.isWidgetReady()) {
      print('ImagePainter widget is not ready. Make sure it is displayed on the page.');
      return;
    }

    // Clear the canvas
    ImagePainterWidget.clearCurrentCanvas();
    print('Canvas cleared successfully');
  } catch (e) {
    print('Clear action failed: $e');
  }
}

// COPY THIS CODE INTO FLUTTERFLOW CUSTOM ACTION
// Action Name: undoPaintAction
// Return Type: Future<void>
// No parameters needed

Future<void> undoPaintAction() async {
  try {
    // Check if widget is ready
    if (!ImagePainterWidget.isWidgetReady()) {
      print('ImagePainter widget is not ready. Make sure it is displayed on the page.');
      return;
    }

    // Undo last action
    ImagePainterWidget.undoCurrentAction();
    print('Undo action completed');
  } catch (e) {
    print('Undo action failed: $e');
  }
}

// BONUS: COPY THIS CODE INTO FLUTTERFLOW CUSTOM ACTION
// Action Name: saveImageToFirebase
// Return Type: Future<String?>
// No parameters needed
// NOTE: Make sure Firebase Storage is configured in your FlutterFlow project

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> saveImageToFirebase() async {
  try {
    // 1. Export the image first
    final imageBytes = await exportPaintedImage();
    
    if (imageBytes == null) {
      print('No image data to save');
      return null;
    }

    // 2. Create unique filename
    final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
    
    // 3. Upload to Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child('drawings/$fileName');
    final uploadTask = await storageRef.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/png'),
    );
    
    // 4. Get download URL
    final downloadUrl = await storageRef.getDownloadURL();
    
    // 5. Optional: Save metadata to Firestore
    await FirebaseFirestore.instance.collection('drawings').add({
      'imageUrl': downloadUrl,
      'fileName': fileName,
      'createdAt': FieldValue.serverTimestamp(),
      'fileSize': imageBytes.length,
      // Add any other metadata you need
      // 'userId': FFAppState().currentUser?.uid,
      // 'title': 'My Drawing',
    });
    
    print('Image saved to Firebase: $downloadUrl');
    return downloadUrl;
    
  } catch (e) {
    print('Firebase save failed: $e');
    return null;
  }
}
