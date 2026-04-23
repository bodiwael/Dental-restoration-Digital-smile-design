/// Core domain models for SmileCraft Dental Restoration Simulator

/// Represents a patient case with before/after images and restorations
class PatientCase {
  final String id;
  final String patientName;
  final DateTime createdAt;
  final List<Restoration> restorations;
  final String? beforeImagePath;
  final String? afterImagePath;

  PatientCase({
    required this.id,
    required this.patientName,
    DateTime? createdAt,
    this.restorations = const [],
    this.beforeImagePath,
    this.afterImagePath,
  }) : createdAt = createdAt ?? DateTime.now();

  PatientCase copyWith({
    String? id,
    String? patientName,
    DateTime? createdAt,
    List<Restoration>? restorations,
    String? beforeImagePath,
    String? afterImagePath,
  }) {
    return PatientCase(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      createdAt: createdAt ?? this.createdAt,
      restorations: restorations ?? this.restorations,
      beforeImagePath: beforeImagePath ?? this.beforeImagePath,
      afterImagePath: afterImagePath ?? this.afterImagePath,
    );
  }
}

/// Types of dental restorations
enum RestorationType {
  crown,
  bridge,
  veneer,
  implantCrown,
  partialDenture,
  completeDenture,
}

/// Material types for restorations
enum MaterialType {
  zirconia,
  eMax,
  porcelain,
  pfm, // Porcelain Fused to Metal
  gold,
  metal,
  composite,
  acrylic,
}

/// Vita shade guide colors (16 standard shades)
enum VitaShade {
  A1, A2, A3, A35, A4,
  B1, B2, B3, B4,
  C1, C2, C3, C4,
  D2, D3, D4,
}

/// Extension to get shade display name
extension VitaShadeExtension on VitaShade {
  String get displayName {
    switch (this) {
      case VitaShade.A1: return 'A1';
      case VitaShade.A2: return 'A2';
      case VitaShade.A3: return 'A3';
      case VitaShade.A35: return 'A3.5';
      case VitaShade.A4: return 'A4';
      case VitaShade.B1: return 'B1';
      case VitaShade.B2: return 'B2';
      case VitaShade.B3: return 'B3';
      case VitaShade.B4: return 'B4';
      case VitaShade.C1: return 'C1';
      case VitaShade.C2: return 'C2';
      case VitaShade.C3: return 'C3';
      case VitaShade.C4: return 'C4';
      case VitaShade.D2: return 'D2';
      case VitaShade.D3: return 'D3';
      case VitaShade.D4: return 'D4';
    }
  }

  /// Get approximate RGB color for preview
  int get approximateColor {
    switch (this) {
      case VitaShade.A1: return 0xFFFFF8E7;
      case VitaShade.A2: return 0xFFFDF5E0;
      case VitaShade.A3: return 0xFFFCEEC9;
      case VitaShade.A35: return 0xFFFBE9C0;
      case VitaShade.A4: return 0xFFF9E4B5;
      case VitaShade.B1: return 0xFFFFFAEB;
      case VitaShade.B2: return 0xFFFEF6E2;
      case VitaShade.B3: return 0xFFFDF2D8;
      case VitaShade.B4: return 0xFFFBEDCE;
      case VitaShade.C1: return 0xFFFDF8E8;
      case VitaShade.C2: return 0xFFFCEFDD;
      case VitaShade.C3: return 0xFFFBE5D2;
      case VitaShade.C4: return 0xFFF9DCC7;
      case VitaShade.D2: return 0xFFFDEEE0;
      case VitaShade.D3: return 0xFFFCE5D5;
      case VitaShade.D4: return 0xFFFBDCCA;
    }
  }
}

/// Configuration for a single restoration
class RestorationConfig {
  final RestorationType type;
  final MaterialType material;
  final VitaShade shade;
  final double opacity; // 0.0 to 1.0
  final double gloss; // 0.0 to 1.0
  final double translucency; // 0.0 to 1.0
  final int toothNumber; // Universal numbering system (1-32)
  final List<int>? bridgeUnits; // For bridges: list of tooth numbers

  RestorationConfig({
    required this.type,
    required this.material,
    this.shade = VitaShade.A2,
    this.opacity = 0.9,
    this.gloss = 0.7,
    this.translucency = 0.3,
    required this.toothNumber,
    this.bridgeUnits,
  });

  RestorationConfig copyWith({
    RestorationType? type,
    MaterialType? material,
    VitaShade? shade,
    double? opacity,
    double? gloss,
    double? translucency,
    int? toothNumber,
    List<int>? bridgeUnits,
  }) {
    return RestorationConfig(
      type: type ?? this.type,
      material: material ?? this.material,
      shade: shade ?? this.shade,
      opacity: opacity ?? this.opacity,
      gloss: gloss ?? this.gloss,
      translucency: translucency ?? this.translucency,
      toothNumber: toothNumber ?? this.toothNumber,
      bridgeUnits: bridgeUnits ?? this.bridgeUnits,
    );
  }
}

/// A completed restoration with mask data
class Restoration {
  final String id;
  final RestorationConfig config;
  final List<int> maskBytes; // RGBA mask pixels
  final int width;
  final int height;
  final DateTime appliedAt;

  Restoration({
    required this.id,
    required this.config,
    required this.maskBytes,
    required this.width,
    required this.height,
    DateTime? appliedAt,
  }) : appliedAt = appliedAt ?? DateTime.now();
}

/// Digital Smile Design configuration
class DSDConfig {
  final bool showGrid;
  final bool showMidline;
  final bool showPupillaryLine;
  final bool showSmileArc;
  final int whiteningLevel; // 0-10

  const DSDConfig({
    this.showGrid = false,
    this.showMidline = true,
    this.showPupillaryLine = false,
    this.showSmileArc = true,
    this.whiteningLevel = 0,
  });

  DSDConfig copyWith({
    bool? showGrid,
    bool? showMidline,
    bool? showPupillaryLine,
    bool? showSmileArc,
    int? whiteningLevel,
  }) {
    return DSDConfig(
      showGrid: showGrid ?? this.showGrid,
      showMidline: showMidline ?? this.showMidline,
      showPupillaryLine: showPupillaryLine ?? this.showPupillaryLine,
      showSmileArc: showSmileArc ?? this.showSmileArc,
      whiteningLevel: whiteningLevel ?? this.whiteningLevel,
    );
  }
}
