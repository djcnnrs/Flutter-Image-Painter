import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';

void main() => runApp(EnhancedExampleApp());

class EnhancedExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Image Painter Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: EnhancedImagePainterExample(),
    );
  }
}

class EnhancedImagePainterExample extends StatefulWidget {
  @override
  _EnhancedImagePainterExampleState createState() => _EnhancedImagePainterExampleState();
}

class _EnhancedImagePainterExampleState extends State<EnhancedImagePainterExample> {
  late ImagePainterController _controller;
  BackgroundType _selectedBackground = BackgroundType.blankCanvas;
  String? _networkImageUrl;
  
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController(
      backgroundType: _selectedBackground,
      backgroundColor: Colors.white,
      toolbarConfig: const ToolbarConfig(
        showTextTool: true,
        showShapesTools: true,
        showSaveTool: true,
      ),
      onSave: _handleSave,
    );
  }

  void _handleSave() {
    // Custom save logic - could upload to Firebase, save to Firestore, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom save action executed! This could upload to Firebase.'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Example: Export and save the image
    _exportImage();
  }

  Future<void> _exportImage() async {
    try {
      final exportedImage = await _controller.exportImage();
      if (exportedImage != null) {
        // Here you could save to gallery, upload to cloud storage, etc.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image exported successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
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

  void _changeBackground(BackgroundType type) {
    setState(() {
      _selectedBackground = type;
      _controller.setBackground(
        type: type,
        imageUrl: type == BackgroundType.networkImage ? _networkImageUrl : null,
        color: Colors.white,
      );
    });
  }

  void _setNetworkImage() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _networkImageUrl = url;
        _selectedBackground = BackgroundType.networkImage;
        _controller.setBackground(
          type: BackgroundType.networkImage,
          imageUrl: url,
        );
      });
    }
  }

  void _toggleToolbarOption(String option) {
    final currentConfig = _controller.toolbarConfig;
    ToolbarConfig newConfig;
    
    switch (option) {
      case 'text':
        newConfig = ToolbarConfig(
          showBrushTool: currentConfig.showBrushTool,
          showColorTool: currentConfig.showColorTool,
          showStrokeTool: currentConfig.showStrokeTool,
          showTextTool: !currentConfig.showTextTool,
          showShapesTools: currentConfig.showShapesTools,
          showUndoTool: currentConfig.showUndoTool,
          showClearTool: currentConfig.showClearTool,
          showSaveTool: currentConfig.showSaveTool,
        );
        break;
      case 'shapes':
        newConfig = ToolbarConfig(
          showBrushTool: currentConfig.showBrushTool,
          showColorTool: currentConfig.showColorTool,
          showStrokeTool: currentConfig.showStrokeTool,
          showTextTool: currentConfig.showTextTool,
          showShapesTools: !currentConfig.showShapesTools,
          showUndoTool: currentConfig.showUndoTool,
          showClearTool: currentConfig.showClearTool,
          showSaveTool: currentConfig.showSaveTool,
        );
        break;
      default:
        return;
    }
    
    _controller.setToolbarConfig(newConfig);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Image Painter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Background selection
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Background:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildBackgroundChip('Blank Canvas', BackgroundType.blankCanvas),
                    _buildBackgroundChip('Graph Paper', BackgroundType.graphPaper),
                    _buildBackgroundChip('Lined Notebook', BackgroundType.linedNotebook),
                    _buildBackgroundChip('Network Image', BackgroundType.networkImage),
                  ],
                ),
                if (_selectedBackground == BackgroundType.networkImage) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            hintText: 'Enter image URL',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _setNetworkImage,
                        child: const Text('Load'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          // Image painter
          Expanded(
            child: ImagePainter.withBackground(
              controller: _controller,
              backgroundType: _selectedBackground,
              backgroundImageUrl: _networkImageUrl,
              backgroundColor: Colors.white,
              height: double.infinity,
              width: double.infinity,
              onSave: _handleSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundChip(String label, BackgroundType type) {
    final isSelected = _selectedBackground == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _changeBackground(type),
      selectedColor: Colors.blue.withOpacity(0.3),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toolbar Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Text Tool'),
              value: _controller.toolbarConfig.showTextTool,
              onChanged: (_) => _toggleToolbarOption('text'),
            ),
            CheckboxListTile(
              title: const Text('Shape Tools'),
              value: _controller.toolbarConfig.showShapesTools,
              onChanged: (_) => _toggleToolbarOption('shapes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
