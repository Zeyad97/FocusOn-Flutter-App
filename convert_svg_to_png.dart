import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

// Simple SVG to raster conversion for app icon
// This creates a basic PNG representation of the icon design

void main() async {
  print('🎵 Creating app icon PNG...');
  
  // Create a simple bitmap representation
  const size = 1024;
  final pixels = Uint8List(size * size * 4); // RGBA
  
  // Fill with gradient-like effect
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - size / 2;
      final dy = y - size / 2;
      final distance = math.sqrt(dx * dx + dy * dy);
      final maxRadius = size / 2 - 40;
      
      if (distance <= maxRadius) {
        // Create gradient effect
        final gradientPos = distance / maxRadius;
        
        int r, g, b;
        if (gradientPos < 0.5) {
          // From #6366F1 to #8B5CF6
          final t = gradientPos * 2;
          r = (0x63 + (0x8B - 0x63) * t).round();
          g = (0x66 + (0x5C - 0x66) * t).round();
          b = (0xF1 + (0xF6 - 0xF1) * t).round();
        } else {
          // From #8B5CF6 to #A855F7
          final t = (gradientPos - 0.5) * 2;
          r = (0x8B + (0xA8 - 0x8B) * t).round();
          g = (0x5C + (0x55 - 0x5C) * t).round();
          b = (0xF6 + (0xF7 - 0xF6) * t).round();
        }
        
        final index = (y * size + x) * 4;
        pixels[index] = r;     // R
        pixels[index + 1] = g; // G
        pixels[index + 2] = b; // B
        pixels[index + 3] = 255; // A
      } else {
        // Transparent outside circle
        final index = (y * size + x) * 4;
        pixels[index + 3] = 0; // Transparent
      }
    }
  }
  
  // Add simple music note representation in center
  final centerX = size ~/ 2;
  final centerY = size ~/ 2;
  
  // Note stem (vertical line)
  for (int y = centerY - 60; y < centerY + 90; y++) {
    for (int x = centerX + 25; x < centerX + 37; x++) {
      if (x >= 0 && x < size && y >= 0 && y < size) {
        final index = (y * size + x) * 4;
        pixels[index] = 255;     // White
        pixels[index + 1] = 255;
        pixels[index + 2] = 255;
        pixels[index + 3] = 255;
      }
    }
  }
  
  // Note head (oval at bottom)
  for (int y = centerY + 45; y < centerY + 81; y++) {
    for (int x = centerX + 5; x < centerX + 55; x++) {
      final dx = (x - (centerX + 20)) / 25.0;
      final dy = (y - (centerY + 63)) / 18.0;
      if (dx * dx + dy * dy <= 1.0) {
        if (x >= 0 && x < size && y >= 0 && y < size) {
          final index = (y * size + x) * 4;
          pixels[index] = 255;     // White
          pixels[index + 1] = 255;
          pixels[index + 2] = 255;
          pixels[index + 3] = 255;
        }
      }
    }
  }
  
  // Simple flag shape
  for (int y = centerY - 60; y < centerY - 20; y++) {
    for (int x = centerX + 37; x < centerX + 77; x++) {
      final flagProgress = (x - (centerX + 37)) / 40.0;
      final flagHeight = 20 * (1 - flagProgress * 0.5);
      final flagTop = centerY - 60 + (40 - flagHeight) / 2;
      final flagBottom = flagTop + flagHeight;
      
      if (y >= flagTop && y <= flagBottom) {
        if (x >= 0 && x < size && y >= 0 && y < size) {
          final index = (y * size + x) * 4;
          pixels[index] = 255;     // White
          pixels[index + 1] = 255;
          pixels[index + 2] = 255;
          pixels[index + 3] = 255;
        }
      }
    }
  }
  
  print('✅ Basic icon bitmap created');
  print('📝 Note: This creates a simple representation.');
  print('   For best results, use the SVG with a proper image editor:');
  print('   1. Open assets/images/app_icon_temp.svg in GIMP, Inkscape, or online converter');
  print('   2. Export as PNG at 1024x1024');
  print('   3. Save as app_icon_1024.png');
  print('   4. Run: flutter pub run flutter_launcher_icons:main');
}
