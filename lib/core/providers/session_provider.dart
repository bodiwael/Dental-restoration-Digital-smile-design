import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restoration_models.dart';
import '../services/mobile_sam_service.dart';
import '../services/texture_renderer.dart';

/// Provider for MobileSamService
final mobileSamServiceProvider = Provider<MobileSamService>((ref) {
  return MobileSamService();
});

/// Provider for TextureRenderer
final textureRendererProvider = Provider<TextureRenderer>((ref) {
  return TextureRenderer();
});

/// Session state for the current patient case
class SessionState {
  final PatientCase? currentCase;
  final String? loadedImagePath;
  final img.Image? loadedImage;
  final Float32List? imageEmbedding;
  final List<Restoration> appliedRestorations;
  final RestorationConfig? pendingConfig;
  final DSDConfig dsdConfig;
  final bool isProcessing;
  final String? errorMessage;

  const SessionState({
    this.currentCase,
    this.loadedImagePath,
    this.loadedImage,
    this.imageEmbedding,
    this.appliedRestorations = const [],
    this.pendingConfig,
    this.dsdConfig = const DSDConfig(),
    this.isProcessing = false,
    this.errorMessage,
  });

  SessionState copyWith({
    PatientCase? currentCase,
    String? loadedImagePath,
    img.Image? loadedImage,
    Float32List? imageEmbedding,
    List<Restoration>? appliedRestorations,
    RestorationConfig? pendingConfig,
    DSDConfig? dsdConfig,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return SessionState(
      currentCase: currentCase ?? this.currentCase,
      loadedImagePath: loadedImagePath ?? this.loadedImagePath,
      loadedImage: loadedImage ?? this.loadedImage,
      imageEmbedding: imageEmbedding ?? this.imageEmbedding,
      appliedRestorations: appliedRestorations ?? this.appliedRestorations,
      pendingConfig: pendingConfig ?? this.pendingConfig,
      dsdConfig: dsdConfig ?? this.dsdConfig,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
    );
  }
}

/// Riverpod notifier for session management
class SessionNotifier extends StateNotifier<SessionState> {
  final MobileSamService _samService;
  final TextureRenderer _textureRenderer;

  SessionNotifier(this._samService, this._textureRenderer)
      : super(const SessionState());

  /// Initialize MobileSAM service
  Future<void> initializeSAM() async {
    try {
      state = state.copyWith(isProcessing: true, errorMessage: null);
      await _samService.initialize();
      state = state.copyWith(isProcessing: false);
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to initialize SAM: $e',
      );
    }
  }

  /// Load a patient photo
  Future<void> loadPhoto(String imagePath, img.Image image) async {
    try {
      state = state.copyWith(isProcessing: true, errorMessage: null);
      
      // Store image
      state = state.copyWith(
        loadedImagePath: imagePath,
        loadedImage: image,
      );
      
      // Encode image with MobileSAM (runs once)
      final embedding = await _samService.encodeImage(image);
      
      state = state.copyWith(
        imageEmbedding: embedding,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to load photo: $e',
      );
    }
  }

  /// Set pending restoration configuration
  void setPendingConfig(RestorationConfig config) {
    state = state.copyWith(pendingConfig: config);
  }

  /// Apply restoration at tap position
  Future<void> applyRestorationAt(double tapX, double tapY) async {
    if (state.loadedImage == null || state.imageEmbedding == null) {
      state = state.copyWith(errorMessage: 'No image loaded');
      return;
    }

    final config = state.pendingConfig;
    if (config == null) {
      state = state.copyWith(errorMessage: 'No restoration type selected');
      return;
    }

    try {
      state = state.copyWith(isProcessing: true, errorMessage: null);

      // Get mask from MobileSAM
      final maskBytes = await _samService.decodeMask(
        embedding: state.imageEmbedding!,
        pointX: tapX,
        pointY: tapY,
        label: 1, // Foreground
      );

      // Process mask to image size
      final mask = MobileSamService.processMask(
        maskBytes,
        state.loadedImage!.width,
        state.loadedImage!.height,
      );

      // Load material texture
      await _textureRenderer.loadTexture(config.material);

      // Apply restoration
      final resultImage = _textureRenderer.applyRestoration(
        originalImage: state.loadedImage!,
        mask: mask,
        config: config,
      );

      // Create restoration record
      final restoration = Restoration(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        config: config,
        maskBytes: maskBytes,
        width: mask.width,
        height: mask.height,
      );

      // Update state with new image and restoration
      state = state.copyWith(
        loadedImage: resultImage,
        appliedRestorations: [...state.appliedRestorations, restoration],
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to apply restoration: $e',
      );
    }
  }

  /// Update DSD configuration
  void updateDSDConfig(DSDConfig config) {
    state = state.copyWith(dsdConfig: config);
  }

  /// Apply whitening effect
  Future<void> applyWhitening(int level) async {
    if (state.loadedImage == null) return;

    try {
      state = state.copyWith(isProcessing: true);
      
      final whitenedImage = _textureRenderer.applyWhitening(
        state.loadedImage!,
        level,
      );
      
      state = state.copyWith(
        loadedImage: whitenedImage,
        dsdConfig: state.dsdConfig.copyWith(whiteningLevel: level),
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to apply whitening: $e',
      );
    }
  }

  /// Undo last restoration
  void undoLastRestoration() {
    if (state.appliedRestorations.isEmpty || state.loadedImagePath == null) {
      return;
    }

    // Reload original image and reapply all but last restoration
    // For simplicity, just remove from list (in production, re-render)
    final updatedRestorations = state.appliedRestorations.sublist(
      0,
      state.appliedRestorations.length - 1,
    );

    state = state.copyWith(appliedRestorations: updatedRestorations);
  }

  /// Clear current session
  void clearSession() {
    state = const SessionState();
  }

  /// Create or update patient case
  void saveCase(String patientName) {
    final caseId = DateTime.now().millisecondsSinceEpoch.toString();
    
    state = state.copyWith(
      currentCase: PatientCase(
        id: caseId,
        patientName: patientName,
        restorations: state.appliedRestorations,
      ),
    );
  }

  @override
  void dispose() {
    _samService.dispose();
    _textureRenderer.clearCache();
    super.dispose();
  }
}

/// Provider for SessionNotifier
final sessionNotifierProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  final samService = ref.watch(mobileSamServiceProvider);
  final textureRenderer = ref.watch(textureRendererProvider);
  return SessionNotifier(samService, textureRenderer);
});
