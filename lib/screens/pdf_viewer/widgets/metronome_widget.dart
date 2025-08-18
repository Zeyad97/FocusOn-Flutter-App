import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';

/// Metronome widget with visual and haptic feedback
class MetronomeWidget extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;

  const MetronomeWidget({
    super.key,
    required this.isVisible,
    required this.onClose,
  });

  @override
  State<MetronomeWidget> createState() => _MetronomeWidgetState();
}

class _MetronomeWidgetState extends State<MetronomeWidget>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  int _bpm = 120;
  int _timeSignature = 4;
  int _currentBeat = 0;
  Timer? _metronomeTimer;
  
  late AnimationController _visualController;
  late AnimationController _pendulumController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pendulumAnimation;

  @override
  void initState() {
    super.initState();
    
    _visualController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _pendulumController = AnimationController(
      duration: Duration(milliseconds: (60000 / _bpm).round()),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _visualController,
      curve: Curves.easeOut,
    ));
    
    _pendulumAnimation = Tween<double>(
      begin: -0.3,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _pendulumController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _metronomeTimer?.cancel();
    _visualController.dispose();
    _pendulumController.dispose();
    super.dispose();
  }

  void _startMetronome() {
    if (_isPlaying) return;
    
    setState(() {
      _isPlaying = true;
      _currentBeat = 0;
    });
    
    _pendulumController.duration = Duration(milliseconds: (60000 / _bpm).round());
    _pendulumController.repeat(reverse: true);
    
    _metronomeTimer = Timer.periodic(
      Duration(milliseconds: (60000 / _bpm).round()),
      (timer) {
        _tick();
      },
    );
    
    // First tick immediately
    _tick();
  }

  void _stopMetronome() {
    setState(() {
      _isPlaying = false;
      _currentBeat = 0;
    });
    
    _metronomeTimer?.cancel();
    _pendulumController.stop();
    _pendulumController.reset();
  }

  void _tick() {
    if (!mounted) return;
    
    setState(() {
      _currentBeat = (_currentBeat + 1) % _timeSignature;
    });
    
    // Visual feedback
    _visualController.forward().then((_) {
      _visualController.reverse();
    });
    
    // Haptic feedback - stronger on downbeat
    if (_currentBeat == 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _changeBpm(int delta) {
    setState(() {
      _bpm = math.max(40, math.min(200, _bpm + delta));
    });
    
    if (_isPlaying) {
      _stopMetronome();
      _startMetronome();
    }
  }

  void _changeTimeSignature() {
    setState(() {
      switch (_timeSignature) {
        case 2:
          _timeSignature = 3;
          break;
        case 3:
          _timeSignature = 4;
          break;
        case 4:
          _timeSignature = 6;
          break;
        case 6:
          _timeSignature = 2;
          break;
        default:
          _timeSignature = 4;
      }
      _currentBeat = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 100,
      right: 16,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Metronome',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Pendulum visual
            AnimatedBuilder(
              animation: _pendulumAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _pendulumAnimation.value,
                  child: Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Beat indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_timeSignature, (index) {
                final isActive = _isPlaying && index == _currentBeat;
                final isDownbeat = index == 0;
                
                return AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    final scale = isActive ? _scaleAnimation.value : 1.0;
                    
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isDownbeat ? AppColors.errorRed : AppColors.primaryBlue)
                              : Colors.grey.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: isDownbeat
                              ? Border.all(color: AppColors.errorRed, width: 2)
                              : null,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            
            const SizedBox(height: 16),
            
            // BPM display and controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeBpm(-5),
                  icon: const Icon(Icons.remove),
                ),
                Column(
                  children: [
                    Text(
                      '$_bpm',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'BPM',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _changeBpm(5),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Fine control slider
            Slider(
              value: _bpm.toDouble(),
              min: 40,
              max: 200,
              divisions: 160,
              onChanged: (value) {
                setState(() {
                  _bpm = value.round();
                });
                
                if (_isPlaying) {
                  _stopMetronome();
                  _startMetronome();
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Time signature and play/stop
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _changeTimeSignature,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_timeSignature/4',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: _isPlaying ? _stopMetronome : _startMetronome,
                  icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                  label: Text(_isPlaying ? 'Stop' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? AppColors.errorRed : AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Preset tempos
            Wrap(
              spacing: 8,
              children: [
                _TempoPreset('Largo', 60, _bpm, (bpm) => _setBpm(bpm)),
                _TempoPreset('Andante', 90, _bpm, (bpm) => _setBpm(bpm)),
                _TempoPreset('Allegro', 140, _bpm, (bpm) => _setBpm(bpm)),
                _TempoPreset('Presto', 180, _bpm, (bpm) => _setBpm(bpm)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setBpm(int bpm) {
    setState(() {
      _bpm = bpm;
    });
    
    if (_isPlaying) {
      _stopMetronome();
      _startMetronome();
    }
  }
}

class _TempoPreset extends StatelessWidget {
  final String label;
  final int bpm;
  final int currentBpm;
  final Function(int) onTap;

  const _TempoPreset(this.label, this.bpm, this.currentBpm, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = currentBpm == bpm;
    
    return GestureDetector(
      onTap: () => onTap(bpm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey,
          ),
        ),
        child: Text(
          '$label\n$bpm',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
