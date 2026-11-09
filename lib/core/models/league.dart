import 'package:flutter/material.dart';

/// The 7 Greek Gamification Tiers discovered from Chorcha, enhanced with rank multipliers.
enum LeagueTier {
  alpha(
    name: 'ALPHA',
    minXp: 1,
    maxXp: 1000,
    primaryColor: Color(0xFF6B7280),
    description: 'The foundation of your educational journey.',
    iconAsset: 'assets/leagues/alpha.svg',
  ),
  beta(
    name: 'BETA',
    minXp: 1001,
    maxXp: 2000,
    primaryColor: Color(0xFF10B981),
    description: 'Stepping into consistent competitive practice.',
    iconAsset: 'assets/leagues/beta.svg',
  ),
  gamma(
    name: 'GAMMA',
    minXp: 2001,
    maxXp: 3000,
    primaryColor: Color(0xFF3B82F6),
    description: 'Advanced learner circle with proven accuracy.',
    iconAsset: 'assets/leagues/gamma.svg',
  ),
  theta(
    name: 'THETA',
    minXp: 3001,
    maxXp: 4000,
    primaryColor: Color(0xFF8B5CF6),
    description: 'Deep knowledge and national leaderboard contender.',
    iconAsset: 'assets/leagues/theta.svg',
  ),
  lambda(
    name: 'LAMBDA',
    minXp: 4001,
    maxXp: 5000,
    primaryColor: Color(0xFFEC4899),
    description: 'High tenacity, mastering both speed and analytical depth.',
    iconAsset: 'assets/leagues/lambda.svg',
  ),
  sigma(
    name: 'SIGMA',
    minXp: 5001,
    maxXp: 8000,
    primaryColor: Color(0xFFF59E0B),
    description: 'Elite candidates in the top percentile of active users.',
    iconAsset: 'assets/leagues/sigma.svg',
  ),
  omega(
    name: 'OMEGA',
    minXp: 8001,
    maxXp: 13000,
    primaryColor: Color(0xFFEF4444),
    description: 'The Pinnacle Tier. Exemplar of academic excellence.',
    iconAsset: 'assets/leagues/omega.svg',
  );

  final String name;
  final int minXp;
  final int maxXp;
  final Color primaryColor;
  final String description;
  final String iconAsset;

  const LeagueTier({
    required this.name,
    required this.minXp,
    required this.maxXp,
    required this.primaryColor,
    required this.description,
    required this.iconAsset,
  });

  static LeagueTier fromXp(int xp) {
    for (final tier in LeagueTier.values.reversed) {
      if (xp >= tier.minXp) return tier;
    }
    return LeagueTier.alpha;
  }
}
