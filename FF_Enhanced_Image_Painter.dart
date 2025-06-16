// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enhanced_image_painter/enhanced_image_painter.dart';

class ImagePainterWidget extends StatefulWidget {
  const ImagePainterWidget({
    super.key,
    this.width,
    this.height,
    this.bgImage,
    this.jobRef,
  });

  final double? width;
  final double? height;
  final String? bgImage;
  final DocumentReference? jobRef;

  @override
  State<ImagePainterWidget> createState() => _ImagePainterWidgetState();
}

class _ImagePainterWidgetState extends State<ImagePainterWidget> {
  bool _isSaving = false;
  final GlobalKey<EnhancedImagePainterState> _painterKey = GlobalKey<EnhancedImagePainterState>();
  
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
    final double actualWidth = widget.width ?? 300;
    final double actualHeight = widget.height ?? 200;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          EnhancedImagePainter(
            key: _painterKey,
            width: actualWidth,
            height: actualHeight,
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
        final jobSnapshot = await widget.jobRef!.get();
        final bidRef = jobSnapshot.get('bid_ref') as DocumentReference?;
        final bidId = bidRef?.id ?? 'unknown_bid';
        storagePath = 'businesses/$bidId/jobs/${widget.jobRef!.id}/notes/$fileName';
      } else {
        storagePath = 'notes/$fileName';
      }

      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      
      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      
      final downloadUrl = await storageRef.getDownloadURL();
      
      if (widget.jobRef != null) {
        await widget.jobRef!.update({
          'attachments_ref': FieldValue.arrayUnion([downloadUrl])
        });
      }     
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
    _painterKey.currentState?.undoLastAction();
  }

  // CUSTOMIZE CLEAR ACTION HERE  
  void _handleClear() {
    _painterKey.currentState?.clearCanvas();
    _showMessage('Canvas cleared', Colors.blue);
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
