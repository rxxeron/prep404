import 'package:flutter/material.dart';

/// High-fidelity 60fps entry animation screen for Prep404
/// Featuring the confirmed 1:1 master square brand logo and "Failure Not Found" tagline.
class Prep404EntrySplash extends StatefulWidget {
  final String statusText;
  const Prep404EntrySplash({
    super.key,
    this.statusText = 'Preparing your study space…',
  });

  @override
  State<Prep404EntrySplash> createState() => _Prep404EntrySplashState();
}

class _Prep404EntrySplashState extends State<Prep404EntrySplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF160D1A) : const Color(0xFFFFF2DF);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value * (_controller.value > 0.7 ? _glowAnimation.value : 1.0),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Container with subtle brand shadow and squircle clipping
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2DF),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1445204F),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: Offset(0, 14),
                      ),
                      BoxShadow(
                        color: Color(0x1FF28C28),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/brand/prep404_square_logo_cream.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/brand/prep404_square_logo_cream.jpg',
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 36),
                // Smooth branded progress indicator
                SizedBox(
                  width: 140,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      backgroundColor: Color(0x1A45204F),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFF28C28), // Warm Tangerine
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Subtitle
                Text(
                  widget.statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xCCFFF2DF) : const Color(0xB245204F),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
