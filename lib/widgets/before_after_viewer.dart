import 'package:flutter/material.dart';
import 'dart:typed_data';

/// Widget for before/after comparison with draggable divider
class BeforeAfterViewer extends StatefulWidget {
  final dynamic beforeImage; // img.Image
  final dynamic afterImage; // img.Image
  final double position; // 0.0 to 1.0
  final Function(double) onPositionChanged;

  const BeforeAfterViewer({
    super.key,
    required this.beforeImage,
    required this.afterImage,
    required this.position,
    required this.onPositionChanged,
  });

  @override
  State<BeforeAfterViewer> createState() => _BeforeAfterViewerState();
}

class _BeforeAfterViewerState extends State<BeforeAfterViewer> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Before image (background)
            Positioned.fill(
              child: Image.memory(
                _encodeImage(widget.beforeImage),
                fit: BoxFit.contain,
              ),
            ),

            // After image (clipped)
            Positioned.fill(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.position,
                  child: Image.memory(
                    _encodeImage(widget.afterImage),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Divider line
            Positioned(
              left: constraints.maxWidth * widget.position - 2,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragStart: (_) => setState(() => _isDragging = true),
                onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
                onHorizontalDragUpdate: (details) {
                  final newPosition = (details.localPosition.dx / constraints.maxWidth)
                      .clamp(0.0, 1.0);
                  widget.onPositionChanged(newPosition);
                },
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _isDragging ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.drag_handle,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Labels
            Positioned(
              left: 16,
              top: 16,
              child: _buildLabel('BEFORE'),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: _buildLabel('AFTER'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Uint8List _encodeImage(dynamic image) {
    // TODO: Implement proper encoding
    // For now, return empty bytes as placeholder
    return Uint8List(0);
  }
}
