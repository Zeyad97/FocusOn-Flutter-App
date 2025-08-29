import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Run this script to generate app icons matching the splash screen design
/// Usage: dart icon_generator.dart
void main() async {
  print('🎵 Generating app icons matching splash screen design...');
  
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  await generateAppIcon();
  print('✅ App icons generated successfully!');
  print('📱 Run: flutter packages pub run flutter_launcher_icons:main');
}

Future<void> generateAppIcon() async {
  // Create the app icon widget matching splash screen
  final iconWidget = AppIconWidget();
  
  // Generate different sizes
  final sizes = [1024, 512, 256, 128, 64]; // iOS and Android need various sizes
  
  for (final size in sizes) {
    final bytes = await _widgetToImage(iconWidget, size.toDouble());
    final file = File('assets/images/app_icon_${size}x$size.png');
    await file.writeAsBytes(bytes);
    print('Generated: app_icon_${size}x$size.png');
  }
  
  // Generate main app icon (512x512 for launcher icons)
  final mainBytes = await _widgetToImage(iconWidget, 512);
  final mainFile = File('assets/images/app_icon.png');
  await mainFile.writeAsBytes(mainBytes);
  
  // Generate foreground for adaptive icon (Android)
  final foregroundWidget = AppIconForegroundWidget();
  final foregroundBytes = await _widgetToImage(foregroundWidget, 512);
  final foregroundFile = File('assets/images/app_icon_foreground.png');
  await foregroundFile.writeAsBytes(foregroundBytes);
  
  print('Main app icon and foreground generated!');
}

Future<Uint8List> _widgetToImage(Widget widget, double size) async {
  final repaintBoundary = RenderRepaintBoundary();
  
  final renderView = RenderView(
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: repaintBoundary,
    ),
    configuration: ViewConfiguration(
      size: Size(size, size),
      devicePixelRatio: 1.0,
    ),
    window: PlatformDispatcher.instance.views.first,
  );
  
  final pipelineOwner = PipelineOwner();
  final buildOwner = BuildOwner(focusManager: FocusManager());
  
  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();
  
  final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    child: widget,
  ).attachToRenderTree(buildOwner);
  
  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();
  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();
  
  final image = await repaintBoundary.toImage(pixelRatio: 1.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  return byteData!.buffer.asUint8List();
}

/// App Icon Widget matching the splash screen design
class AppIconWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 512,
      height: 512,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1), // AppColors.primaryPurple
            Color(0xFF8B5CF6), // AppColors.accentPurple  
            Color(0xFFA855F7), // AppColors.lightPurple
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 8,
              ),
            ),
          ),
          
          // Main logo icon
          Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: Icon(
              Icons.music_note,
              size: 180,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Foreground for Android adaptive icon
class AppIconForegroundWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 512,
      height: 512,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 6,
              ),
            ),
          ),
          
          // Main logo icon
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              Icons.music_note,
              size: 140,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
