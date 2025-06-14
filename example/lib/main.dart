import 'package:flutter/material.dart';
import 'package:enhanced_image_painter/enhanced_image_painter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Image Painter Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ImagePainterExample(),
    );
  }
}

class ImagePainterExample extends StatefulWidget {
  const ImagePainterExample({super.key});

  @override
  State<ImagePainterExample> createState() => _ImagePainterExampleState();
}

class _ImagePainterExampleState extends State<ImagePainterExample> {
  late EnhancedImagePainterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EnhancedImagePainterController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Image Painter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Draw, annotate, and save your artwork!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 4,
                child: EnhancedImagePainter(
                  controller: _controller,
                  width: double.infinity,
                  height: double.infinity,
                  backgroundType: PainterBackgroundType.graphPaper,
                  showControls: true,
                  showColorPicker: true,
                  showBrushSizeSlider: true,
                  enableUndo: true,
                  enableClear: true,
                  enableSave: true,
                  onSave: (imageBytes) async {
                    // Handle save functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Image saved successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Features: Draw, Text, Shapes, Multiple Backgrounds, Export',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
