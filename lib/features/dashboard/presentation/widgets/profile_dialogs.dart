import 'package:flutter/material.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/theme/app_theme.dart';

class LogoutConfirmDialog extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onConfirm;

  const LogoutConfirmDialog({
    super.key,
    required this.colors,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 10),
          Text(
            'Log Out',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to log out of Prep404?',
        style: TextStyle(fontSize: 14, color: colors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text(
            'Log Out',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class DeleteAccountDialog extends StatelessWidget {
  final AppColors colors;
  final ValueChanged<String> onConfirm;

  const DeleteAccountDialog({
    super.key,
    required this.colors,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    String? selectedReason;
    const reasons = <(String, String)>[
      ('no_longer_needed', 'I no longer need my account'),
      ('privacy_concerns', 'Privacy concerns'),
      ('technical_issues', 'Technical issues'),
      ('switching_service', 'I am switching to another service'),
      ('other', 'Other'),
      ('prefer_not_to_say', 'Prefer not to say'),
    ];
    return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
              scrollable: true,
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.delete_forever_rounded,
                      color: Color(0xFFDC2626)),
                  const SizedBox(width: 10),
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to permanently delete your account? Your profile and study data will be erased. This action cannot be undone.',
                      style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Text('Why are you leaving? (your answer is optional)',
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    RadioGroup<String>(
                      groupValue: selectedReason,
                      onChanged: (value) =>
                          setDialogState(() => selectedReason = value),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: reasons
                            .map((reason) => RadioListTile<String>(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(reason.$2,
                                      style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 13)),
                                  value: reason.$1,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm(selectedReason ?? 'prefer_not_to_say');
                  },
                  child: const Text(
                    'Delete Permanently',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ));
  }
}

class PersonalDetailsSheet extends StatelessWidget {
  final UserProfile profile;
  final AppColors colors;
  final VoidCallback onEdit;

  const PersonalDetailsSheet({
    super.key,
    required this.profile,
    required this.colors,
    required this.onEdit,
  });

  Widget _infoRow(String label, String value, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow('Full Name', profile.name, colors),
          _infoRow(
            'Phone Number',
            profile.phone.isNotEmpty ? profile.phone : 'Not added',
            colors,
          ),
          _infoRow(
            'Medium',
            profile.medium.name.toUpperCase(),
            colors,
          ),
          _infoRow(
            'Academic Batch',
            profile.academicBatch.isNotEmpty
                ? profile.academicBatch
                : "HSC '25",
            colors,
          ),
          _infoRow(
            'Institution',
            profile.institutionName.isNotEmpty
                ? profile.institutionName
                : 'Not specified',
            colors,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                  child: const Text(
                    'Edit Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
