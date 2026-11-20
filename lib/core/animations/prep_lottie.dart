import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Centralized Prep404 Lottie Animation Helper
/// Provides standard loaders, celebration pops, error shakes, and streak animations
/// with automatic shimmer & vector fallbacks when offline or loading.
class PrepLottie extends StatelessWidget {
  final String? assetPath;
  final String? url;
  final double size;
  final bool loop;
  final bool autoPlay;
  final VoidCallback? onLoaded;
  final Widget? fallback;

  const PrepLottie({
    super.key,
    this.assetPath,
    this.url,
    this.size = 120,
    this.loop = true,
    this.autoPlay = true,
    this.onLoaded,
    this.fallback,
  });

  /// Standard Branded Study Space Loader
  factory PrepLottie.loading({
    Key? key,
    double size = 80,
    String? message,
  }) {
    return PrepLottie(
      key: key,
      size: size,
      loop: true,
      assetPath: 'assets/animations/loading.json',
      fallback: _LoadingFallback(size: size, message: message),
    );
  }

  /// Celebratory Success / Victory Pop (Exam completion, quiz win)
  factory PrepLottie.success({
    Key? key,
    double size = 140,
    bool loop = false,
  }) {
    return PrepLottie(
      key: key,
      size: size,
      loop: loop,
      assetPath: 'assets/animations/success.json',
      fallback: _SuccessFallback(size: size),
    );
  }

  /// Alert / Error Wobble
  factory PrepLottie.error({
    Key? key,
    double size = 100,
    bool loop = false,
  }) {
    return PrepLottie(
      key: key,
      size: size,
      loop: loop,
      assetPath: 'assets/animations/error.json',
      fallback: _ErrorFallback(size: size),
    );
  }

  /// Animated Streak Flame
  factory PrepLottie.streak({
    Key? key,
    double size = 90,
  }) {
    return PrepLottie(
      key: key,
      size: size,
      loop: true,
      assetPath: 'assets/animations/streak_fire.json',
      fallback: _StreakFallback(size: size),
    );
  }

  /// Gentle Animated Empty State Illustration
  factory PrepLottie.emptyState({
    Key? key,
    double size = 88,
  }) {
    return PrepLottie(
      key: key,
      size: size,
      loop: true,
      assetPath: 'assets/animations/empty_state.json',
      fallback: _LoadingFallback(size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAnimate = autoPlay && !reduceMotion;
    if (assetPath != null) {
      return Lottie.asset(
        assetPath!,
        width: size,
        height: size,
        repeat: loop && !reduceMotion,
        animate: shouldAnimate,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return fallback ?? _LoadingFallback(size: size);
        },
      );
    }

    if (url != null) {
      return Lottie.network(
        url!,
        width: size,
        height: size,
        repeat: loop,
        animate: autoPlay,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return fallback ?? _LoadingFallback(size: size);
        },
      );
    }

    return fallback ?? _LoadingFallback(size: size);
  }
}

class _LoadingFallback extends StatelessWidget {
  final double size;
  final String? message;

  const _LoadingFallback({required this.size, this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Shimmer.fromColors(
          baseColor: colors.primary.withValues(alpha: 0.3),
          highlightColor: colors.primaryLight,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: size * 0.45,
                height: size * 0.45,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(
            message!,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _SuccessFallback extends StatelessWidget {
  final double size;

  const _SuccessFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.accentEmerald.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: colors.accentEmerald, width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.check_circle_rounded,
          color: colors.accentEmerald,
          size: size * 0.55,
        ),
      ),
    );
  }
}

class _ErrorFallback extends StatelessWidget {
  final double size;

  const _ErrorFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.dangerRed.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: colors.dangerRed, width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.error_outline_rounded,
          color: colors.dangerRed,
          size: size * 0.55,
        ),
      ),
    );
  }
}

class _StreakFallback extends StatelessWidget {
  final double size;

  const _StreakFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0x1AF28C28),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.local_fire_department_rounded,
          color: const Color(0xFFF28C28),
          size: size * 0.6,
        ),
      ),
    );
  }
}
