// REQUIRED IMPORTS FOR ALL FLUTTERFLOW ACTIONS:
// Add these imports at the top of each custom action in FlutterFlow

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart'; // Only if using Firebase actions
import 'package:cloud_firestore/cloud_firestore.dart';   // Only if using Firestore actions

// =================================================================
// FLUTTERFLOW CUSTOM ACTIONS - COPY EACH ONE SEPARATELY
// =================================================================

// COPY THIS CODE INTO FLUTTERFLOW CUSTOM ACTION
// Action Name: exportPaintedImage
// Return Type: Future<List<int>?> (FlutterFlow compatible)
// No parameters needed

Future<List<int>?> exportPaintedImage() async {
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
      // Convert Uint8List to List<int> for FlutterFlow compatibility
      return imageBytes.toList();
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
// Return Type: Future<bool> (FlutterFlow compatible - returns success status)
// No parameters needed

Future<bool> clearPaintedCanvas() async {
  try {
    // Check if widget is ready
    if (!ImagePainterWidget.isWidgetReady()) {
      print('ImagePainter widget is not ready. Make sure it is displayed on the page.');
      return false;
    }

    // Clear the canvas
    ImagePainterWidget.clearCurrentCanvas();
    print('Canvas cleared successfully');
    return true;
  } catch (e) {
    print('Clear action failed: $e');
    return false;
  }
}

// COPY THIS CODE INTO FLUTTERFLOW CUSTOM ACTION
// Action Name: undoPaintAction
// Return Type: Future<bool> (FlutterFlow compatible - returns success status)
// No parameters needed

Future<bool> undoPaintAction() async {
  try {
    // Check if widget is ready
    if (!ImagePainterWidget.isWidgetReady()) {
      print('ImagePainter widget is not ready. Make sure it is displayed on the page.');
      return false;
    }

    // Undo last action
    ImagePainterWidget.undoCurrentAction();
    print('Undo action completed');
    return true;
  } catch (e) {
    print('Undo action failed: $e');
    return false;
  }
}

// ALTERNATIVE: SIMPLE VOID ACTIONS (If you don't need return values)
// COPY THIS CODE INTO FLUTTERFLOW CUSTOM ACTION
// Action Name: exportPaintedImageSimple
// Return Type: Future<void> (No return value)
// No parameters needed
// NOTE: Use app state or show snackbar to handle results

Future<void> exportPaintedImageSimple() async {
  try {
    if (!ImagePainterWidget.isWidgetReady()) {
      // Update app state to show error
      FFAppState().lastActionResult = 'Widget not ready';
      return;
    }

    final imageBytes = await ImagePainterWidget.exportCurrentImage();
    
    if (imageBytes != null) {
      // Store in app state for use elsewhere
      FFAppState().lastExportedImage = imageBytes.toList();
      FFAppState().lastActionResult = 'Export successful';
      print('Image exported successfully: ${imageBytes.length} bytes');
    } else {
      FFAppState().lastActionResult = 'Export failed - no data';
    }
  } catch (e) {
    FFAppState().lastActionResult = 'Export error: $e';
    print('Export action failed: $e');
  }
}

// BONUS: COPY THIS CODE INTO FLUTTERFLOW CUSTOM ACTION
// Action Name: saveImageToFirebase
// Return Type: Future<String?> (FlutterFlow compatible)
// No parameters needed
// NOTE: Make sure Firebase Storage is configured in your FlutterFlow project

Future<String?> saveImageToFirebase() async {
  try {
    // 1. Export the image first (use List<int> version)
    final imageBytesList = await exportPaintedImage();
    
    if (imageBytesList == null) {
      print('No image data to save');
      return null;
    }

    // 2. Convert List<int> back to Uint8List for Firebase
    final imageBytes = Uint8List.fromList(imageBytesList);

    // 3. Create unique filename
    final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
    
    // 4. Upload to Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child('drawings/$fileName');
    final uploadTask = await storageRef.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/png'),
    );
    
    // 5. Get download URL
    final downloadUrl = await storageRef.getDownloadURL();
    
    // 6. Optional: Save metadata to Firestore
    await FirebaseFirestore.instance.collection('drawings').add({
      'imageUrl': downloadUrl,
      'fileName': fileName,
      'createdAt': FieldValue.serverTimestamp(),
      'fileSize': imageBytes.length,
      // Add any other metadata you need
      // 'userId': currentUserUid,
      // 'title': 'My Drawing',
    });
    
    print('Image saved to Firebase: $downloadUrl');
    return downloadUrl;
    
  } catch (e) {
    print('Firebase save failed: $e');
    return null;
  }
}

// ALTERNATIVE: SIMPLE FIREBASE SAVE (Uses app state)
// COPY THIS CODE INTO FLUTTERFLOW CUSTOM ACTION  
// Action Name: saveImageToFirebaseSimple
// Return Type: Future<void>
// No parameters needed

Future<void> saveImageToFirebaseSimple() async {
  try {
    // Export image first
    await exportPaintedImageSimple();
    
    // Check if export was successful
    if (FFAppState().lastActionResult != 'Export successful') {
      FFAppState().lastActionResult = 'Save failed - export error';
      return;
    }

    // Get image data from app state
    final imageBytesList = FFAppState().lastExportedImage;
    if (imageBytesList == null || imageBytesList.isEmpty) {
      FFAppState().lastActionResult = 'Save failed - no image data';
      return;
    }

    final imageBytes = Uint8List.fromList(imageBytesList.cast<int>());
    final fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.png';
    
    // Upload to Firebase
    final storageRef = FirebaseStorage.instance.ref().child('drawings/$fileName');
    await storageRef.putData(imageBytes);
    final downloadUrl = await storageRef.getDownloadURL();
    
    // Store result in app state
    FFAppState().lastFirebaseUrl = downloadUrl;
    FFAppState().lastActionResult = 'Saved to Firebase successfully';
    
  } catch (e) {
    FFAppState().lastActionResult = 'Firebase save error: $e';
  }
}
