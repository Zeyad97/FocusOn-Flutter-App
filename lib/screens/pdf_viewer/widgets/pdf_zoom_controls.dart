import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Enhanced zoom controls widget for PDF viewer
class PDFZoomControls extends StatelessWidget {
  final double zoomLevel;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitWidth;
  final VoidCallback onFitHeight;
  final VoidCallback onActualSize;

  const PDFZoomControls({
    super.key,
    required this.zoomLevel,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitWidth,
    required this.onFitHeight,
    required this.onActualSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom out button
          _ZoomButton(
            icon: Icons.zoom_out,
            onPressed: zoomLevel > 0.25 ? onZoomOut : null,
            tooltip: 'Zoom Out',
          ),
          
          const SizedBox(width: 8),
          
          // Zoom percentage display
          GestureDetector(
            onTap: _showZoomDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(zoomLevel * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Zoom in button
          _ZoomButton(
            icon: Icons.zoom_in,
            onPressed: zoomLevel < 5.0 ? onZoomIn : null,
            tooltip: 'Zoom In',
          ),
          
          const SizedBox(width: 12),
          
          // Separator
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withOpacity(0.3),
          ),
          
          const SizedBox(width: 12),
          
          // Fit width button
          _ZoomButton(
            icon: Icons.fit_screen,
            onPressed: onFitWidth,
            tooltip: 'Fit Width',
            isActive: _isNearZoomLevel(1.0),
          ),
          
          const SizedBox(width: 8),
          
          // Fit height button
          _ZoomButton(
            icon: Icons.height,
            onPressed: onFitHeight,
            tooltip: 'Fit Height',
          ),
          
          const SizedBox(width: 8),
          
          // Actual size button
          _ZoomButton(
            icon: Icons.fullscreen,
            onPressed: onActualSize,
            tooltip: 'Actual Size',
          ),
        ],
      ),
    );
  }

  bool _isNearZoomLevel(double target) {
    return (zoomLevel - target).abs() < 0.1;
  }

  void _showZoomDialog() {
    // TODO: Implement zoom level selection dialog
  }
}

/// Individual zoom control button
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isActive;

  const _ZoomButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive 
                  ? AppColors.primaryPurple.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: onPressed != null 
                  ? (isActive ? AppColors.primaryPurple : Colors.white)
                  : Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced zoom slider widget
class PDFZoomSlider extends StatelessWidget {
  final double zoomLevel;
  final Function(double) onZoomChanged;

  const PDFZoomSlider({
    super.key,
    required this.zoomLevel,
    required this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom level indicator
          Text(
            '${(zoomLevel * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Zoom slider
          SizedBox(
            width: 200,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primaryPurple,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
                thumbColor: AppColors.primaryPurple,
                overlayColor: AppColors.primaryPurple.withOpacity(0.3),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                trackHeight: 4,
              ),
              child: Slider(
                value: zoomLevel.clamp(0.25, 5.0),
                min: 0.25,
                max: 5.0,
                divisions: 19, // 0.25, 0.5, 0.75, 1.0, 1.25, ... 5.0
                onChanged: onZoomChanged,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Zoom level markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('25%', style: _markerStyle),
              Text('50%', style: _markerStyle),
              Text('100%', style: _markerStyle),
              Text('200%', style: _markerStyle),
              Text('500%', style: _markerStyle),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle get _markerStyle => TextStyle(
    color: Colors.white.withOpacity(0.7),
    fontSize: 10,
  );
}
