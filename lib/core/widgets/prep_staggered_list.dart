import 'dart:async';
import 'package:flutter/material.dart';

/// Staggered entry animation wrapper for list items.
///
/// Implements the 70 ms staggered cascade entrance rule:
/// Each consecutive item slides up and fades in 70 ms after the previous one,
/// transforming raw static list pops into polished, fluid presentations.
class PrepStaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration staggerDelay;
  final Duration maxDelay;
  final Duration duration;
  final double slideOffset;
  final Curve curve;

  const PrepStaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.staggerDelay = const Duration(milliseconds: 70),
    this.maxDelay = const Duration(milliseconds: 560),
    this.duration = const Duration(milliseconds: 360),
    this.slideOffset = 22.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<PrepStaggeredItem> createState() => _PrepStaggeredItemState();
}

class _PrepStaggeredItemState extends State<PrepStaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    final totalDelayMs = widget.index * widget.staggerDelay.inMilliseconds;
    final cappedDelayMs = totalDelayMs > widget.maxDelay.inMilliseconds
        ? widget.maxDelay.inMilliseconds
        : totalDelayMs;

    if (cappedDelayMs == 0) {
      _controller.forward();
    } else {
      _delayTimer = Timer(Duration(milliseconds: cappedDelayMs), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Convenience column that automatically wraps each child in a [PrepStaggeredItem]
/// staggered by 70 ms.
class PrepStaggeredColumn extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration maxDelay;
  final Duration duration;
  final double slideOffset;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  const PrepStaggeredColumn({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 70),
    this.maxDelay = const Duration(milliseconds: 560),
    this.duration = const Duration(milliseconds: 360),
    this.slideOffset = 22.0,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++)
          PrepStaggeredItem(
            index: i,
            staggerDelay: staggerDelay,
            maxDelay: maxDelay,
            duration: duration,
            slideOffset: slideOffset,
            child: children[i],
          ),
      ],
    );
  }
}
