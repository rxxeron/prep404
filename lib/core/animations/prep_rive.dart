import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import '../theme/app_theme.dart';

/// Centralized Prep404 Rive Animation Component (Rive 0.14+ API)
/// Supports:
/// - Native State machine transitions (Triggers, Booleans, Numbers)
/// - Pointer & gesture interactivity
/// - Interactive Onboarding mascot & exam companion
/// - Offline vector fallback when assets are loading or unavailable
class PrepRive extends StatefulWidget {
  final String? assetPath;
  final String? url;
  final String? stateMachineName;
  final String? artboardName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Function(rive.RiveWidgetController controller)? onInit;
  final Widget? fallback;

  const PrepRive({
    super.key,
    this.assetPath,
    this.url,
    this.stateMachineName,
    this.artboardName,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.onInit,
    this.fallback,
  });

  @override
  State<PrepRive> createState() => _PrepRiveState();
}

class _PrepRiveState extends State<PrepRive> {
  rive.FileLoader? _fileLoader;

  @override
  void initState() {
    super.initState();
    _initLoader();
  }

  @override
  void didUpdateWidget(PrepRive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath || oldWidget.url != widget.url) {
      _fileLoader?.dispose();
      _initLoader();
    }
  }

  void _initLoader() {
    final factory = rive.Factory.flutter;
    if (widget.assetPath != null) {
      _fileLoader = rive.FileLoader.fromAsset(
        widget.assetPath!,
        riveFactory: factory,
      );
    } else if (widget.url != null) {
      _fileLoader = rive.FileLoader.fromUrl(
        widget.url!,
        riveFactory: factory,
      );
    } else {
      _fileLoader = null;
    }
  }

  @override
  void dispose() {
    _fileLoader?.dispose();
    super.dispose();
  }

  rive.Fit _toRiveFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.fill:
        return rive.Fit.fill;
      case BoxFit.contain:
        return rive.Fit.contain;
      case BoxFit.cover:
        return rive.Fit.cover;
      case BoxFit.fitWidth:
        return rive.Fit.fitWidth;
      case BoxFit.fitHeight:
        return rive.Fit.fitHeight;
      case BoxFit.none:
        return rive.Fit.none;
      case BoxFit.scaleDown:
        return rive.Fit.scaleDown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFallback = widget.fallback ??
        _RiveDefaultFallback(
          width: widget.width,
          height: widget.height,
        );

    final loader = _fileLoader;
    if (loader == null) {
      return effectiveFallback;
    }

    final artboardSelector = widget.artboardName != null
        ? rive.ArtboardSelector.byName(widget.artboardName!)
        : const rive.ArtboardDefault();

    final smSelector = widget.stateMachineName != null
        ? rive.StateMachineSelector.byName(widget.stateMachineName!)
        : const rive.StateMachineDefault();

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: rive.RiveWidgetBuilder(
        fileLoader: loader,
        artboardSelector: artboardSelector,
        stateMachineSelector: smSelector,
        onLoaded: (state) {
          widget.onInit?.call(state.controller);
        },
        builder: (context, state) {
          return switch (state) {
            rive.RiveLoaded() => rive.RiveWidget(
                controller: state.controller,
                fit: _toRiveFit(widget.fit),
              ),
            rive.RiveLoading() => effectiveFallback,
            rive.RiveFailed() => effectiveFallback,
          };
        },
      ),
    );
  }
}

class _RiveDefaultFallback extends StatelessWidget {
  final double? width;
  final double? height;

  const _RiveDefaultFallback({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: width ?? 120,
      height: height ?? 120,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.psychology_rounded,
          color: colors.primary,
          size: (height != null) ? height! * 0.5 : 48,
        ),
      ),
    );
  }
}
