// FlutterFlow Custom Widget - TEST VERSION
// Widget Name: SimpleImagePainter
// Parameters: width (double), height (double)
// Dependencies: NONE (for testing)

import 'package:flutter/material.dart';

class SimpleImagePainter extends StatefulWidget {
  const SimpleImagePainter({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key);

  final double width;
  final double height;

  @override
  SimpleImagePainterState createState() => SimpleImagePainterState();
}

class SimpleImagePainterState extends State<SimpleImagePainter> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Center(
        child: Text(
          'Image Painter\n${widget.width.toInt()} x ${widget.height.toInt()}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}
