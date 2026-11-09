import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Damped harmonic spring curve for natural error recoil.
class DampedSineCurve extends Curve {
  final double count;

  const DampedSineCurve({this.count = 3.0});

  @override
  double transformInternal(double t) {
    // Dampened sinusoidal decay: amplitude decays smoothly to 0 at t=1.0
    return math.sin(t * count * 2 * math.pi) * math.pow(1.0 - t, 1.6);
  }
}

/// Tactile error shake wrapper implementing damped horizontal recoil.
///
/// Designed for invalid PIN/OTP entries, incorrect passwords, or rejected actions.
/// Can be triggered:
/// 1. Imperatively via `GlobalKey<PrepShakeErrorState>` -> `key.currentState?.shake()`
/// 2. Reactively via [shakeTrigger] integer increment.
class PrepShakeError extends StatefulWidget {
  final Widget child;
  final double maxOffset;
  final Duration duration;
  final bool enableHaptic;
  final int shakeTrigger;
  final VoidCallback? onAnimationComplete;

  const PrepShakeError({
    super.key,
    required this.child,
    this.maxOffset = 10.0,
    this.duration = const Duration(milliseconds: 420),
    this.enableHaptic = true,
    this.shakeTrigger = 0,
    this.onAnimationComplete,
  });

  @override
  State<PrepShakeError> createState() => PrepShakeErrorState();
}

class PrepShakeErrorState extends State<PrepShakeError>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const DampedSineCurve(count: 3.5),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(PrepShakeError oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTrigger > oldWidget.shakeTrigger) {
      shake();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Triggers the damped horizontal recoil animation.
  void shake() {
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (widget.enableHaptic) {
      HapticFeedback.mediumImpact();
    }

    if (disableAnimations) {
      widget.onAnimationComplete?.call();
      return;
    }

    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final double currentOffset = _shakeAnimation.value * widget.maxOffset;
        return Transform.translate(
          offset: Offset(currentOffset, 0.0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
