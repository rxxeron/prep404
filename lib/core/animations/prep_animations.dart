/// Prep404 Enterprise Animation Architecture Suite
/// Unified export barrel for 60fps animations, interactive illustrations,
/// physics shaders, Lottie states, and sensor-driven parallax.

library prep_animations;

// Third-Party High-Performance Frameworks
export 'package:flutter_animate/flutter_animate.dart';
export 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
export 'package:shimmer/shimmer.dart';
export 'package:animations/animations.dart';
export 'package:lottie/lottie.dart' hide Marker;
export 'package:rive/rive.dart'
    hide RiveSemanticsMixin, RiveSemanticsWidget;

// Custom Engine Layer (Shaders, Particles, Rive, Lottie, Sensors)
export 'prep_shaders.dart';
export 'prep_lottie.dart';
export 'prep_rive.dart';
export 'sensor_parallax_card.dart';
