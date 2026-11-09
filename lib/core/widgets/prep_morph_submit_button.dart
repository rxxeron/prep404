import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Operational states for [PrepMorphSubmitButton].
enum PrepButtonState {
  /// Standard resting state: full-width pill displaying text and optional icon.
  idle,

  /// In-progress state: smoothly collapses to a circular spinner (260px -> 52px).
  loading,

  /// Completion state: morphs to a success pill/circle with an animated checkmark.
  success,

  /// Error state: displays a failure indicator with tactile recoil.
  error,
}

/// A tactile morphing submit button adhering to motion design standards.
///
/// Transitions through a single continuous shape:
/// `Pill (Full Width)` -> `Circular Spinner (52px)` -> `Checkmark Tick (52px)`
///
/// Features:
/// - Smooth width & border-radius interpolation using cubic curves.
/// - Adaptive color wash (Tangerine -> Emerald on success / Crimson on error).
/// - Automatic haptic feedback on state changes (light on press, medium on success).
/// - Respects platform accessibility `disableAnimations` / Reduce Motion settings.
class PrepMorphSubmitButton extends StatefulWidget {
  final PrepButtonState state;
  final VoidCallback? onPressed;
  final String text;
  final Widget? icon;
  final double height;
  final double? width;
  final double? collapsedWidth;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? loadingColor;
  final Color? successColor;
  final Color? errorColor;
  final Widget? successIcon;
  final Widget? errorIcon;
  final TextStyle? textStyle;
  final Duration duration;
  final VoidCallback? onSuccessFinished;
  final Duration successDuration;

  const PrepMorphSubmitButton({
    super.key,
    required this.state,
    required this.onPressed,
    required this.text,
    this.icon,
    this.height = 52.0,
    this.width,
    this.collapsedWidth,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.loadingColor,
    this.successColor = const Color(0xFF10B981), // Emerald Success
    this.errorColor = const Color(0xFFEF4444), // Crimson Error
    this.successIcon,
    this.errorIcon,
    this.textStyle,
    this.duration = const Duration(milliseconds: 320),
    this.onSuccessFinished,
    this.successDuration = const Duration(milliseconds: 900),
  });

  @override
  State<PrepMorphSubmitButton> createState() => _PrepMorphSubmitButtonState();
}

class _PrepMorphSubmitButtonState extends State<PrepMorphSubmitButton> {
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    if (widget.state == PrepButtonState.success && widget.onSuccessFinished != null) {
      _scheduleSuccessCallback();
    }
  }

  void _scheduleSuccessCallback() {
    _successTimer?.cancel();
    _successTimer = Timer(widget.successDuration, () {
      if (mounted) {
        widget.onSuccessFinished?.call();
      }
    });
  }

  @override
  void didUpdateWidget(PrepMorphSubmitButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      if (widget.state == PrepButtonState.success) {
        HapticFeedback.mediumImpact();
        if (widget.onSuccessFinished != null) {
          _scheduleSuccessCallback();
        }
      } else if (widget.state == PrepButtonState.error) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (widget.state != PrepButtonState.idle || widget.onPressed == null) return;
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveDuration = disableAnimations ? Duration.zero : widget.duration;

    final double effectiveHeight = widget.height;
    final double effectiveCollapsedWidth =
        widget.collapsedWidth ?? effectiveHeight;

    final bool isCollapsed = widget.state != PrepButtonState.idle;

    // Resolve color based on state
    Color targetBgColor;
    Color targetFgColor;

    switch (widget.state) {
      case PrepButtonState.idle:
        targetBgColor = widget.backgroundColor ?? colorScheme.primary;
        targetFgColor = widget.foregroundColor ?? colorScheme.onPrimary;
        break;
      case PrepButtonState.loading:
        targetBgColor = widget.backgroundColor ?? colorScheme.primary;
        targetFgColor = widget.loadingColor ?? widget.foregroundColor ?? colorScheme.onPrimary;
        break;
      case PrepButtonState.success:
        targetBgColor = widget.successColor ?? const Color(0xFF10B981);
        targetFgColor = Colors.white;
        break;
      case PrepButtonState.error:
        targetBgColor = widget.errorColor ?? const Color(0xFFEF4444);
        targetFgColor = Colors.white;
        break;
    }

    final effectiveRadius = widget.borderRadius ??
        BorderRadius.circular(isCollapsed ? effectiveHeight / 2 : 16);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double baseWidth = widget.width ?? (maxWidth.isFinite ? maxWidth : 260.0);
        final double targetWidth = isCollapsed ? effectiveCollapsedWidth : baseWidth;

        return Center(
          child: AnimatedContainer(
            duration: effectiveDuration,
            curve: Curves.easeInOutCubic,
            width: targetWidth,
            height: effectiveHeight,
            decoration: BoxDecoration(
              color: targetBgColor,
              borderRadius: effectiveRadius,
              boxShadow: isCollapsed
                  ? [
                      BoxShadow(
                        color: targetBgColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: targetBgColor.withValues(alpha: 0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.state == PrepButtonState.idle && widget.onPressed != null
                    ? _handleTap
                    : null,
                borderRadius: effectiveRadius as BorderRadius?,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: effectiveDuration,
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: _buildChildForState(targetFgColor),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChildForState(Color fgColor) {
    switch (widget.state) {
      case PrepButtonState.idle:
        return KeyedSubtree(
          key: const ValueKey('prep_button_idle'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: widget.textStyle ??
                    TextStyle(
                      color: fgColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );

      case PrepButtonState.loading:
        return KeyedSubtree(
          key: const ValueKey('prep_button_loading'),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
        );

      case PrepButtonState.success:
        return KeyedSubtree(
          key: const ValueKey('prep_button_success'),
          child: widget.successIcon ??
              const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 28,
              ),
        );

      case PrepButtonState.error:
        return KeyedSubtree(
          key: const ValueKey('prep_button_error'),
          child: widget.errorIcon ??
              const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 26,
              ),
        );
    }
  }
}
