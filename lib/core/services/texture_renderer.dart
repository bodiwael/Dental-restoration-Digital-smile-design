import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/restoration_models.dart';

/// Pure Dart texture renderer for dental restorations
/// Applies material textures with luminance-preserving blending
class TextureRenderer {
  /// Cache of loaded material textures
  final Map<MaterialType, img.Image?> _textureCache = {};
  
  /// Load a material texture from assets
  Future<void> loadTexture(MaterialType material) async {
    if (_textureCache.containsKey(material)) return;
    
    final String assetPath;
    switch (material) {
      case MaterialType.zirconia:
        assetPath = 'assets/textures/zirconia.png';
        break;
      case MaterialType.eMax:
        assetPath = 'assets/textures/emax.png';
        break;
      case MaterialType.porcelain:
        assetPath = 'assets/textures/porcelain.png';
        break;
      case MaterialType.pfm:
        assetPath = 'assets/textures/pfm.png';
        break;
      case MaterialType.gold:
        assetPath = 'assets/textures/gold.png';
        break;
      case MaterialType.metal:
        assetPath = 'assets/textures/metal.png';
        break;
      case MaterialType.composite:
        assetPath = 'assets/textures/composite.png';
        break;
      case MaterialType.acrylic:
        assetPath = 'assets/textures/acrylic.png';
        break;
    }
    
    // TODO: Load from assets using rootBundle
    // For now, generate procedural texture
    _textureCache[material] = _generateProceduralTexture(material);
  }
  
  /// Generate procedural texture for materials
  img.Image _generateProceduralTexture(MaterialType material) {
    const size = 256;
    final image = img.Image(width: size, height: size);
    
    final baseColor = _getMaterialBaseColor(material);
    
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        // Add subtle noise and variation
        final noise = (x * 7 + y * 13) % 20 - 10;
        final r = (baseColor[0] + noise).clamp(0, 255).toInt();
        final g = (baseColor[1] + noise).clamp(0, 255).toInt();
        final b = (baseColor[2] + noise).clamp(0, 255).toInt();
        
        // Add subtle gradient for depth
        final gradient = ((x + y) / 512.0 * 30).toInt();
        
        image.setPixelRgba(
          x, y,
          (r + gradient).clamp(0, 255).toInt(),
          (g + gradient).clamp(0, 255).toInt(),
          (b + gradient).clamp(0, 255).toInt(),
          255,
        );
      }
    }
    
    return image;
  }
  
  /// Get base RGB color for each material type
  List<int> _getMaterialBaseColor(MaterialType material) {
    switch (material) {
      case MaterialType.zirconia:
        return [245, 240, 235]; // Off-white
      case MaterialType.eMax:
        return [250, 245, 238]; // Translucent white
      case MaterialType.porcelain:
        return [248, 243, 235]; // Ceramic white
      case MaterialType.pfm:
        return [240, 235, 228]; // Slightly gray
      case MaterialType.gold:
        return [212, 175, 55]; // Gold
      case MaterialType.metal:
        return [180, 180, 185]; // Silver-gray
      case MaterialType.composite:
        return [242, 238, 230]; // Resin white
      case MaterialType.acrylic:
        return [235, 230, 225]; // Denture acrylic
    }
  }
  
  /// Apply restoration texture to image using mask
  /// Uses luminance-preserving blend for realistic results
  img.Image applyRestoration({
    required img.Image originalImage,
    required img.Image mask,
    required RestorationConfig config,
  }) {
    // Ensure texture is loaded
    if (!_textureCache.containsKey(config.material)) {
      throw Exception('Texture not loaded for ${config.material}');
    }
    
    final texture = _textureCache[config.material]!;
    if (texture.width == 0 || texture.height == 0) {
      throw Exception('Invalid texture for ${config.material}');
    }
    
    // Create output image
    final result = img.Image.from(originalImage);
    
    // Get shade color
    final shadeColor = _shadeToRgb(config.shade);
    
    // Apply texture with luminance preservation
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final maskAlpha = mask.getPixel(x, y).a;
        
        if (maskAlpha > 0) {
          final originalPixel = originalImage.getPixel(x, y);
          final textureX = (x * texture.width / result.width).floor() % texture.width;
          final textureY = (y * texture.height / result.height).floor() % texture.height;
          var texturePixel = texture.getPixel(textureX, textureY);
          
          // Convert to ColorRgb8 for processing
          final textureColor = img.ColorRgb8(texturePixel.r, texturePixel.g, texturePixel.b);
          
          // Apply shade tint to texture
          final shadedTexture = _applyShadeTint(textureColor, shadeColor);
          
          // Convert original pixel to ColorRgb8
          final originalColor = img.ColorRgb8(originalPixel.r, originalPixel.g, originalPixel.b);
          
          // Luminance-preserving blend
          final blended = _luminanceBlend(
            originalColor,
            shadedTexture,
            config.opacity,
          );
          
          // Apply gloss highlight
          final withGloss = _applyGloss(blended, x, y, result.width, result.height, config.gloss);
          
          // Apply edge translucency
          final finalPixel = _applyTranslucencyEdge(
            withGloss,
            x, y,
            mask,
            config.translucency,
          );
          
          result.setPixelRgb(x, y, finalPixel.r, finalPixel.g, finalPixel.b);
        }
      }
    }
    
    return result;
  }
  
  /// Convert VitaShade to RGB
  List<int> _shadeToRgb(VitaShade shade) {
    final color = shade.approximateColor;
    return [
      (color >> 16) & 0xFF,
      (color >> 8) & 0xFF,
      color & 0xFF,
    ];
  }
  
  /// Apply shade tint to texture pixel
  img.ColorRgb8 _applyShadeTint(img.ColorRgb8 pixel, List<int> shadeRgb) {
    // Blend texture with shade color
    final r = ((pixel.r * 0.7) + (shadeRgb[0] * 0.3)).toInt().clamp(0, 255);
    final g = ((pixel.g * 0.7) + (shadeRgb[1] * 0.3)).toInt().clamp(0, 255);
    final b = ((pixel.b * 0.7) + (shadeRgb[2] * 0.3)).toInt().clamp(0, 255);
    return img.ColorRgb8(r, g, b);
  }
  
  /// Luminance-preserving blend between original and texture
  img.ColorRgb8 _luminanceBlend(img.ColorRgb8 original, img.ColorRgb8 texture, double opacity) {
    // Calculate original luminance
    final origLum = 0.299 * original.r + 0.587 * original.g + 0.114 * original.b;
    
    // Blend colors
    final r = (original.r * (1 - opacity) + texture.r * opacity).toInt().clamp(0, 255);
    final g = (original.g * (1 - opacity) + texture.g * opacity).toInt().clamp(0, 255);
    final b = (original.b * (1 - opacity) + texture.b * opacity).toInt().clamp(0, 255);
    
    // Calculate blended luminance
    final blendLum = 0.299 * r + 0.587 * g + 0.114 * b;
    
    // Adjust to match original luminance
    if (blendLum > 0) {
      final lumRatio = origLum / blendLum;
      return img.ColorRgb8(
        (r * lumRatio).toInt().clamp(0, 255),
        (g * lumRatio).toInt().clamp(0, 255),
        (b * lumRatio).toInt().clamp(0, 255),
      );
    }
    
    return img.ColorRgb8(r, g, b);
  }
  
  /// Apply gloss highlight based on position
  img.ColorRgb8 _applyGloss(
    img.ColorRgb8 pixel,
    int x, int y,
    int width, int height,
    double gloss,
  ) {
    if (gloss <= 0) return pixel;
    
    // Create specular highlight in upper-left quadrant
    final centerX = width * 0.3;
    final centerY = height * 0.3;
    final radius = width * 0.25;
    
    final dx = x - centerX;
    final dy = y - centerY;
    final dist = math.sqrt(dx * dx + dy * dy);
    
    if (dist < radius) {
      final intensity = (1 - dist / radius) * gloss * 0.5;
      final highlight = (255 * intensity).toInt();
      return img.ColorRgb8(
        (pixel.r + highlight).clamp(0, 255).toInt(),
        (pixel.g + highlight).clamp(0, 255).toInt(),
        (pixel.b + highlight).clamp(0, 255).toInt(),
      );
    }
    
    return pixel;
  }
  
  /// Apply translucency at mask edges
  img.ColorRgb8 _applyTranslucencyEdge(
    img.ColorRgb8 pixel,
    int x, int y,
    img.Image mask,
    double translucency,
  ) {
    if (translucency <= 0) return pixel;
    
    // Check neighbors for edge detection
    var neighborCount = 0;
    var neighborSum = 0;
    
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < mask.width && ny >= 0 && ny < mask.height) {
          neighborCount++;
          neighborSum += mask.getPixel(nx, ny).a;
        }
      }
    }
    
    final avgNeighbor = neighborCount > 0 ? neighborSum / neighborCount : 255;
    final edgeFactor = (255 - avgNeighbor) / 255; // Higher at edges
    
    if (edgeFactor > 0.1) {
      // Make edges more translucent
      final newAlpha = (pixel.a * (1 - edgeFactor * translucency * 0.5)).toInt().clamp(0, 255);
      return img.ColorRgb8(pixel.r, pixel.g, pixel.b);
    }
    
    return pixel;
  }
  
  /// Apply whitening effect to entire image
  img.Image applyWhitening(img.Image image, int level) {
    if (level <= 0) return image;
    
    final result = img.Image.from(image);
    final factor = 1.0 + (level * 0.05); // Up to 50% brighter
    
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);
        final r = (pixel.r * factor).toInt().clamp(0, 255);
        final g = (pixel.g * factor).toInt().clamp(0, 255);
        final b = (pixel.b * factor).toInt().clamp(0, 255);
        result.setPixelRgb(x, y, r, g, b);
      }
    }
    
    return result;
  }
  
  /// Clear texture cache
  void clearCache() {
    _textureCache.clear();
  }
}
