import 'package:flutter/material.dart';

/// Prep404 Official Brand Colors & Design System Palette
/// Based on the Prep404 Mascot & Visual Identity System
class Prep404Colors {
  Prep404Colors._();

  // Core Brand Tokens
  static const Color warmTangerine = Color(0xFFF28C28); // Primary Brand / 404 / CTA
  static const Color deepPlum = Color(0xFF45204F);      // Secondary / Mascot / Prep Wordmark / Headers
  static const Color softCream = Color(0xFFFFF2DF);     // Canvas / Light Surface / Paper Feel
  static const Color goldenOrange = Color(0xFFE8A04B);  // Accent / Trophies / Gold Rating
  static const Color softPeach = Color(0xFFF7D9B5);     // Secondary Surface / Badge Fill / Chip Borders

  // Dark Mode Tokens
  static const Color darkPlumBg = Color(0xFF160D1A);
  static const Color darkSurface = Color(0xFF24142B);
  static const Color darkElevated = Color(0xFF361C40);
  static const Color darkBorder = Color(0xFF45204F);
  static const Color darkTextPrimary = Color(0xFFFFF2DF);

  // Semantic Status Tokens
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Brand Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFF28C28),
      Color(0xFFEA580C),
    ],
  );

  static const LinearGradient heroCreamGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF9F0),
      Color(0xFFFFF2DF),
    ],
  );

  static const LinearGradient battleArenaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2D1435),
      Color(0xFF45204F),
      Color(0xFF160D1A),
    ],
  );
}
