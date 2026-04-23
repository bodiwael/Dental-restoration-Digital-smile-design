import 'package:flutter/material.dart';
import '../core/models/restoration_models.dart';

/// Widget displaying Vita shade guide grid
class ShadeGrid extends StatelessWidget {
  final VitaShade selectedShade;
  final Function(VitaShade) onShadeSelected;

  const ShadeGrid({
    super.key,
    required this.selectedShade,
    required this.onShadeSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Group shades by row (A, B, C, D)
    final rows = [
      VitaShade.values.where((s) => s.name.startsWith('A')).toList(),
      VitaShade.values.where((s) => s.name.startsWith('B')).toList(),
      VitaShade.values.where((s) => s.name.startsWith('C')).toList(),
      VitaShade.values.where((s) => s.name.startsWith('D')).toList(),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((shade) {
                return _buildShadeButton(shade);
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShadeButton(VitaShade shade) {
    final isSelected = selectedShade == shade;
    final color = Color(shade.approximateColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => onShadeSelected(shade),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade400,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isSelected
              ? const Icon(
                  Icons.check,
                  size: 18,
                  color: Colors.black54,
                )
              : null,
        ),
      ),
    );
  }
}
