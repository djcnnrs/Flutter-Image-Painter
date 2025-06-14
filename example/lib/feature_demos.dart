import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';

void main() => runApp(FeatureDemoApp());

class FeatureDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Painter Feature Demos',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DemoListScreen(),
    );
  }
}

class DemoListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feature Demonstrations')),
      body: ListView(
        children: [
          ListTile(
            title: Text('1. Customizable Toolbar'),
            subtitle: Text('Hide/show specific tools'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CustomToolbarDemo()),
            ),
          ),
          ListTile(
            title: Text('2. Background Patterns'),
            subtitle: Text('Graph paper, lined notebook, etc.'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BackgroundPatternsDemo()),
            ),
          ),
          ListTile(
            title: Text('3. Network Image Background'),
            subtitle: Text('Use any image URL as background'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NetworkImageDemo()),
            ),
          ),
          ListTile(
            title: Text('4. Custom Save Logic'),
            subtitle: Text('Add Firebase/cloud upload logic'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CustomSaveDemo()),
            ),
          ),
          ListTile(
            title: Text('5. Export with Background'),
            subtitle: Text('Export complete image with background'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ExportDemo()),
            ),
          ),
        ],
      ),
    );
  }
}

// Demo 1: Customizable Toolbar
class CustomToolbarDemo extends StatefulWidget {
  @override
  _CustomToolbarDemoState createState() => _CustomToolbarDemoState();
}

class _CustomToolbarDemoState extends State<CustomToolbarDemo> {
  late ImagePainterController _controller;
  bool showTextTool = true;
  bool showShapesTools = true;

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController(
      backgroundType: BackgroundType.blankCanvas,
      toolbarConfig: ToolbarConfig(
        showTextTool: showTextTool,
        showShapesTools: showShapesTools,
      ),
    );
  }

  void _updateToolbar() {
    _controller.setToolbarConfig(ToolbarConfig(
      showTextTool: showTextTool,
      showShapesTools: showShapesTools,
      showSaveTool: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Customizable Toolbar')),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                CheckboxListTile(
                  title: Text('Show Text Tool'),
                  value: showTextTool,
                  onChanged: (value) {
                    setState(() {
                      showTextTool = value ?? true;
                      _updateToolbar();
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text('Show Shape Tools'),
                  value: showShapesTools,
                  onChanged: (value) {
                    setState(() {
                      showShapesTools = value ?? true;
                      _updateToolbar();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ImagePainter.withBackground(
              controller: _controller,
              backgroundType: BackgroundType.blankCanvas,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Demo 2: Background Patterns
class BackgroundPatternsDemo extends StatefulWidget {
  @override
  _BackgroundPatternsDemoState createState() => _BackgroundPatternsDemoState();
}

class _BackgroundPatternsDemoState extends State<BackgroundPatternsDemo> {
  late ImagePainterController _controller;
  BackgroundType currentBackground = BackgroundType.graphPaper;

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController(
      backgroundType: currentBackground,
    );
  }

  void _changeBackground(BackgroundType type) {
    setState(() {
      currentBackground = type;
      _controller.setBackground(type: type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Background Patterns')),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Graph Paper'),
                  selected: currentBackground == BackgroundType.graphPaper,
                  onSelected: (_) => _changeBackground(BackgroundType.graphPaper),
                ),
                ChoiceChip(
                  label: Text('Lined Notebook'),
                  selected: currentBackground == BackgroundType.linedNotebook,
                  onSelected: (_) => _changeBackground(BackgroundType.linedNotebook),
                ),
                ChoiceChip(
                  label: Text('Blank Canvas'),
                  selected: currentBackground == BackgroundType.blankCanvas,
                  onSelected: (_) => _changeBackground(BackgroundType.blankCanvas),
                ),
              ],
            ),
          ),
          Expanded(
            child: ImagePainter.withBackground(
              controller: _controller,
              backgroundType: currentBackground,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Demo 3: Network Image Background
class NetworkImageDemo extends StatefulWidget {
  @override
  _NetworkImageDemoState createState() => _NetworkImageDemoState();
}

class _NetworkImageDemoState extends State<NetworkImageDemo> {
  late ImagePainterController _controller;
  final _urlController = TextEditingController(
    text: 'https://picsum.photos/400/300',
  );
  String? currentImageUrl;

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController(
      backgroundType: BackgroundType.blankCanvas,
    );
  }

  void _loadNetworkImage() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        currentImageUrl = url;
        _controller.setBackground(
          type: BackgroundType.networkImage,
          imageUrl: url,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Network Image Background')),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/image.jpg',
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadNetworkImage,
                  child: Text('Load Background Image'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ImagePainter.withBackground(
              controller: _controller,
              backgroundType: currentImageUrl != null ? BackgroundType.networkImage : BackgroundType.blankCanvas,
              backgroundImageUrl: currentImageUrl,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _urlController.dispose();
    super.dispose();
  }
}

// Demo 4: Custom Save Logic
class CustomSaveDemo extends StatefulWidget {
  @override
  _CustomSaveDemoState createState() => _CustomSaveDemoState();
}

class _CustomSaveDemoState extends State<CustomSaveDemo> {
  late ImagePainterController _controller;
  String saveStatus = 'Not saved';

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController(
      backgroundType: BackgroundType.graphPaper,
      toolbarConfig: ToolbarConfig(showSaveTool: true),
      onSave: _handleSave,
    );
  }

  void _handleSave() async {
    setState(() {
      saveStatus = 'Saving...';
    });

    try {
      // Simulate cloud upload delay
      await Future.delayed(Duration(seconds: 2));
      
      // Get the image data
      final imageData = await _controller.exportImage();
      
      if (imageData != null) {
        // Here you would upload to Firebase, save to gallery, etc.
        setState(() {
          saveStatus = 'Saved successfully! (${imageData.length} bytes)';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved! Ready for Firebase upload.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        saveStatus = 'Save failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Custom Save Logic')),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Save Status: $saveStatus'),
                SizedBox(height: 8),
                Text('Click the save button in the toolbar below to trigger custom save logic.'),
              ],
            ),
          ),
          Expanded(
            child: ImagePainter.withBackground(
              controller: _controller,
              backgroundType: BackgroundType.graphPaper,
              height: double.infinity,
              width: double.infinity,
              onSave: _handleSave,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Demo 5: Export with Background
class ExportDemo extends StatefulWidget {
  @override
  _ExportDemoState createState() => _ExportDemoState();
}

class _ExportDemoState extends State<ExportDemo> {
  late ImagePainterController _controller;
  String exportInfo = 'Draw something, then export!';

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController(
      backgroundType: BackgroundType.linedNotebook,
    );
  }

  void _exportImage() async {
    try {
      final imageData = await _controller.exportImage();
      if (imageData != null) {
        setState(() {
          exportInfo = 'Exported! Size: ${imageData.length} bytes';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image exported with background!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      setState(() {
        exportInfo = 'Export failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export with Background'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportImage,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Text(exportInfo),
          ),
          Expanded(
            child: ImagePainter.withBackground(
              controller: _controller,
              backgroundType: BackgroundType.linedNotebook,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
