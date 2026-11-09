import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/prep404_logo.dart';

/// Screen presenting the Prep404 platform mission, features, and release information
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Widget _buildFeatureItem({
    required AppColors colors,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About Us',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: const [
          ThemeToggleIconButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Branding Header
            Center(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Prep404Logo(height: 52),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Text(
                      'Version 1.0.0 • 2026 Edition',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Mission Statement Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
                boxShadow: colors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prep404 is engineered specifically for students targeting premier private universities in Bangladesh — including BRAC, NSU, AIUB, EWU, UIU, IUB, and AUST.\n\nOur mission is to eliminate admission exam uncertainty by providing authentic past question blueprints, adaptive AI tutoring, and rigorous analytics to maximize test-day confidence.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Core Pillars Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
                boxShadow: colors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Core Innovations',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem(
                    colors: colors,
                    icon: Icons.menu_book_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: 'Authentic Exam Blueprints',
                    description:
                        'Detailed questions and time constraints tailored to each department and faculty test.',
                  ),
                  _buildFeatureItem(
                    colors: colors,
                    icon: Icons.functions_rounded,
                    iconColor: const Color(0xFF059669),
                    title: 'KaTeX STEM Solutions',
                    description:
                        'Step-by-step mathematical, physical, and chemical proofs formatted with native LaTeX quality.',
                  ),
                  _buildFeatureItem(
                    colors: colors,
                    icon: Icons.psychology_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'FSRS-5 Spaced Repetition',
                    description:
                        'Modern spaced repetition algorithms to guarantee long-term retention of critical formulas.',
                  ),
                  _buildFeatureItem(
                    colors: colors,
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFFEA580C),
                    title: '100% Pure English Environment',
                    description:
                        'Clean, distraction-free interface matching international standardized testing benchmarks.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Legal & Contact Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'support@prep404.com',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Prep404 © 2026. All rights reserved.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
