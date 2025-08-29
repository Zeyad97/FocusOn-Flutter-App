import 'dart:io';
import 'dart:typed_data';

void main() async {
  print('🔴 Creating a simple RED icon to test...');
  
  // Create a simple red square PNG
  final redIcon = createRedIcon();
  
  final file = File('app_icon_1024.png');
  await file.writeAsBytes(redIcon);
  
  print('✅ Created red test icon: app_icon_1024.png');
  print('🔄 Now running icon generator...');
  
  // Run the icon generator
  final result = await Process.run('flutter', ['pub', 'run', 'flutter_launcher_icons:main']);
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }
  
  print('🎯 Icons generated! Now building app...');
  
  // Build the app
  final buildResult = await Process.run('flutter', ['build', 'apk']);
  print(buildResult.stdout);
  
  print('🚀 Done! Check your app icon now - it should be RED!');
}

Uint8List createRedIcon() {
  // Simple 8x8 red PNG (will be scaled up)
  return Uint8List.fromList([
    // PNG signature
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    
    // IHDR chunk (8x8, 8-bit RGB)
    0x00, 0x00, 0x00, 0x0D, // length
    0x49, 0x48, 0x44, 0x52, // IHDR
    0x00, 0x00, 0x00, 0x08, // width: 8
    0x00, 0x00, 0x00, 0x08, // height: 8
    0x08, 0x02, 0x00, 0x00, 0x00, // bit depth, color type, compression, filter, interlace
    0x4A, 0x7D, 0x64, 0x2C, // CRC
    
    // IDAT chunk (red pixels)
    0x00, 0x00, 0x00, 0x14, // length
    0x49, 0x44, 0x41, 0x54, // IDAT
    0x78, 0x9C, 0x63, 0xF8, 0x00, 0x00, 0x00, 0x60, 0x00, 0x58, 0x05, 0xD4, 0x07, 0x35, 0x01, 0x1E, 0x60, 0x00, 0x00, 0x27,
    0x10, 0x00, 0x01, 0xFD, // Compressed red data
    
    // IEND chunk
    0x00, 0x00, 0x00, 0x00, // length
    0x49, 0x45, 0x4E, 0x44, // IEND
    0xAE, 0x42, 0x60, 0x82  // CRC
  ]);
}
