import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_painter/image_painter.dart';

void main() {
  group('Enhanced Image Painter Tests', () {
    testWidgets('Controller with toolbar config works', (WidgetTester tester) async {
      final controller = ImagePainterController(
        toolbarConfig: const ToolbarConfig(
          showTextTool: false,
          showShapesTools: true,
        ),
      );

      expect(controller.toolbarConfig.showTextTool, false);
      expect(controller.toolbarConfig.showShapesTools, true);

      controller.dispose();
    });

    testWidgets('Background type can be set', (WidgetTester tester) async {
      final controller = ImagePainterController(
        backgroundType: BackgroundType.graphPaper,
        backgroundColor: Colors.blue,
      );

      expect(controller.backgroundType, BackgroundType.graphPaper);
      expect(controller.backgroundColor, Colors.blue);

      // Test changing background
      controller.setBackground(
        type: BackgroundType.linedNotebook,
        color: Colors.red,
      );

      expect(controller.backgroundType, BackgroundType.linedNotebook);
      expect(controller.backgroundColor, Colors.red);

      controller.dispose();
    });

    testWidgets('Save callback works', (WidgetTester tester) async {
      bool saveCalled = false;
      
      final controller = ImagePainterController(
        onSave: () {
          saveCalled = true;
        },
      );

      expect(controller.onSave, isNotNull);
      controller.onSave!();
      expect(saveCalled, true);

      controller.dispose();
    });

    testWidgets('Toolbar configuration can be updated', (WidgetTester tester) async {
      final controller = ImagePainterController();

      expect(controller.toolbarConfig.showTextTool, true); // default

      controller.setToolbarConfig(
        const ToolbarConfig(showTextTool: false),
      );

      expect(controller.toolbarConfig.showTextTool, false);

      controller.dispose();
    });

    testWidgets('withBackground constructor works', (WidgetTester tester) async {
      final controller = ImagePainterController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePainter.withBackground(
              controller: controller,
              backgroundType: BackgroundType.graphPaper,
              backgroundColor: Colors.white,
              height: 400,
              width: 400,
            ),
          ),
        ),
      );

      expect(find.byType(ImagePainter), findsOneWidget);
      expect(controller.backgroundType, BackgroundType.graphPaper);
      expect(controller.backgroundColor, Colors.white);

      controller.dispose();
    });

    test('Paint modes filter based on toolbar config', () {
      const config = ToolbarConfig(
        showTextTool: false,
        showShapesTools: false,
      );

      final modes = paintModes(TextDelegate(), config);
      
      // Should not contain text mode
      expect(modes.where((m) => m.mode == PaintMode.text), isEmpty);
      
      // Should not contain shape modes
      expect(modes.where((m) => m.mode == PaintMode.rect), isEmpty);
      expect(modes.where((m) => m.mode == PaintMode.circle), isEmpty);
      expect(modes.where((m) => m.mode == PaintMode.arrow), isEmpty);
      expect(modes.where((m) => m.mode == PaintMode.dashLine), isEmpty);
      
      // Should still contain basic modes
      expect(modes.where((m) => m.mode == PaintMode.freeStyle), isNotEmpty);
      expect(modes.where((m) => m.mode == PaintMode.line), isNotEmpty);
      expect(modes.where((m) => m.mode == PaintMode.none), isNotEmpty);
    });

    test('Export image handles different background types', () async {
      // Test with no image but with background
      final controller = ImagePainterController(
        backgroundType: BackgroundType.blankCanvas,
        backgroundColor: Colors.red,
      );

      // Should not throw error even without image
      expect(() async => await controller.exportImage(), returnsNormally);

      controller.dispose();
    });
  });
}
