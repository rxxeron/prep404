import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 3D Parallax Tilt Card driven by physical phone orientation (sensors_plus)
/// Provides immersive physical depth to hero cards, candidate badges, and mascot widgets.
class SensorParallaxCard extends StatefulWidget {
  final Widget child;
  final double maxTiltAngle; // In radians (default ~10 degrees)
  final double depthTranslation; // Depth translation along Z axis
  final bool enabled;

  const SensorParallaxCard({
    super.key,
    required this.child,
    this.maxTiltAngle = 0.18,
    this.depthTranslation = 8.0,
    this.enabled = true,
  });

  @override
  State<SensorParallaxCard> createState() => _SensorParallaxCardState();
}

class _SensorParallaxCardState extends State<SensorParallaxCard> {
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  double _pitch = 0.0; // Rotation around X-axis
  double _roll = 0.0;  // Rotation around Y-axis

  @override
  void initState() {
    super.initState();
    if (widget.enabled && !kIsWeb) {
      _initSensor();
    }
  }

  void _initSensor() {
    try {
      _sensorSubscription =
          accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
              .listen(
        (event) {
          if (!mounted) return;
          // Normalized phone tilt values (gravity is ~9.8 on Z when flat)
          final targetPitch = (-event.y / 9.8).clamp(-1.0, 1.0) * widget.maxTiltAngle;
          final targetRoll = (event.x / 9.8).clamp(-1.0, 1.0) * widget.maxTiltAngle;

          // Low-pass filter for smooth motion dampening
          setState(() {
            _pitch = _pitch * 0.8 + targetPitch * 0.2;
            _roll = _roll * 0.8 + targetRoll * 0.2;
          });
        },
        onError: (_) {
          // Gracefully ignore if hardware sensor is absent
        },
        cancelOnError: true,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || (_pitch == 0.0 && _roll == 0.0)) {
      return widget.child;
    }

    // Perspective transformation matrix with 3D eye focal length
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // 3D Perspective focal depth
      ..rotateX(_pitch)
      ..rotateY(_roll);

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: widget.child,
    );
  }
}
