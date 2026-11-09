import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/university_target.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/onboarding_controller.dart';

/// Step 1: Adaptable Medium & Curriculum Selection with Bangla/English Version
class MediumSelectorStep extends StatelessWidget {
  final OnboardingController controller;
  final AppLanguage language;

  const MediumSelectorStep({
    super.key,
    required this.controller,
    this.language = AppLanguage.english,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = AppStrings(language);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    strings.chooseMediumTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.chooseMediumSubtitle,
                    style: TextStyle(fontSize: 14, color: colors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Bangla Medium Card (NCTB)
                  _buildMediumCard(
                    context: context,
                    colors: colors,
                    medium: StudentMedium.bangla,
                    title: strings.banglaMediumTitle,
                    subtitle: strings.banglaMediumSubtitle,
                    badge: 'NCTB',
                    icon: Icons.menu_book_rounded,
                    isSelected: controller.medium == StudentMedium.bangla,
                    onTap: () => controller.setMedium(StudentMedium.bangla),
                  ),

                  // Bangla Medium Sub-selection: Bangla Version vs English Version
                  if (controller.medium == StudentMedium.bangla) ...[
                    const SizedBox(height: 14),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
                        boxShadow: colors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.translate_rounded, color: colors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                strings.nctbVersionTitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildVersionChip(
                                  colors: colors,
                                  version: NctbVersion.bangla,
                                  title: 'Bangla Version',
                                  subtitle: 'Bengali Textbooks',
                                  badge: 'Bangla',
                                  isSelected: controller.nctbVersion == NctbVersion.bangla,
                                  onTap: () => controller.setNctbVersion(NctbVersion.bangla),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildVersionChip(
                                  colors: colors,
                                  version: NctbVersion.english,
                                  title: 'English Version',
                                  subtitle: 'English Textbooks',
                                  badge: 'English',
                                  isSelected: controller.nctbVersion == NctbVersion.english,
                                  onTap: () => controller.setNctbVersion(NctbVersion.english),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // English Medium Card (GCE O/A Level)
                  _buildMediumCard(
                    context: context,
                    colors: colors,
                    medium: StudentMedium.english,
                    title: strings.englishMediumTitle,
                    subtitle: strings.englishMediumSubtitle,
                    badge: 'GCE',
                    icon: Icons.language_rounded,
                    isSelected: controller.medium == StudentMedium.english,
                    onTap: () => controller.setMedium(StudentMedium.english),
                  ),

                  // English Medium Sub-selection (Edexcel vs Cambridge)
                  if (controller.medium == StudentMedium.english) ...[
                    const SizedBox(height: 14),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
                        boxShadow: colors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school_rounded, color: colors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Curriculum Examination Board',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCurriculumChip(
                                  colors: colors,
                                  curriculum: EnglishCurriculum.cambridge,
                                  label: 'Cambridge (CAIE)',
                                  subtitle: 'GCE O / A Level',
                                  isSelected: controller.curriculum == EnglishCurriculum.cambridge,
                                  onTap: () => controller.setEnglishCurriculum(EnglishCurriculum.cambridge),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCurriculumChip(
                                  colors: colors,
                                  curriculum: EnglishCurriculum.edexcel,
                                  label: 'Pearson Edexcel',
                                  subtitle: 'GCSE / IAL',
                                  isSelected: controller.curriculum == EnglishCurriculum.edexcel,
                                  onTap: () => controller.setEnglishCurriculum(EnglishCurriculum.edexcel),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Adaptable Guidance Card (Fills space naturally with high educational context)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primaryLight.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, color: colors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.curriculumAlignmentTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.medium == StudentMedium.bangla
                                    ? (controller.nctbVersion == NctbVersion.bangla
                                        ? strings.curriculumAlignmentBanglaDesc
                                        : strings.curriculumAlignmentEnglishVersionDesc)
                                    : strings.curriculumAlignmentGceDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediumCard({
    required BuildContext context,
    required AppColors colors,
    required StudentMedium medium,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryLight : colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: colors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : colors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.primary : colors.border,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : colors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? colors.primary : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: isSelected ? colors.primary : colors.border,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionChip({
    required AppColors colors,
    required NctbVersion version,
    required String title,
    required String subtitle,
    required String badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? colors.cardShadow : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white.withValues(alpha: 0.85) : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurriculumChip({
    required AppColors colors,
    required EnglishCurriculum curriculum,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? colors.cardShadow : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white.withValues(alpha: 0.85) : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
