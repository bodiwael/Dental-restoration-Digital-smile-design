import 'package:flutter/material.dart';
import '../core/models/restoration_models.dart';
import '../app_theme.dart';

/// Widget for selecting restoration type and material
class RestorationSelector extends StatelessWidget {
  final RestorationType selectedType;
  final MaterialType selectedMaterial;
  final Function(RestorationType) onTypeSelected;
  final Function(MaterialType) onMaterialSelected;

  const RestorationSelector({
    super.key,
    required this.selectedType,
    required this.selectedMaterial,
    required this.onTypeSelected,
    required this.onMaterialSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Restoration type selector
        _buildTypeSelector(context),
        const SizedBox(height: 12),
        // Material selector
        _buildMaterialSelector(context),
      ],
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: RestorationType.values.map((type) {
          final isSelected = selectedType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getTypeName(type)),
              selected: isSelected,
              onSelected: (selected) => onTypeSelected(type),
              selectedColor: AppTheme.primaryLight,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMaterialSelector(BuildContext context) {
    // Filter materials based on restoration type
    final availableMaterials = _getAvailableMaterials(selectedType);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: availableMaterials.map((material) {
          final isSelected = selectedMaterial == material;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: CircleAvatar(
                backgroundColor: _getMaterialColor(material),
                child: const SizedBox(width: 16, height: 16),
              ),
              label: Text(AppTheme.getMaterialTypeName(material)),
              selected: isSelected,
              onSelected: (selected) => onMaterialSelected(material),
              selectedColor: AppTheme.accentTeal.withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getTypeName(RestorationType type) {
    switch (type) {
      case RestorationType.crown:
        return 'Crown';
      case RestorationType.bridge:
        return 'Bridge';
      case RestorationType.veneer:
        return 'Veneer';
      case RestorationType.implantCrown:
        return 'Implant';
      case RestorationType.partialDenture:
        return 'Partial';
      case RestorationType.completeDenture:
        return 'Complete';
    }
  }

  List<MaterialType> _getAvailableMaterials(RestorationType type) {
    switch (type) {
      case RestorationType.crown:
        return [
          MaterialType.zirconia,
          MaterialType.eMax,
          MaterialType.porcelain,
          MaterialType.pfm,
          MaterialType.gold,
          MaterialType.metal,
        ];
      case RestorationType.bridge:
        return [
          MaterialType.zirconia,
          MaterialType.pfm,
          MaterialType.gold,
        ];
      case RestorationType.veneer:
        return [
          MaterialType.porcelain,
          MaterialType.composite,
          MaterialType.eMax,
        ];
      case RestorationType.implantCrown:
        return [
          MaterialType.zirconia,
          MaterialType.eMax,
          MaterialType.porcelain,
        ];
      case RestorationType.partialDenture:
        return [
          MaterialType.acrylic,
          MaterialType.metal,
        ];
      case RestorationType.completeDenture:
        return [
          MaterialType.acrylic,
          MaterialType.composite,
        ];
    }
  }

  Color _getMaterialColor(MaterialType material) {
    switch (material) {
      case MaterialType.zirconia:
        return const Color(0xFFF5F5F0);
      case MaterialType.eMax:
        return const Color(0xFFFAFAF5);
      case MaterialType.porcelain:
        return const Color(0xFFF8F8F0);
      case MaterialType.pfm:
        return const Color(0xFFE8E8E0);
      case MaterialType.gold:
        return const Color(0xFFD4AF37);
      case MaterialType.metal:
        return const Color(0xFFB0B0B5);
      case MaterialType.composite:
        return const Color(0xFFF2EEE6);
      case MaterialType.acrylic:
        return const Color(0xFFEBE8E5);
    }
  }
}
