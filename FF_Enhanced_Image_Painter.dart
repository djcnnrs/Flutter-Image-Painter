// FlutterFlow Custom Widget - Copy this code
// Widget Name: ImagePainterWidget
// Parameters: width (double), height (double), bgImage (String?), jobRef (DocumentReference?)
// Dependencies: Add the GitHub package URL in pubspec dependencies

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_painter/enhanced_image_painter.dart';

class ImagePainterWidget extends StatefulWidget {
  const ImagePainterWidget({
    Key? key,
    required this.width,
    required this.height,
    this.bgImage,
    this.jobRef,
  }) : super(key: key);

  final double width;
  final double height;
  final String? bgImage;
  final DocumentReference? jobRef;

  @override
  ImagePainterWidgetState createState() => ImagePainterWidgetState();
}

class ImagePainterWidgetState extends State<ImagePainterWidget> {
  final GlobalKey<EnhancedImagePainterState> _painterKey = 
      GlobalKey<EnhancedImagePainterState>();
  
  bool _isSaving = false;
  
  // CUSTOMIZE FEATURES HERE - Add/remove modes as needed
  static const enabledModes = [
    PaintMode.freeStyle,
    PaintMode.line,
    PaintMode.arrow,
    PaintMode.dashedLine,
    PaintMode.rect,
    PaintMode.circle,
    PaintMode.text,
  ];
  
  // CUSTOMIZE STYLES HERE
  static const defaultStrokeWidth = 2.0;
  static const defaultColor = Colors.black;
  static const toolbarAtTop = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          EnhancedImagePainter(
            key: _painterKey,
            width: widget.width,
            height: widget.height,
            bgImage: widget.bgImage,
            config: EnhancedImagePainterConfig(
              enabledModes: enabledModes,
              defaultStrokeWidth: defaultStrokeWidth,
              defaultColor: defaultColor,
              toolbarAtTop: toolbarAtTop,
              toolbarBackgroundColor: Colors.grey[200],
              onSave: _handleSave,
              onUndo: _handleUndo,
              onClear: _handleClear,
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // CUSTOMIZE SAVE ACTION HERE
  Future<void> _handleSave() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);

    try {
      _showMessage('Saving...', Colors.blue);
      
      final imageBytes = await _painterKey.currentState?.exportImage();
      
      if (imageBytes == null) {
        _showMessage('Failed to save note.', Colors.red);
        return;
      }

      final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}.png';

      String storagePath;
      if (widget.jobRef != null) {
        // Change this path as needed
        storagePath = 'notes/$fileName';
      }

      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      
      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      
      final downloadUrl = await storageRef.getDownloadURL();
      
      // Show success message      
      _showMessage('Note saved successfully!', Colors.green);
      
      // CUSTOMIZE POST-SAVE ACTIONS HERE
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      print('Save error: $e');
      _showMessage('Failed to save: $e', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // CUSTOMIZE UNDO ACTION HERE
  void _handleUndo() {
    // Widget handles undo internally, add custom logic here if needed
  }

  // CUSTOMIZE CLEAR ACTION HERE  
  void _handleClear() {
    _showMessage('Canvas cleared', Colors.blue);
    // Widget handles clear internally, add custom logic here if needed
  }

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), 
          backgroundColor: color, 
          duration: Duration(seconds: 2)
        ),
      );
    }
  }
}
