import 'package:flutter/material.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/animated_bubble_background.dart';
import '../../../../core/widgets/app_language_menu_button.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/medium_selector_step.dart';
import '../widgets/academic_info_step.dart';
import '../widgets/university_selection_step.dart';

/// Master Onboarding Screen with Stepper
class OnboardingFlowScreen extends StatefulWidget {
  final ValueChanged<UserProfile> onCompleted;
  final VoidCallback? onSignOut;
  final String initialName;
  final String initialPhone;
  final UserProfile? initialProfile;
  final int initialStep;
  final bool isEditing;
  final AppLanguage language;
  final ValueChanged<AppLanguage>? onLanguageChanged;

  const OnboardingFlowScreen({
    super.key,
    required this.onCompleted,
    this.onSignOut,
    this.initialName = '',
    this.initialPhone = '',
    this.initialProfile,
    this.initialStep = 0,
    this.isEditing = false,
    this.language = AppLanguage.english,
    this.onLanguageChanged,
  });

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  late final OnboardingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController(
      initialName: widget.initialName,
      initialPhone: widget.initialPhone,
      initialProfile: widget.initialProfile,
      initialStep: widget.initialStep,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(widget.language);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        centerTitle: false,
        leading: widget.isEditing
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A36), Color(0xFF542747)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '404',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.isEditing
                  ? strings.editAdmissionProfile
                  : strings.onboardingTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          const ThemeToggleIconButton(),
          if (widget.onLanguageChanged != null)
            AppLanguageMenuButton(
              language: widget.language,
              onChanged: widget.onLanguageChanged!,
            ),
          if (widget.onSignOut != null && !widget.isEditing)
            IconButton(
              icon: Icon(Icons.logout_rounded,
                  color: colors.textSecondary, size: 20),
              tooltip: 'Sign Out / Back to Login',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text(
                        'Do you want to return to the login screen?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  widget.onSignOut!();
                }
              },
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return LinearProgressIndicator(
                value: (_controller.currentStep + 1) / 3.0,
                backgroundColor: colors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                minHeight: 3,
              );
            },
          ),
        ),
      ),
      body: AnimatedBubbleBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    children: [
                      // Step Indicator Badges
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            _buildStepPill(
                                stepIndex: 0,
                                title: strings.step1Title,
                                colors: colors),
                            _buildStepDivider(colors),
                            _buildStepPill(
                                stepIndex: 1,
                                title: strings.step2Title,
                                colors: colors),
                            _buildStepDivider(colors),
                            _buildStepPill(
                                stepIndex: 2,
                                title: strings.step3Title,
                                colors: colors),
                          ],
                        ),
                      ),

                      // Main Step Body
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          child: IndexedStack(
                            index: _controller.currentStep,
                            children: [
                              MediumSelectorStep(
                                controller: _controller,
                                language: widget.language,
                              ),
                              AcademicInfoStep(
                                controller: _controller,
                                language: widget.language,
                              ),
                              UniversitySelectionStep(
                                controller: _controller,
                                language: widget.language,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Action Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border(
                            top: BorderSide(
                              color: colors.border,
                            ),
                          ),
                          boxShadow: colors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            if (_controller.currentStep > 0)
                              OutlinedButton(
                                onPressed: _controller.prevStep,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.textSecondary,
                                  side: BorderSide(color: colors.border),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(strings.prevBtn),
                              ),
                            if (_controller.currentStep > 0)
                              const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _onNextOrComplete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                  shadowColor:
                                      colors.primary.withValues(alpha: 0.35),
                                ),
                                child: _controller.isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : Text(
                                        _controller.currentStep == 2
                                            ? (widget.isEditing
                                                ? 'Save Changes'
                                                : strings.startPrepBtn)
                                            : strings.nextBtn,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onNextOrComplete() async {
    final strings = AppStrings(widget.language);
    if (_controller.currentStep == 0) {
      _controller.nextStep();
    } else if (_controller.currentStep == 1) {
      if (!_controller.canProceedToStep2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.missingAcademicInfoMsg),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        return;
      }
      _controller.nextStep();
    } else {
      if (!_controller.canComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.missingTargetUniMsg),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        return;
      }
      final profile = await _controller.completeOnboarding();
      if (profile != null && mounted) {
        widget.onCompleted(profile);
        if (widget.isEditing && Navigator.canPop(context)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Admission profile & targets updated successfully!'),
              backgroundColor: Color(0xFF059669),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, profile);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Your profile could not be saved. Check your connection and try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildStepPill(
      {required int stepIndex,
      required String title,
      required AppColors colors}) {
    final isActive = _controller.currentStep == stepIndex;
    final isDone = _controller.currentStep > stepIndex;

    return InkWell(
      onTap: () => _controller.jumpToStep(stepIndex),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? colors.primaryLight
              : (isDone
                  ? colors.accentEmerald.withValues(alpha: 0.15)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: colors.primary)
              : (isDone
                  ? Border.all(
                      color: colors.accentEmerald.withValues(alpha: 0.4))
                  : null),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDone) ...[
              Icon(Icons.check, size: 12, color: colors.accentEmerald),
              const SizedBox(width: 4),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? colors.primary
                    : (isDone ? colors.accentEmerald : colors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDivider(AppColors colors) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Divider(color: colors.border, thickness: 1.5),
      ),
    );
  }
}
