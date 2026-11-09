import 'package:flutter/material.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Dedicated full screen for managing user notification preferences
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Notification preference keys
  static const String _keyPracticeReminders = 'practice_reminders_enabled';
  static const String _keyStreakAlerts = 'streak_alerts_enabled';
  static const String _keyCircularAlerts = 'circular_alerts_enabled';
  static const String _keyExamDateAlerts = 'exam_schedule_alerts_enabled';
  static const String _keyContentUpdates = 'content_updates_enabled';
  static const String _keyWeeklySummary = 'weekly_summary_enabled';

  bool _practiceReminders = true;
  bool _streakAlerts = true;
  bool _circularAlerts = true;
  bool _examDateAlerts = true;
  bool _contentUpdates = true;
  bool _weeklySummary = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final cache = CacheService();
    setState(() {
      _practiceReminders = cache.read<bool>(_keyPracticeReminders) ?? true;
      _streakAlerts = cache.read<bool>(_keyStreakAlerts) ?? true;
      _circularAlerts = cache.read<bool>(_keyCircularAlerts) ?? true;
      _examDateAlerts = cache.read<bool>(_keyExamDateAlerts) ?? true;
      _contentUpdates = cache.read<bool>(_keyContentUpdates) ?? true;
      _weeklySummary = cache.read<bool>(_keyWeeklySummary) ?? true;
    });
  }

  void _updatePreference(String key, bool value, void Function() apply) {
    setState(apply);
    CacheService().write(key, value);
  }

  Widget _buildGroupCard({
    required AppColors colors,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
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
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required AppColors colors,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            activeTrackColor: colors.primary,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(AppColors colors) {
    return Divider(
      height: 18,
      thickness: 1,
      color: colors.borderSubtle,
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
          'Notifications',
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
            // Study Habits Group
            _buildGroupCard(
              colors: colors,
              title: 'Study Habits & Reminders',
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFFF97316),
              children: [
                _buildSwitchRow(
                  colors: colors,
                  title: 'Daily Practice Reminders',
                  subtitle:
                      'Timely reminders to complete your scheduled topic practice.',
                  value: _practiceReminders,
                  onChanged: (val) => _updatePreference(
                    _keyPracticeReminders,
                    val,
                    () => _practiceReminders = val,
                  ),
                ),
                _buildDivider(colors),
                _buildSwitchRow(
                  colors: colors,
                  title: 'Streak Saver Alert',
                  subtitle:
                      'Get notified before midnight if your practice streak is about to reset.',
                  value: _streakAlerts,
                  onChanged: (val) => _updatePreference(
                    _keyStreakAlerts,
                    val,
                    () => _streakAlerts = val,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Admission Circulars Group
            _buildGroupCard(
              colors: colors,
              title: 'Admission & University Alerts',
              icon: Icons.school_outlined,
              iconColor: const Color(0xFF2563EB),
              children: [
                _buildSwitchRow(
                  colors: colors,
                  title: 'Circular & Deadline Alerts',
                  subtitle:
                      'Immediate alerts when application windows open or close for your targeted universities.',
                  value: _circularAlerts,
                  onChanged: (val) => _updatePreference(
                    _keyCircularAlerts,
                    val,
                    () => _circularAlerts = val,
                  ),
                ),
                _buildDivider(colors),
                _buildSwitchRow(
                  colors: colors,
                  title: 'Exam Reschedule Notices',
                  subtitle:
                      'Critical push alerts if official admission exam dates or shift timings change.',
                  value: _examDateAlerts,
                  onChanged: (val) => _updatePreference(
                    _keyExamDateAlerts,
                    val,
                    () => _examDateAlerts = val,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Question Bank & Insights Group
            _buildGroupCard(
              colors: colors,
              title: 'Content & Progress Insights',
              icon: Icons.insights_rounded,
              iconColor: const Color(0xFF059669),
              children: [
                _buildSwitchRow(
                  colors: colors,
                  title: 'New Exam Papers & Variants',
                  subtitle:
                      'Notifies when new past year questions or KaTeX formula sets are published.',
                  value: _contentUpdates,
                  onChanged: (val) => _updatePreference(
                    _keyContentUpdates,
                    val,
                    () => _contentUpdates = val,
                  ),
                ),
                _buildDivider(colors),
                _buildSwitchRow(
                  colors: colors,
                  title: 'Weekly Readiness Report',
                  subtitle:
                      'A weekly summary of your topic accuracy, strengths, and target admission readiness score.',
                  value: _weeklySummary,
                  onChanged: (val) => _updatePreference(
                    _keyWeeklySummary,
                    val,
                    () => _weeklySummary = val,
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
