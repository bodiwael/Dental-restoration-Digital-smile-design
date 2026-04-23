import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:image/image.dart' as img;

import '../core/providers/session_provider.dart';
import '../core/models/restoration_models.dart' as models;
import '../app_theme.dart';
import '../widgets/mask_painter.dart';
import '../widgets/before_after_viewer.dart';
import '../widgets/shade_grid.dart';
import '../widgets/restoration_selector.dart';

/// Main editor screen for applying restorations
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  models.RestorationType _selectedType = models.RestorationType.crown;
  models.MaterialType _selectedMaterial = models.MaterialType.zirconia;
  models.VitaShade _selectedShade = models.VitaShade.A2;
  bool _showBeforeAfter = false;
  double _beforeAfterPosition = 0.5;

  @override
  void initState() {
    super.initState();
    // Initialize SAM when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionNotifierProvider.notifier).initializeSAM();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smile Designer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: sessionState.appliedRestorations.isEmpty
                ? null
                : () => ref
                    .read(sessionNotifierProvider.notifier)
                    .undoLastRestoration(),
          ),
          IconButton(
            icon: const Icon(Icons.compare),
            color: _showBeforeAfter ? AppTheme.primaryBlue : null,
            onPressed: () {
              setState(() => _showBeforeAfter = !_showBeforeAfter);
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportPDF(context, sessionState),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image viewer with tap handling
          Expanded(
            child: _buildImageViewer(sessionState),
          ),

          // DSD controls
          if (sessionState.dsdConfig.showGrid ||
              sessionState.dsdConfig.showMidline)
            _buildDSDOverlay(sessionState),

          // Control panel
          _buildControlPanel(sessionState),
        ],
      ),
    );
  }

  Widget _buildImageViewer(SessionState state) {
    if (state.loadedImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTapDown: (details) {
        // Get tap position normalized to image coordinates
        final RenderBox box = context.findRenderObject() as RenderBox;
        final size = box.size;
        final tapX = details.localPosition.dx / size.width;
        final tapY = details.localPosition.dy / size.height;

        // Apply restoration at tap position
        ref
            .read(sessionNotifierProvider.notifier)
            .applyRestorationAt(tapX, tapY);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Main image
              Positioned.fill(
                child: _showBeforeAfter
                    ? BeforeAfterViewer(
                        beforeImage: state.loadedImage!,
                        afterImage: state.loadedImage!, // TODO: Store original
                        position: _beforeAfterPosition,
                        onPositionChanged: (pos) {
                          setState(() => _beforeAfterPosition = pos);
                        },
                      )
                    : Image.memory(
                        _encodeImageToPng(state.loadedImage!),
                        fit: BoxFit.contain,
                      ),
              ),

              // Mask overlay (if processing)
              if (state.isProcessing)
                const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 16),
                          Text('Processing...'),
                        ],
                      ),
                    ),
                  ),
                ),

              // Error message
              if (state.errorMessage != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    color: AppTheme.errorRed,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              ref.read(sessionNotifierProvider.notifier);
                              // Clear error
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDSDOverlay(SessionState state) {
    return Container(
      height: 40,
      color: Colors.black.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.dsdConfig.showMidline)
            const VerticalDivider(
              color: Colors.red,
              width: 2,
              thickness: 2,
            ),
          if (state.dsdConfig.showGrid) ...[
            const SizedBox(width: 16),
            Text(
              'Grid Active',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlPanel(SessionState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Restoration type selector
          RestorationSelector(
            selectedType: _selectedType,
            selectedMaterial: _selectedMaterial,
            onTypeSelected: (type) {
              setState(() => _selectedType = type);
              _updatePendingConfig(state);
            },
            onMaterialSelected: (material) {
              setState(() => _selectedMaterial = material);
              _updatePendingConfig(state);
            },
          ),

          const Divider(height: 1),

          // Shade selector
          SizedBox(
            height: 60,
            child: ShadeGrid(
              selectedShade: _selectedShade,
              onShadeSelected: (shade) {
                setState(() => _selectedShade = shade);
                _updatePendingConfig(state);
              },
            ),
          ),

          const Divider(height: 1),

          // DSD and action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final notifier = ref.read(sessionNotifierProvider.notifier);
                      final currentDSD = state.dsdConfig;
                      notifier.updateDSDConfig(
                        currentDSD.copyWith(showGrid: !currentDSD.showGrid),
                      );
                    },
                    icon: const Icon(Icons.grid_on),
                    label: const Text('Grid'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final notifier = ref.read(sessionNotifierProvider.notifier);
                      final currentDSD = state.dsdConfig;
                      notifier.updateDSDConfig(
                        currentDSD.copyWith(showMidline: !currentDSD.showMidline),
                      );
                    },
                    icon: const Icon(Icons.vertical_align_center),
                    label: const Text('Midline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSaveDialog(context, state),
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updatePendingConfig(SessionState state) {
    final config = models.RestorationConfig(
      type: _selectedType,
      material: _selectedMaterial,
      shade: _selectedShade,
      toothNumber: 8, // Default to central incisor
    );
    ref.read(sessionNotifierProvider.notifier).setPendingConfig(config);
  }

  void _exportPDF(BuildContext context, SessionState state) {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export coming soon')),
    );
  }

  void _showSaveDialog(BuildContext context, SessionState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Case'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Patient Name',
            hintText: 'Enter patient name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(sessionNotifierProvider.notifier)
                    .saveCase(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Case saved successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Uint8List _encodeImageToPng(img.Image image) {
    return Uint8List.fromList(img.encodePng(image));
  }
}
