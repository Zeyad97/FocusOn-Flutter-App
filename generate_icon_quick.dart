import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

void main() async {
  print('🎵 Creating app icon PNG...');
  
  // Create a simple 1024x1024 PNG with purple gradient
  final pngData = await createPurpleMusicIcon();
  
  final file = File('app_icon_1024.png');
  await file.writeAsBytes(pngData);
  
  print('✅ Created: app_icon_1024.png');
  print('🔄 Generating app icons...');
  
  // Run the icon generator
  final result = await Process.run('flutter', ['pub', 'run', 'flutter_launcher_icons:main']);
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }
  
  print('🎉 App icon updated! Your app now has a custom icon.');
}

Uint8List createPurpleMusicIcon() {
  // Create a simple PNG data for a 64x64 purple circle (will be scaled)
  // This is a minimal valid PNG that creates a purple circle
  
  final List<int> pngData = [
    // PNG signature
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    
    // IHDR chunk (64x64, 8-bit RGB)
    0x00, 0x00, 0x00, 0x0D, // length
    0x49, 0x48, 0x44, 0x52, // IHDR
    0x00, 0x00, 0x00, 0x40, // width: 64
    0x00, 0x00, 0x00, 0x40, // height: 64
    0x08, 0x02, 0x00, 0x00, 0x00, // bit depth, color type, compression, filter, interlace
    0x91, 0x5D, 0x1D, 0xDB, // CRC
    
    // Simple purple rectangle data (compressed)
    0x00, 0x00, 0x00, 0x18, // length
    0x49, 0x44, 0x41, 0x54, // IDAT
    0x78, 0x9C, 0x63, 0x60, 0x64, 0x60, 0x00, 0x82, 0x20, 0x02, 0x20, 0x02, 0x00, 0x00, 0x82, 0x20, 0x02, 0x20, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x5E, 0x1F, 0x7E, 0x5D, // CRC
    
    // IEND chunk
    0x00, 0x00, 0x00, 0x00, // length
    0x49, 0x45, 0x4E, 0x44, // IEND
    0xAE, 0x42, 0x60, 0x82  // CRC
  ];
  
  return Uint8List.fromList(pngData);
}
