import 'dart:io';
import 'dart:math' as math;

void main() {
  print('🎵 Creating temporary app icon...');
  
  // This creates a simple SVG that can be converted to PNG
  final svgContent = '''
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="grad1" cx="30%" cy="30%" r="70%">
      <stop offset="0%" style="stop-color:#6366F1;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#8B5CF6;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#A855F7;stop-opacity:1" />
    </radialGradient>
    <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#6366F1" flood-opacity="0.4"/>
    </filter>
  </defs>
  
  <!-- Background Circle -->
  <circle cx="512" cy="512" r="480" fill="url(#grad1)" filter="url(#shadow)"/>
  
  <!-- Outer Ring -->
  <circle cx="512" cy="512" r="400" fill="none" stroke="rgba(255,255,255,0.3)" stroke-width="8"/>
  
  <!-- Inner Circle Background -->
  <circle cx="512" cy="512" r="320" fill="rgba(255,255,255,0.1)"/>
  
  <!-- Music Note Icon (simplified) -->
  <g transform="translate(512,512)">
    <!-- Note stem -->
    <rect x="50" y="-120" width="12" height="180" fill="white"/>
    <!-- Note head -->
    <ellipse cx="40" cy="60" rx="25" ry="18" fill="white"/>
    <!-- Flag -->
    <path d="M62 -120 Q120 -100 120 -60 Q120 -40 100 -45 L62 -60 Z" fill="white"/>
  </g>
</svg>
''';

  // Write SVG file
  final svgFile = File('assets/images/app_icon_temp.svg');
  svgFile.writeAsStringSync(svgContent);
  
  print('✅ Created temporary SVG icon: ${svgFile.path}');
  print('📝 To convert to PNG:');
  print('   1. Open the SVG in any image editor');
  print('   2. Export as PNG at 1024x1024');
  print('   3. Save as app_icon_1024.png');
  print('   4. Run: flutter pub run flutter_launcher_icons:main');
}
