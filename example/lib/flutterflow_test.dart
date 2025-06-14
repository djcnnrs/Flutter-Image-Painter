import 'package:flutter/material.dart';
import 'package:image_painter/flutterflow_image_painter.dart';

void main() => runApp(FlutterFlowTestApp());

class FlutterFlowTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterFlow Image Painter Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FlutterFlowTestPage(),
    );
  }
}

class FlutterFlowTestPage extends StatefulWidget {
  @override
  _FlutterFlowTestPageState createState() => _FlutterFlowTestPageState();
}

class _FlutterFlowTestPageState extends State<FlutterFlowTestPage> {
  final GlobalKey<FlutterFlowImagePainterState> _painterKey = 
      GlobalKey<FlutterFlowImagePainterState>();
  
  String _backgroundType = 'blank';
  Color _backgroundColor = Colors.white;
  bool _showTextTool = true;
  bool _showShapesTools = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FlutterFlow Image Painter Test'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _exportImage,
          ),
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: _undoAction,
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearCanvas,
          ),
        ],
      ),
      body: Column(
        children: [
          // Control Panel (simulates FlutterFlow's parameter configuration)
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Background Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _buildBackgroundChip('Blank', 'blank'),
                    _buildBackgroundChip('Graph', 'graph'),
                    _buildBackgroundChip('Lined', 'lined'),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: Text('Text Tool'),
                        value: _showTextTool,
                        onChanged: (value) => setState(() => _showTextTool = value ?? true),
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: Text('Shape Tools'),
                        value: _showShapesTools,
                        onChanged: (value) => setState(() => _showShapesTools = value ?? true),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Image Painter Widget (this is what goes in FlutterFlow)
          Expanded(
            child: FlutterFlowImagePainter(
              key: _painterKey,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height - 250,
              backgroundType: _backgroundType,
              backgroundColor: _backgroundColor,
              strokeWidth: 4.0,
              paintColor: Colors.red,
              showTextTool: _showTextTool,
              showShapesTools: _showShapesTools,
              showBrushTool: true,
              showColorTool: true,
              showStrokeTool: true,
              showUndoTool: true,
              showClearTool: true,
              showSaveTool: false, // We handle save in the app bar
              controlsAtTop: false,
              showControls: true,
              isScalable: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundChip(String label, String type) {
    final isSelected = _backgroundType == type;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _backgroundType = type),
        selectedColor: Colors.blue.withOpacity(0.3),
      ),
    );
  }

  // These methods simulate FlutterFlow actions
  Future<void> _exportImage() async {
    try {
      final imageData = await _painterKey.currentState?.exportImage();
      if (imageData != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image exported! Size: ${imageData.length} bytes'),
            backgroundColor: Colors.green,
          ),
        );
        
        // In FlutterFlow, you would upload this to Firebase, save to gallery, etc.
        print('Image exported with ${imageData.length} bytes');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _undoAction() {
    _painterKey.currentState?.undoLastAction();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Undo action performed')),
    );
  }

  void _clearCanvas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Canvas'),
        content: Text('Are you sure you want to clear all drawings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _painterKey.currentState?.clearCanvas();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Canvas cleared')),
              );
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
}
