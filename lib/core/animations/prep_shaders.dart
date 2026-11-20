import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// 1. ADVANCED AURORA FRAGMENT SHADER BACKGROUND
// ============================================================================

/// Ambient fluid Aurora Mesh Background powered by Flutter SPIR-V Fragment Shaders.
/// Renders 60fps multi-frequency wave blending with graceful CustomPainter fallback.
class AuroraShaderBackground extends StatefulWidget {
  final Widget child;
  final bool animate;

  const AuroraShaderBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  @override
  State<AuroraShaderBackground> createState() => _AuroraShaderBackgroundState();
}

class _AuroraShaderBackgroundState extends State<AuroraShaderBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    if (widget.animate && !kIsWeb) {
      _controller.repeat();
    }

    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/aurora_mesh.frag');
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
        });
      }
    } catch (e) {
      debugPrint('FragmentShader not available on this platform, using fallback: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Stack(
      children: [
        // Solid base canvas
        Positioned.fill(
          child: Container(color: colors.background),
        ),

        // 60fps Shader or Fallback Canvas
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_shader != null) {
                  return CustomPaint(
                    painter: _AuroraShaderPainter(
                      shader: _shader!,
                      time: _controller.value * 10.0,
                      primaryColor: colors.primary,
                      secondaryColor: colors.accentPurple,
                      backgroundColor: colors.background,
                    ),
                  );
                }

                // Smooth CustomPainter fallback
                return CustomPaint(
                  painter: _AuroraFallbackPainter(
                    animationValue: _controller.value,
                    primaryColor: colors.primary,
                    secondaryColor: colors.accentPurple,
                  ),
                );
              },
            ),
          ),
        ),

        // Foreground application content
        widget.child,
      ],
    );
  }
}

class _AuroraShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;

  _AuroraShaderPainter({
    required this.shader,
    required this.time,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // uniform vec2 uResolution;
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // uniform float uTime;
    shader.setFloat(2, time);

    // uniform vec4 uColorPrimary;
    shader.setFloat(3, primaryColor.r);
    shader.setFloat(4, primaryColor.g);
    shader.setFloat(5, primaryColor.b);
    shader.setFloat(6, primaryColor.a);

    // uniform vec4 uColorSecondary;
    shader.setFloat(7, secondaryColor.r);
    shader.setFloat(8, secondaryColor.g);
    shader.setFloat(9, secondaryColor.b);
    shader.setFloat(10, secondaryColor.a);

    // uniform vec4 uColorBackground;
    shader.setFloat(11, backgroundColor.r);
    shader.setFloat(12, backgroundColor.g);
    shader.setFloat(13, backgroundColor.b);
    shader.setFloat(14, backgroundColor.a);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_AuroraShaderPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.primaryColor != primaryColor;
}

class _AuroraFallbackPainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  _AuroraFallbackPainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = animationValue * 2 * math.pi;
    final p1 = Offset(
      size.width * 0.8 + math.sin(t) * 40,
      size.height * 0.15 + math.cos(t) * 30,
    );
    final p2 = Offset(
      size.width * 0.2 + math.cos(t * 0.8) * 35,
      size.height * 0.85 + math.sin(t * 0.8) * 35,
    );

    final paint1 = Paint()
      ..shader = ui.Gradient.radial(
        p1,
        size.width * 0.6,
        [
          primaryColor.withValues(alpha: 0.18),
          primaryColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );

    final paint2 = Paint()
      ..shader = ui.Gradient.radial(
        p2,
        size.width * 0.55,
        [
          secondaryColor.withValues(alpha: 0.16),
          secondaryColor.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );

    canvas.drawCircle(p1, size.width * 0.6, paint1);
    canvas.drawCircle(p2, size.width * 0.55, paint2);
  }

  @override
  bool shouldRepaint(_AuroraFallbackPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

// ============================================================================
// 2. LIQUID FLUID WAVE PROGRESS GAUGE (FRAGMENT SHADER)
// ============================================================================

/// Liquid Wave Progress Fill powered by GLSL Fragment Shader.
class LiquidFluidProgress extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final Color? liquidColor;
  final Color? foamColor;
  final Widget? centerChild;

  const LiquidFluidProgress({
    super.key,
    required this.progress,
    this.size = 140,
    this.liquidColor,
    this.foamColor,
    this.centerChild,
  });

  @override
  State<LiquidFluidProgress> createState() => _LiquidFluidProgressState();
}

class _LiquidFluidProgressState extends State<LiquidFluidProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/liquid_fluid.frag');
      if (mounted) {
        setState(() => _shader = program.fragmentShader());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primary = widget.liquidColor ?? colors.primary;
    final foam = widget.foamColor ?? Colors.white.withValues(alpha: 0.8);

    return Container(
      width: widget.size,
      height: widget.size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceElevated,
        border: Border.all(color: colors.border, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_shader != null) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _LiquidShaderPainter(
                    shader: _shader!,
                    progress: widget.progress.clamp(0.0, 1.0),
                    time: _controller.value * 4.0,
                    liquidColor: primary,
                    foamColor: foam,
                  ),
                );
              }

              // Fallback procedural fluid
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProceduralLiquidPainter(
                  progress: widget.progress.clamp(0.0, 1.0),
                  animationValue: _controller.value,
                  liquidColor: primary,
                ),
              );
            },
          ),
          if (widget.centerChild != null) widget.centerChild!,
        ],
      ),
    );
  }
}

class _LiquidShaderPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double progress;
  final double time;
  final Color liquidColor;
  final Color foamColor;

  _LiquidShaderPainter({
    required this.shader,
    required this.progress,
    required this.time,
    required this.liquidColor,
    required this.foamColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, progress);

    shader.setFloat(4, liquidColor.r);
    shader.setFloat(5, liquidColor.g);
    shader.setFloat(6, liquidColor.b);
    shader.setFloat(7, liquidColor.a);

    shader.setFloat(8, foamColor.r);
    shader.setFloat(9, foamColor.g);
    shader.setFloat(10, foamColor.b);
    shader.setFloat(11, foamColor.a);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_LiquidShaderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.time != time;
}

class _ProceduralLiquidPainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final Color liquidColor;

  _ProceduralLiquidPainter({
    required this.progress,
    required this.animationValue,
    required this.liquidColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final yBase = size.height * (1.0 - progress);

    path.moveTo(0, yBase);
    for (double x = 0; x <= size.width; x += 4) {
      final wave = math.sin((x / size.width * 2 * math.pi) +
              (animationValue * 2 * math.pi)) *
          5.0;
      path.lineTo(x, yBase + wave);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ProceduralLiquidPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.animationValue != animationValue;
}

// ============================================================================
// 3. 60FPS ADVANCED PARTICLE SYSTEM (CELEBRATION / BURST / STREAK FLAMES)
// ============================================================================

/// Particle model representing an individual kinetic particle
class PrepParticle {
  Offset position;
  Offset velocity;
  double radius;
  Color color;
  double opacity;
  double life;
  final double decayRate;

  PrepParticle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
    this.opacity = 1.0,
    this.life = 1.0,
    required this.decayRate,
  });

  bool update(double dt) {
    position += velocity * dt;
    velocity = Offset(velocity.dx * 0.98, velocity.dy + (60.0 * dt)); // Gravity + drag
    life -= decayRate * dt;
    opacity = life.clamp(0.0, 1.0);
    return life > 0;
  }
}

/// Dynamic Particle Burst Trigger for streak leveling, quiz victory, and XP sparks
class PrepParticleBurst extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final List<Color>? colors;

  const PrepParticleBurst({
    super.key,
    required this.child,
    this.particleCount = 36,
    this.colors,
  });

  static PrepParticleBurstState? of(BuildContext context) =>
      context.findAncestorStateOfType<PrepParticleBurstState>();

  @override
  State<PrepParticleBurst> createState() => PrepParticleBurstState();
}

class PrepParticleBurstState extends State<PrepParticleBurst>
    with SingleTickerProviderStateMixin {
  final List<PrepParticle> _particles = [];
  late final AnimationController _ticker;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(_onTick);
  }

  void _onTick() {
    if (_particles.isEmpty) {
      if (_ticker.isAnimating) _ticker.stop();
      return;
    }
    const dt = 0.016; // ~60fps step
    setState(() {
      _particles.removeWhere((p) => !p.update(dt));
    });
  }

  /// Trigger a kinetic burst at a given target origin
  void burst(Offset origin) {
    final palette = widget.colors ??
        const [
          Color(0xFFF28C28), // Tangerine
          Color(0xFFE8A04B), // Amber
          Color(0xFF10B981), // Emerald
          Color(0xFF8B5CF6), // Purple
          Color(0xFFFFD700), // Gold
        ];

    for (int i = 0; i < widget.particleCount; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 80.0 + _rng.nextDouble() * 180.0;
      final velocity = Offset(math.cos(angle) * speed, math.sin(angle) * speed);

      _particles.add(
        PrepParticle(
          position: origin,
          velocity: velocity,
          radius: 3.0 + _rng.nextDouble() * 4.0,
          color: palette[_rng.nextInt(palette.length)],
          decayRate: 0.8 + _rng.nextDouble() * 0.8,
        ),
      );
    }

    if (!_ticker.isAnimating) {
      _ticker.repeat(period: const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ParticleCanvasPainter(particles: _particles),
              ),
            ),
          ),
      ],
    );
  }
}

class _ParticleCanvasPainter extends CustomPainter {
  final List<PrepParticle> particles;

  _ParticleCanvasPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity);
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticleCanvasPainter oldDelegate) => true;
}
