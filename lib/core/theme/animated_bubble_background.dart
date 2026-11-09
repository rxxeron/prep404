import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

bool get _isInTest {
  if (kIsWeb) return false;
  return Platform.environment.containsKey('FLUTTER_TEST');
}

/// Fluid ambient animated bubble background for Prep404 onboarding & auth flows
class AnimatedBubbleBackground extends StatefulWidget {
  final Widget child;
  final bool animate;

  const AnimatedBubbleBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  @override
  State<AnimatedBubbleBackground> createState() =>
      _AnimatedBubbleBackgroundState();
}

class _AnimatedBubbleBackgroundState extends State<AnimatedBubbleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animationsConfigured = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _controller.value = 0.5;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configureAnimation();
  }

  @override
  void didUpdateWidget(covariant AnimatedBubbleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _configureAnimation();
  }

  void _configureAnimation() {
    _animationsConfigured = true;
    if (!_isInTest &&
        widget.animate &&
        !MediaQuery.of(context).disableAnimations) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animationsConfigured) _configureAnimation();
    final colors = context.colors;
    final isDark = context.isDark;

    return Stack(
      children: [
        // Solid background canvas fill
        Positioned.fill(
          child: Container(color: colors.background),
        ),

        // Animated ambient floating bubbles/orbs
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value * 2 * math.pi;
                final sin1 = math.sin(t);
                final cos1 = math.cos(t);
                final sin2 = math.sin(t + 1.4);
                final cos2 = math.cos(t + 1.4);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Bubble 1: Top-Right luminous orb (Warm primary glow)
                    Positioned(
                      top: -90 + (sin1 * 18),
                      right: -70 + (cos1 * 16),
                      child: Container(
                        width: 320 + (sin1 * 24),
                        height: 320 + (sin1 * 24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colors.primary
                                  .withValues(alpha: isDark ? 0.20 : 0.12),
                              colors.primary
                                  .withValues(alpha: isDark ? 0.08 : 0.04),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Bubble 2: Bottom-Left ambient orb (Deep plum / accent purple glow)
                    Positioned(
                      bottom: -80 + (cos2 * 20),
                      left: -60 + (sin2 * 18),
                      child: Container(
                        width: 290 + (cos2 * 22),
                        height: 290 + (cos2 * 22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colors.accentPurple
                                  .withValues(alpha: isDark ? 0.16 : 0.09),
                              colors.accentPurple
                                  .withValues(alpha: isDark ? 0.06 : 0.02),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Bubble 3: Mid-floating accent orb (Warm sunshine/amber highlight)
                    Positioned(
                      top: MediaQuery.sizeOf(context).height * 0.42 +
                          (sin2 * 22),
                      right: -40 + (sin1 * 15),
                      child: Container(
                        width: 190 + (cos1 * 16),
                        height: 190 + (cos1 * 16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colors.accentSunshine
                                  .withValues(alpha: isDark ? 0.11 : 0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Bubble 4: Top-Left subtle floating bubble
                    Positioned(
                      top: 40 + (cos1 * 14),
                      left: -30 + (sin2 * 12),
                      child: Container(
                        width: 140 + (sin2 * 14),
                        height: 140 + (sin2 * 14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colors.primary
                                  .withValues(alpha: isDark ? 0.10 : 0.06),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Foreground content
        Positioned.fill(
          child: widget.child,
        ),
      ],
    );
  }
}
