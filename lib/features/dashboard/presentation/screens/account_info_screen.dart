import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/models/university_target.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../onboarding/presentation/screens/onboarding_flow_screen.dart';
import '../widgets/profile_dialogs.dart';

/// Dedicated Account & Personal Information Screen with Integrated Account Deletion
class AccountInfoScreen extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile>? onProfileUpdated;
  final VoidCallback onLogOut;
  final Future<void> Function(String reason)? onDeleteAccount;

  const AccountInfoScreen({
    super.key,
    required this.profile,
    this.onProfileUpdated,
    required this.onLogOut,
    this.onDeleteAccount,
  });

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  late UserProfile _currentProfile;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
  }

  void _openEditFlow({int step = 0}) async {
    UserProfile? updated;
    if (GoRouter.maybeOf(context) != null) {
      updated = await context.push<UserProfile>(
        AppRoutes.onboarding,
        extra: _currentProfile,
      );
    } else {
      updated = await Navigator.push<UserProfile>(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingFlowScreen(
            isEditing: true,
            initialStep: step,
            initialProfile: _currentProfile,
            onCompleted: (p) {},
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

  void _showDeleteAccountDialog(BuildContext context, AppColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => DeleteAccountDialog(
        colors: colors,
        onConfirm: (reason) async {
          if (widget.onDeleteAccount != null) {
            await widget.onDeleteAccount!(reason);
          }
        },
      ),
    );
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
            Navigator.pop(ctx);
            widget.onLogOut();
          },
        ),
      );
    }
  }

  Widget _buildCard({
    required AppColors colors,
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required AppColors colors,
    required String label,
    required String value,
    IconData? icon,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: colors.textMuted),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: isHighlighted ? colors.primary : colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authEmail = SupabaseService().currentUser?.email;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context, _currentProfile),
        ),
        title: Text(
          'Account & Personal Info',
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
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: colors.primary.withValues(alpha: 0.15),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF7A36), Color(0xFF542747)],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '404',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentProfile.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (_currentProfile.academicBatch.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Batch: ${_currentProfile.academicBatch.trim()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card 1: Personal & Contact Information
            _buildCard(
              colors: colors,
              title: 'Personal Information',
              icon: Icons.person_outline_rounded,
              trailing: TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Details'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _openEditFlow(step: 1),
              ),
              children: [
                _buildDetailRow(
                  colors: colors,
                  label: 'Full Name',
                  value: _currentProfile.name,
                ),
                _buildDetailRow(
                  colors: colors,
                  label: 'Mobile Number',
                  value: _currentProfile.phone.isNotEmpty ? _currentProfile.phone : 'Not provided',
                ),
                if (authEmail != null && authEmail.isNotEmpty)
                  _buildDetailRow(
                    colors: colors,
                    label: 'Email',
                    value: authEmail,
                  ),
                _buildDetailRow(
                  colors: colors,
                  label: 'Gender',
                  value: _currentProfile.gender != null
                      ? _currentProfile.gender!.toUpperCase()
                      : 'Not specified',
                ),
                _buildDetailRow(
                  colors: colors,
                  label: 'Region',
                  value: '${_currentProfile.districtName ?? ''}${_currentProfile.districtName != null && _currentProfile.divisionName != null ? ', ' : ''}${_currentProfile.divisionName ?? 'Not specified'}',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card 2: Academic Background & Curriculum
            _buildCard(
              colors: colors,
              title: 'Academic Details',
              icon: Icons.school_outlined,
              trailing: TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _openEditFlow(step: 1),
              ),
              children: [
                _buildDetailRow(
                  colors: colors,
                  label: 'Curriculum',
                  value: _currentProfile.medium == StudentMedium.bangla
                      ? 'NCTB (${_currentProfile.nctbVersion?.name.toUpperCase() ?? 'BANGLA'} VERSION)'
                      : 'ENGLISH MEDIUM (${_currentProfile.englishCurriculum?.displayName.toUpperCase() ?? 'CAMBRIDGE'})',
                  isHighlighted: true,
                ),
                _buildDetailRow(
                  colors: colors,
                  label: 'Current Batch',
                  value: _currentProfile.academicBatch.trim().isNotEmpty
                      ? _currentProfile.academicBatch
                      : 'Not specified',
                ),
                _buildDetailRow(
                  colors: colors,
                  label: 'College / School',
                  value: _currentProfile.institutionName.isNotEmpty
                      ? _currentProfile.institutionName
                      : 'Not specified',
                ),
                if (_currentProfile.hscGpa?.isNotEmpty == true)
                  _buildDetailRow(
                    colors: colors,
                    label: 'HSC Result',
                    value: _currentProfile.hscGpa!,
                  ),
                if (_currentProfile.sscGpa?.isNotEmpty == true)
                  _buildDetailRow(
                    colors: colors,
                    label: 'SSC Result',
                    value: _currentProfile.sscGpa!,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Card 3: University Targets
            _buildCard(
              colors: colors,
              title: 'Target Universities',
              icon: Icons.flag_outlined,
              trailing: TextButton.icon(
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Change Targets'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _openEditFlow(step: 2),
              ),
              children: [
                if (_currentProfile.targetSelections.isEmpty)
                  Text(
                    'No target universities selected yet.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  )
                else
                  ..._currentProfile.targetSelections.entries.map((entry) {
                    final uniCode = entry.key.toUpperCase();
                    final count = entry.value.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              uniCode,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$count program${count > 1 ? 's' : ''} targeted',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 24),

            // Card 4: Account Security & Danger Zone (Delete Account & Log Out)
            _buildCard(
              colors: colors,
              title: 'Account Security & Actions',
              icon: Icons.shield_outlined,
              children: [
                // Log Out Option
                InkWell(
                  onTap: () => _showLogoutDialog(context, colors),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.logout_rounded, color: Color(0xFF475569), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Log Out',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                'Sign out of your Prep404 candidate account',
                                style: TextStyle(fontSize: 12, color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Delete Account Option
                InkWell(
                  onTap: () => _showDeleteAccountDialog(context, colors),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2).withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delete Account',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              Text(
                                'Permanently erase all profile data and exam progress',
                                style: TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFDC2626), size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
