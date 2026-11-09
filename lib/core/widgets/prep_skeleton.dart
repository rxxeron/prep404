import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A low-distraction loading placeholder that follows the active Prep404 theme.
class PrepSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const PrepSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  State<PrepSkeleton> createState() => _PrepSkeletonState();
}

class _PrepSkeletonState extends State<PrepSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
      value: 0.5,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion == reduceMotion &&
        _controller.isAnimating == !reduceMotion) {
      return;
    }
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _reduceMotion ? 0.72 : 0.48 + (_controller.value * 0.32),
        child: child,
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xFF374151)
              : const Color(0xFFFFF3E6),
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: colors.borderSubtle),
        ),
      ),
    );
  }
}

/// Page-sized skeleton for screens showing a title and repeated content cards.
class PrepPageSkeleton extends StatelessWidget {
  final int cardCount;
  const PrepPageSkeleton({super.key, this.cardCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PrepSkeleton(width: 190, height: 24, radius: 8),
        const SizedBox(height: 12),
        const PrepSkeleton(width: 260, height: 14, radius: 7),
        const SizedBox(height: 24),
        for (var i = 0; i < cardCount; i++) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.colors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PrepSkeleton(width: 150, height: 17, radius: 7),
                SizedBox(height: 12),
                PrepSkeleton(height: 12, radius: 6),
                SizedBox(height: 8),
                PrepSkeleton(width: 220, height: 12, radius: 6),
                SizedBox(height: 18),
                PrepSkeleton(height: 42, radius: 12),
              ],
            ),
          ),
          if (i < cardCount - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// Compact placeholders for rows and chips while a section refreshes.
class PrepInlineSkeleton extends StatelessWidget {
  final int count;
  const PrepInlineSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          const Row(
            children: [
              PrepSkeleton(width: 42, height: 42, radius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PrepSkeleton(width: 150, height: 14, radius: 7),
                    SizedBox(height: 8),
                    PrepSkeleton(height: 11, radius: 6),
                  ],
                ),
              ),
            ],
          ),
          if (i < count - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}
