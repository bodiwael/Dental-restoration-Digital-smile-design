# SmileCraft - Dental Restoration Simulator

**100% on-device Flutter app for Android. No server, no internet required.**

## Features

- **Restoration Types:**
  - Crown (Zirconia, e.max, Porcelain, PFM, Gold, Metal)
  - Bridge (multi-unit, connector rendering)
  - Veneer (Porcelain, Composite, e.max)
  - Implant crown simulation
  - Partial & Complete Denture

- **Digital Smile Design (DSD):**
  - Grid overlay
  - Midline marker
  - Pupillary line
  - Smile arc guide
  - Whitening simulation (0-10 levels)

- **Full Vita Shade Guide:** A1–D4 (16 shades)
- **Before/After Comparison:** Drag slider to compare
- **PDF Report Export:** Professional case documentation

## Architecture

```
Photo → MediaPipe FaceMesh (2MB, 16ms)
     → Detects mouth/teeth zone

Tap on tooth → MobileSAM Encoder (22MB) — runs once per photo, ~400ms
            → MobileSAM Decoder (16MB) — runs per tap, ~80ms
            → Boolean pixel mask

Pick restoration + material + shade
→ TextureRenderer (pure Dart)
→ Luminance-preserving pixel blend + gloss highlight + translucency edge
→ Result image in <100ms
```

## Performance Targets (Snapdragon 695 / mid-range)

| Step | Time |
|------|------|
| SAM image encoding | ~400ms (once) |
| SAM tap → mask | ~80ms |
| Texture render | ~80ms |
| **Total per restoration** | **~160ms after first tap** |

## Setup Instructions

### 1. Install Flutter

```bash
# Download Flutter SDK from https://flutter.dev
# Add to PATH

flutter --version   # Need 3.19+
flutter doctor      # Check setup
```

### 2. Get Dependencies

```bash
cd /workspace
flutter pub get
```

### 3. Download MobileSAM TFLite Models

#### Option A: Convert yourself (recommended for latest version)

```bash
# Install Python dependencies
pip install mobile-sam torch onnx onnx-tf tensorflow

# Download MobileSAM checkpoint
wget https://github.com/ChaoningZhang/MobileSAM/releases/download/v1.0/mobile_sam.pt

# Run conversion script
python scripts/convert_mobilesam.py

# Copy outputs to Flutter assets
cp mobile_sam_encoder.tflite assets/models/
cp mobile_sam_decoder.tflite assets/models/
```

#### Option B: Use pre-converted models

Download from releases and place in `assets/models/`:
- `mobile_sam_encoder.tflite` (~22MB)
- `mobile_sam_decoder.tflite` (~16MB)

### 4. Add Material Textures

Place 256×256 PNG textures in `assets/textures/`:

Required files:
- `zirconia.png` - Zirconia ceramic texture
- `emax.png` - IPS e.max texture
- `porcelain.png` - Feldspathic porcelain
- `pfm.png` - Porcelain-fused-to-metal
- `gold.png` - Gold alloy
- `metal.png` - Base metal
- `composite.png` - Composite resin
- `acrylic.png` - Denture acrylic

You can generate these procedurally (app includes fallback generators) or use dental stock textures.

### 5. Configure Android Permissions

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
```

### 6. Build & Run

```bash
# Debug mode
flutter run

# Release APK
flutter build apk --release

# Release AAB (Play Store)
flutter build appbundle --release
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app_theme.dart               # Theme configuration
├── core/
│   ├── models/
│   │   └── restoration_models.dart  # Domain models
│   ├── services/
│   │   ├── mobile_sam_service.dart  # SAM inference
│   │   └── texture_renderer.dart    # Image rendering
│   └── providers/
│       └── session_provider.dart    # State management
├── screens/
│   ├── home_screen.dart         # Main navigation
│   └── editor_screen.dart       # Restoration editor
└── widgets/
    ├── restoration_selector.dart
    ├── shade_grid.dart
    ├── before_after_viewer.dart
    └── mask_painter.dart

assets/
├── models/                      # TFLite models
└── textures/                    # Material textures

scripts/
└── convert_mobilesam.py         # Model conversion
```

## Usage Flow

1. **Launch App** → Tap "New Case"
2. **Capture Photo** → Take or select patient smile photo
3. **Select Restoration** → Choose type (Crown, Veneer, etc.)
4. **Pick Material** → Select material and Vita shade
5. **Tap Tooth** → Tap on tooth to apply restoration
6. **Adjust DSD** → Toggle grid, midline, whitening
7. **Compare** → Drag slider for before/after view
8. **Save** → Enter patient name and save case
9. **Export PDF** → Generate professional report

## Technical Notes

### MobileSAM Integration

The app uses MobileSAM (Segment Anything Model) for precise tooth segmentation:

1. **Encoder** runs once when photo loads (~400ms)
   - Converts image to 256-dim embedding
   - Output cached for all subsequent taps

2. **Decoder** runs per tap (~80ms)
   - Takes embedding + point coordinate
   - Outputs binary mask (1024×1024)
   - Resized to match original image

### Texture Rendering

Pure Dart implementation with luminance-preserving blend:

1. Load material texture (procedural or PNG)
2. Apply Vita shade tint
3. Blend with original tooth preserving luminance
4. Add specular gloss highlight
5. Apply edge translucency for realism

### Memory Management

- Images decoded at display resolution
- SAM embeddings cached per session
- Textures cached after first load
- Automatic cleanup on session end

## Troubleshooting

### Model Loading Errors

Ensure TFLite files are in `assets/models/` and listed in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/
```

### Performance Issues

- Reduce image size if >4MP
- Close other apps to free RAM
- First tap slower due to encoder initialization

### Build Failures

```bash
flutter clean
flutter pub get
flutter run
```

## License

© 2024 SmileCraft. All rights reserved.

## Credits

- MobileSAM: https://github.com/ChaoningZhang/MobileSAM
- Flutter: https://flutter.dev
- MediaPipe: https://google.github.io/mediapipe
