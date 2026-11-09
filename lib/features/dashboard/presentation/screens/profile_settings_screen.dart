import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/routing/app_router.dart';
import 'learner_support_screen.dart';
import 'account_info_screen.dart';
import 'community_links_screen.dart';
import 'notification_settings_screen.dart';
import 'about_us_screen.dart';
import 'reported_questions_screen.dart';
import 'subscription_screen.dart';
import 'upgrade_screen.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/university_target.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/app_language_menu_button.dart';
import '../../../onboarding/presentation/screens/onboarding_flow_screen.dart';
import '../widgets/profile_menu_components.dart';
import '../widgets/profile_dialogs.dart';

/// Full Chorcha-style User Profile & Account Settings Screen with Editable Admission Setup
class ProfileSettingsScreen extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile>? onProfileUpdated;
  final VoidCallback onLogOut;
  final Future<void> Function(String reason)? onDeleteAccount;
  final bool? isEnglish;
  final ValueChanged<AppLanguage>? onLanguageChanged;

  const ProfileSettingsScreen({
    super.key,
    required this.profile,
    this.onProfileUpdated,
    required this.onLogOut,
    this.onDeleteAccount,
    this.isEnglish,
    this.onLanguageChanged,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late UserProfile _currentProfile;
  bool _practiceRemindersEnabled = false;
  bool _analyticsConsentEnabled = true;
  bool _analyticsConsentLoading = false;
  bool _analyticsConsentAvailable = true;
  bool _analyticsConsentSaving = false;

  StateSetter? _analyticsSheetSetter;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    _practiceRemindersEnabled =
        CacheService().read<bool>('practice_reminders_enabled') ?? false;
    // Analytics is on by default unless explicitly disabled
    final cachedConsent = CacheService().read<bool>('analytics_consent_enabled');
    _analyticsConsentEnabled = cachedConsent ?? true;
    _loadAnalyticsConsent();
  }

  Future<void> _loadAnalyticsConsent() async {
    final enabled = await ApiClient().fetchAnalyticsConsent();
    if (!mounted) return;
    setState(() {
      _analyticsConsentEnabled = enabled ?? true;
      _analyticsConsentAvailable = true;
      _analyticsConsentLoading = false;
    });
    _analyticsSheetSetter?.call(() {});
    if (enabled != null) {
      CacheService().write('analytics_consent_enabled', enabled);
    }
  }

  Future<void> _setAnalyticsConsent(bool enabled, StateSetter setSheetState,
      BuildContext sheetContext) async {
    setState(() => _analyticsConsentSaving = true);
    if (sheetContext.mounted) setSheetState(() {});
    try {
      await ApiClient().updateAnalyticsConsent(enabled);
      CacheService().write('analytics_consent_enabled', enabled);
      if (!mounted) return;
      setState(() {
        _analyticsConsentEnabled = enabled;
        _analyticsConsentSaving = false;
      });
      if (sheetContext.mounted) setSheetState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(() => _analyticsConsentSaving = false);
      if (sheetContext.mounted) setSheetState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    }
  }

  void _openAnalyticsPrivacySettings(AppColors colors) {
    final strings = AppStrings.of(context);
    _loadAnalyticsConsent();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          _analyticsSheetSetter = setSheetState;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.learningAnalytics,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(strings.analyticsConsentDescription,
                    style: TextStyle(color: colors.textSecondary)),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.shareActivityAnalytics,
                      style: TextStyle(color: colors.textPrimary)),
                  subtitle: Text(
                      _analyticsConsentLoading
                          ? strings.loadingPreference
                          : !_analyticsConsentAvailable
                              ? strings.preferenceUnavailable
                              : _analyticsConsentEnabled
                                  ? strings.analyticsOn
                                  : strings.analyticsOff,
                      style: TextStyle(color: colors.textSecondary)),
                  value: _analyticsConsentEnabled,
                  activeTrackColor: colors.primary,
                  onChanged: _analyticsConsentLoading ||
                          !_analyticsConsentAvailable ||
                          _analyticsConsentSaving
                      ? null
                      : (enabled) => _setAnalyticsConsent(
                          enabled, setSheetState, sheetContext),
                ),
                if (_analyticsConsentSaving) const LinearProgressIndicator(),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      _analyticsSheetSetter = null;
    });
  }

  void _openNotificationsSettings(AppColors colors) async {
    if (GoRouter.maybeOf(context) != null) {
      await context.push<void>(AppRoutes.notificationSettings);
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
      );
    }
    if (mounted) {
      setState(() {
        _practiceRemindersEnabled =
            CacheService().read<bool>('practice_reminders_enabled') ?? true;
      });
    }
  }

  void _showOptionDetails(String title, AppColors colors, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(title, style: TextStyle(color: colors.textPrimary)),
        content: Text(message, style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkSocialAccount(OAuthProvider provider, String label) async {
    final service = SupabaseService();
    if (!service.isInitialized || service.client.auth.currentSession == null) {
      _showOptionDetails(
        'Link $label',
        context.colors,
        'Sign in with a Prep404 account first. Then you can link $label to that account.',
      );
      return;
    }

    try {
      final oauth = await service.client.auth.getLinkIdentityUrl(
        provider,
        redirectTo: AppConfig.authRedirectUri,
      );
      final opened = await launchUrl(
        Uri.parse(oauth.url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showOptionDetails(
          'Link $label',
          context.colors,
          'Could not open the $label sign-in page. Check that the provider is enabled in Supabase.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showOptionDetails(
        'Link $label',
        context.colors,
        'Could not start $label linking. Check the provider credentials and redirect URL in Supabase.',
      );
    }
  }

  Future<void> _openLearnerSupport() async {
    if (GoRouter.maybeOf(context) != null) {
      await context.push<void>(AppRoutes.learnerSupport);
    } else {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const LearnerSupportScreen()),
      );
    }
  }

  void _openEditFlow({int step = 0}) async {
    UserProfile? updated;
    if (GoRouter.maybeOf(context) != null) {
      updated = await context.push<UserProfile>(
        AppRoutes.onboarding,
        extra: _currentProfile,
      );
    } else {
      updated = await Navigator.of(context).push<UserProfile>(
        MaterialPageRoute(
          builder: (_) => OnboardingFlowScreen(
            initialProfile: _currentProfile,
            initialStep: step,
            isEditing: true,
            onCompleted: (newProf) {
              CacheService().saveProfile(newProf);
              if (mounted) {
                setState(() {
                  _currentProfile = newProf;
                });
              }
              widget.onProfileUpdated?.call(newProf);
            },
          ),
        ),
      );
    }
    final res = updated;
    if (res != null && mounted) {
      CacheService().saveProfile(res);
      setState(() {
        _currentProfile = res;
      });
      widget.onProfileUpdated?.call(res);
    }
  }

  void _showLogoutDialog(BuildContext context, AppColors colors) {
    if (GoRouter.maybeOf(context) != null) {
      context.push(AppRoutes.logoutDialog);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => LogoutConfirmDialog(
          colors: colors,
          onConfirm: () {
            Navigator.pop(context); // Close Profile Screen
            widget.onLogOut();
          },
        ),
      );
    }
  }

  void _showDeleteAccountDialog(BuildContext context, AppColors colors) {
    if (GoRouter.maybeOf(context) != null) {
      context.push(AppRoutes.deleteAccountDialog);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => DeleteAccountDialog(
          colors: colors,
          onConfirm: (reason) {
            Navigator.pop(context); // Close Profile Screen
            if (widget.onDeleteAccount != null) {
              widget.onDeleteAccount!(reason);
            } else {
              widget.onLogOut();
            }
          },
        ),
      );
    }
  }

  void _openAccountInfoScreen(BuildContext context) async {
    UserProfile? updated;
    if (GoRouter.maybeOf(context) != null) {
      updated = await context.push<UserProfile>(AppRoutes.accountInfo);
    } else {
      updated = await Navigator.push<UserProfile>(
        context,
        MaterialPageRoute(
          builder: (_) => AccountInfoScreen(
            profile: _currentProfile,
            onProfileUpdated: (updated) {
              setState(() => _currentProfile = updated);
              widget.onProfileUpdated?.call(updated);
            },
            onLogOut: widget.onLogOut,
            onDeleteAccount: widget.onDeleteAccount,
          ),
        ),
      );
    }
    final res = updated;
    if (res != null && mounted) {
      setState(() => _currentProfile = res);
      widget.onProfileUpdated?.call(res);
    }
  }

  void _showComingSoonSnackBar(BuildContext context, String title) {
    final colors = context.colors;
    final message = switch (title) {
      'Upgrade' ||
      'Subscription' =>
        'Your account is using the free Prep404 experience. Paid checkout is not connected in this build.',
      'Prep404 Community' =>
        'Community access is not configured for this app build yet.',
      'Reported Questions' =>
        'There are no question reports saved on this device.',
      'Gifts' ||
      'Gift Delivery' =>
        'There are no active gifts or deliveries on this account.',
      'Prep404 Blog' => 'The Prep404 blog is not connected in this app build.',
      'About Us' =>
        'Prep404 helps students prepare for university admission with question practice, mock tests, and a personalized study plan.',
      'Terms of Service' ||
      'Privacy Policy' =>
        'The published $title document is not configured in this app build.',
      'Facebook Link' ||
      'Google Link' ||
      'Apple Link' =>
        'Account linking for $title is not configured yet. Your current sign-in remains active.',
      _ => '$title is not available for this account yet.',
    };
    _showOptionDetails(title, colors, message);
  }

  String _getCurriculumSubtitle(UserProfile p) {
    if (p.medium == StudentMedium.english) {
      final curr = p.englishCurriculum == EnglishCurriculum.edexcel
          ? 'Pearson Edexcel'
          : 'Cambridge International';
      return 'English Medium • $curr';
    } else {
      final ver = p.nctbVersion == NctbVersion.english
          ? 'English Version'
          : 'Bangla Version';
      return 'Bangla Medium (NCTB) • $ver';
    }
  }

  String _getInstitutionSubtitle(UserProfile p) {
    final inst =
        p.institutionName.isNotEmpty ? p.institutionName : 'Not selected';
    final batch =
        p.academicBatch.isNotEmpty ? p.academicBatch : 'Batch not selected';
    return '$inst • $batch';
  }

  String _getTargetsSubtitle(UserProfile p) {
    if (p.targetSelections.isEmpty) return 'No universities selected';
    final uniList =
        p.targetSelections.keys.map((k) => k.toUpperCase()).join(', ');
    final total = p.totalTargetedPrograms;
    return '$uniList ($total ${total == 1 ? 'Program' : 'Programs'})';
  }

  Widget _buildSetupRow({
    required BuildContext context,
    required AppColors colors,
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
  }) =>
      ProfileSetupRow(
        colors: colors,
        title: title,
        value: value,
        icon: icon,
        onEdit: onEdit,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = AppStrings.of(context);
    final initialLetter = _currentProfile.name.trim().isNotEmpty
        ? _currentProfile.name.trim()[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.onLanguageChanged != null)
            AppLanguageMenuButton(
              language: strings.language,
              onChanged: widget.onLanguageChanged!,
              foregroundColor: colors.textPrimary,
            ),
          const ThemeToggleIconButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Avatar Circle
            CircleAvatar(
              radius: 44,
              backgroundColor: colors.deepPlum,
              child: ClipOval(
                child: Image.asset(
                  context.isDark
                      ? 'assets/images/brand/Prep404_Profile_Dark.png'
                      : 'assets/images/brand/Prep404_Profile_Light.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      initialLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // User Name
            Text(
              _currentProfile.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),

            // Batch Badge Pill
            if (_currentProfile.academicBatch.trim().isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Batch: ${_currentProfile.academicBatch.trim()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.deepPlum,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const SizedBox(height: 12),
            ],

            // 🎓 FULLY EDITABLE ADMISSION & ACADEMIC SETUP CARD 🎓
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.borderSubtle),
                boxShadow: colors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  colors.accentEmerald.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.school_rounded,
                                color: colors.accentEmerald, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Admission Profile & Setup',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: colors.accentEmerald,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _openEditFlow(step: 0),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Edit All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. Medium & Curriculum
                  _buildSetupRow(
                    context: context,
                    colors: colors,
                    title: 'Curriculum / Version',
                    value: _getCurriculumSubtitle(_currentProfile),
                    icon: Icons.menu_book_rounded,
                    onEdit: () => _openEditFlow(step: 0),
                  ),
                  const SizedBox(height: 10),

                  // 2. School / College & Academic Batch
                  _buildSetupRow(
                    context: context,
                    colors: colors,
                    title: 'Institution & Batch',
                    value: _getInstitutionSubtitle(_currentProfile),
                    icon: Icons.account_balance_rounded,
                    onEdit: () => _openEditFlow(step: 1),
                  ),
                  const SizedBox(height: 10),

                  // 3. Target Universities & Disciplines
                  _buildSetupRow(
                    context: context,
                    colors: colors,
                    title: 'Target Universities',
                    value: _getTargetsSubtitle(_currentProfile),
                    icon: Icons.track_changes_rounded,
                    onEdit: () => _openEditFlow(step: 2),
                  ),
                  const SizedBox(height: 10),

                  // 4. Candidate Details
                  _buildSetupRow(
                    context: context,
                    colors: colors,
                    title: 'Student & Contact Info',
                    value:
                        '${_currentProfile.name}${_currentProfile.phone.isNotEmpty ? ' • ${_currentProfile.phone}' : ''}',
                    icon: Icons.person_outline_rounded,
                    onEdit: () => _openEditFlow(step: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notification Reminder Blue Card
            InkWell(
              onTap: () => _openNotificationsSettings(colors),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.primaryLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _practiceRemindersEnabled
                                ? 'Practice reminders are turned on'
                                : 'Turn on notifications so you never miss practice!',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: colors.deepPlum,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _practiceRemindersEnabled
                                ? 'Your reminder preference is saved on this device'
                                : 'Tap to manage your reminder preference',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Link Account Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderSubtle),
                boxShadow: colors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Linked Accounts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildSocialPill(
                        semanticLabel: 'Link Facebook account',
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'f',
                              style: TextStyle(
                                color: Color(0xFF1877F2),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.add, size: 14, color: Color(0xFF6B7280)),
                          ],
                        ),
                        onTap: () => _linkSocialAccount(
                            OAuthProvider.facebook, 'Facebook'),
                      ),
                      _buildSocialPill(
                        semanticLabel: 'Link Google account',
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'G',
                              style: TextStyle(
                                color: Color(0xFFEA4335),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.add, size: 14, color: Color(0xFF6B7280)),
                          ],
                        ),
                        onTap: () =>
                            _linkSocialAccount(OAuthProvider.google, 'Google'),
                      ),
                      _buildSocialPill(
                        semanticLabel: 'Link Apple account',
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.apple,
                                size: 16, color: Color(0xFF1F2937)),
                            SizedBox(width: 2),
                            Icon(Icons.add, size: 14, color: Color(0xFF6B7280)),
                          ],
                        ),
                        onTap: () =>
                            _linkSocialAccount(OAuthProvider.apple, 'Apple'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Group 2: Upgrade & Subscription
            _buildGroupCard(
              colors: colors,
              children: [
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  icon: Icons.workspace_premium_rounded,
                  title: 'Upgrade',
                  onTap: () {
                    if (GoRouter.maybeOf(context) != null) {
                      context.push(AppRoutes.upgrade);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                      );
                    }
                  },
                ),
                _buildDivider(colors),
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFFF3E6),
                  iconColor: const Color(0xFFFF7A36),
                  icon: Icons.credit_card_rounded,
                  title: 'Subscription',
                  onTap: () {
                    if (GoRouter.maybeOf(context) != null) {
                      context.push(AppRoutes.subscription);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Group 3: Community, Notifications, Support, Reported Questions
            _buildGroupCard(
              colors: colors,
              children: [
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFFEDD5),
                  iconColor: const Color(0xFFEA580C),
                  icon: Icons.forum_rounded,
                  title: 'Prep404 Community',
                  onTap: () {
                    if (GoRouter.maybeOf(context) != null) {
                      context.push(AppRoutes.communityLinks);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CommunityLinksScreen(),
                        ),
                      );
                    }
                  },
                ),
                _buildDivider(colors),
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFDC2626),
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  onTap: () => _openNotificationsSettings(colors),
                ),
                _buildDivider(colors),
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFE0E7FF),
                  iconColor: const Color(0xFF4F46E5),
                  icon: Icons.insights_rounded,
                  title: 'Learning analytics privacy',
                  onTap: () => _openAnalyticsPrivacySettings(colors),
                ),
                _buildDivider(colors),
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  icon: Icons.support_agent_rounded,
                  title: 'Contact Support',
                  onTap: _openLearnerSupport,
                ),
                _buildDivider(colors),
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFDC2626),
                  icon: Icons.flag_rounded,
                  title: 'Reported Questions',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ReportedQuestionsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Group 4: Gift & Delivery
            _buildGroupCard(
              colors: colors,
              children: [
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  icon: Icons.card_giftcard_rounded,
                  title: 'Gifts & Perks',
                  onTap: () => _showComingSoonSnackBar(context, 'Gifts'),
                ),
                _buildDivider(colors),
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFEF4444),
                  icon: Icons.inventory_2_rounded,
                  title: 'Gift Delivery',
                  onTap: () =>
                      _showComingSoonSnackBar(context, 'Gift Delivery'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Group 5: Blog, About, Terms, Privacy, Account Info
            _buildGroupCard(
              colors: colors,
              children: [
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFFF3E6),
                  iconColor: const Color(0xFF542747),
                  icon: Icons.auto_stories_rounded,
                  title: 'Prep404 Blog',
                  onTap: () => _showComingSoonSnackBar(context, 'Prep404 Blog'),
                ),
                _buildDivider(colors),
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFFF3E6),
                  iconColor: const Color(0xFF542747),
                  icon: Icons.info_outline_rounded,
                  title: 'About Us',
                  onTap: () {
                    if (GoRouter.maybeOf(context) != null) {
                      context.push(AppRoutes.aboutUs);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutUsScreen(),
                        ),
                      );
                    }
                  },
                ),
                _buildDivider(colors),
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFFF3E6),
                  iconColor: const Color(0xFF542747),
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () =>
                      _showComingSoonSnackBar(context, 'Terms of Service'),
                ),
                _buildDivider(colors),
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFFF3E6),
                  iconColor: const Color(0xFF542747),
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  onTap: () =>
                      _showComingSoonSnackBar(context, 'Privacy Policy'),
                ),
                _buildDivider(colors),
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFFF3E6),
                  iconColor: const Color(0xFF542747),
                  icon: Icons.badge_outlined,
                  title: 'Account Info',
                  onTap: () => _openAccountInfoScreen(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Group 6: Delete Account
            _buildGroupCard(
              colors: colors,
              children: [
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFFEE2E2),
                  iconColor: const Color(0xFFDC2626),
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Account',
                  onTap: () => _showDeleteAccountDialog(context, colors),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Group 7: Logout
            _buildGroupCard(
              colors: colors,
              children: [
                _buildMenuItem(
                  colors: colors,
                  iconContainerColor: const Color(0xFFF1F5F9),
                  iconColor: const Color(0xFF475569),
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  onTap: () => _showLogoutDialog(context, colors),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Footer
            Text(
              'Prep404 © 2026. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialPill({
    required String semanticLabel,
    required Widget child,
    required VoidCallback onTap,
  }) =>
      ProfileSocialPill(
        semanticLabel: semanticLabel,
        onTap: onTap,
        child: child,
      );

  Widget _buildGroupCard({
    required AppColors colors,
    required List<Widget> children,
  }) =>
      ProfileGroupCard(colors: colors, children: children);

  Widget _buildDivider(AppColors colors) => Divider(
        height: 1,
        thickness: 1,
        indent: 56,
        color: colors.borderSubtle,
      );

  Widget _buildMenuItem({
    required AppColors colors,
    required Color iconContainerColor,
    required Color iconColor,
    required IconData icon,
    required String title,
    String? trailingBadge,
    Widget? trailing,
    required VoidCallback onTap,
  }) =>
      ProfileMenuItem(
        colors: colors,
        iconContainerColor: iconContainerColor,
        iconColor: iconColor,
        icon: icon,
        title: title,
        trailingBadge: trailingBadge,
        trailing: trailing,
        onTap: onTap,
      );
}
