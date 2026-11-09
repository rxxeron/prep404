import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/cache_service.dart';
import '../theme/app_theme.dart';

// ============================================================================
// 1. EMPTY STATE
// ============================================================================

/// Clean, distraction-free empty state for lists, scripts, and content views
class PrepEmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customGraphic;

  const PrepEmptyStateView({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'Nothing Here Yet',
    this.subtitle = 'When you complete activities or save items, they will appear here.',
    this.actionLabel,
    this.onAction,
    this.customGraphic,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            customGraphic ??
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: colors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 34, color: colors.tangerine),
                ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAction!();
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.tangerine,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. LOADING STATE
// ============================================================================

/// Standardized loading indicator with branded accent and optional message
class PrepLoadingStateView extends StatelessWidget {
  final String? message;
  final bool isFullScreen;

  const PrepLoadingStateView({
    super.key,
    this.message = 'Loading...',
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(colors.tangerine),
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isFullScreen) {
      return Scaffold(
        backgroundColor: colors.background,
        body: content,
      );
    }
    return content;
  }
}

// ============================================================================
// 3. ERROR STATE
// ============================================================================

/// Actionable error state with user-friendly copy and retry hook
class PrepErrorStateView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String? debugInfo;

  const PrepErrorStateView({
    super.key,
    this.title = 'Unable to Load Content',
    this.message = 'Something went wrong while fetching this data. Please check your connection and try again.',
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.debugInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.dangerRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 34, color: colors.dangerRed),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            if (debugInfo != null && debugInfo!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Code: $debugInfo',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: colors.textMuted,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRetry!();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(retryLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. NO INTERNET STATE
// ============================================================================

/// Offline state when connection is lost
class PrepNoInternetView extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onOpenOfflineMode;

  const PrepNoInternetView({
    super.key,
    this.onRetry,
    this.onOpenOfflineMode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, size: 36, color: colors.tangerine),
            ),
            const SizedBox(height: 20),
            Text(
              'No Internet Connection',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your Wi-Fi or mobile data connection. Previously synced past papers remain accessible offline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onRetry!();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.tangerine,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                if (onOpenOfflineMode != null) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onOpenOfflineMode,
                    icon: const Icon(Icons.cloud_done_outlined, size: 16),
                    label: const Text('Offline Mode'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 5. SLOW NETWORK STATE
// ============================================================================

/// State triggered when latency is high or timeouts occur
class PrepSlowNetworkView extends StatelessWidget {
  final VoidCallback? onKeepWaiting;
  final VoidCallback? onSwitchOffline;

  const PrepSlowNetworkView({
    super.key,
    this.onKeepWaiting,
    this.onSwitchOffline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.accentAmber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.speed_rounded, size: 34, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 18),
            Text(
              'Connection is Slow',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Requests are taking longer than normal to respond. You can wait a moment or proceed with cached study material.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onKeepWaiting != null)
                  ElevatedButton(
                    onPressed: onKeepWaiting,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.tangerine,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Keep Waiting'),
                  ),
                if (onSwitchOffline != null) ...[
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: onSwitchOffline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    child: const Text('Use Cached Data'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 6. NO SEARCH RESULT STATE
// ============================================================================

/// Specialized empty state for search queries with clear search action
class PrepNoSearchResultsView extends StatelessWidget {
  final String query;
  final VoidCallback? onClearSearch;
  final String? suggestionText;

  const PrepNoSearchResultsView({
    super.key,
    required this.query,
    this.onClearSearch,
    this.suggestionText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(Icons.search_off_rounded, size: 32, color: colors.textMuted),
            ),
            const SizedBox(height: 18),
            Text(
              'No Results Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.45),
                children: [
                  const TextSpan(text: 'We could not find anything matching "'),
                  TextSpan(
                    text: query,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const TextSpan(text: '".'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              suggestionText ?? 'Check for typos or try searching by subject, topic or varsity name.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colors.textMuted,
              ),
            ),
            if (onClearSearch != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onClearSearch!();
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Clear Search Filter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.tangerine,
                  side: BorderSide(color: colors.tangerine.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 7. PERMISSION DENIED STATE
// ============================================================================

/// Displayed when a critical permission (notifications, storage) is blocked
class PrepPermissionDeniedView extends StatelessWidget {
  final String permissionName;
  final String reason;
  final VoidCallback? onOpenSettings;
  final IconData icon;

  const PrepPermissionDeniedView({
    super.key,
    this.permissionName = 'Notifications',
    this.reason = 'Allow notifications so you never miss 10:00 AM daily model tests, streak alerts, and exam deadlines.',
    this.onOpenSettings,
    this.icon = Icons.notifications_off_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.accentAmber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: const Color(0xFFD97706)),
            ),
            const SizedBox(height: 18),
            Text(
              '$permissionName Permission Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            if (onOpenSettings != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('Open App Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.tangerine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 8. SESSION EXPIRED STATE
// ============================================================================

/// Notifies user that token or authentication session expired
class PrepSessionExpiredView extends StatelessWidget {
  final VoidCallback onReauthenticate;

  const PrepSessionExpiredView({
    super.key,
    required this.onReauthenticate,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onReauthenticate}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: colors.dangerRed, size: 24),
              const SizedBox(width: 10),
              Text(
                'Session Expired',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
            ],
          ),
          content: Text(
            'Your security session has expired. Please sign in again to keep your exam submissions and streak synchronized.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                CacheService().remove('auth_token');
                onReauthenticate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Log In Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.dangerRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_clock_outlined, size: 34, color: colors.dangerRed),
            ),
            const SizedBox(height: 18),
            Text(
              'Session Expired',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your login session has ended. Sign in again to ensure your scores and rankings are preserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () {
                CacheService().remove('auth_token');
                onReauthenticate();
              },
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text('Log In Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 9. FORM VALIDATION UTILITIES
// ============================================================================

/// Bangladeshi EdTech Form Validation Logic & Helpers
class PrepFormValidator {
  static final RegExp _bdPhoneRegex = RegExp(r'^(?:\+?880|0)?1[3-9]\d{8}$');
  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');

  /// Validates Bangladeshi phone numbers (01XXXXXXXXX)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final clean = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!_bdPhoneRegex.hasMatch(clean)) {
      return 'Enter a valid 11-digit mobile number (e.g. 017XXXXXXXX)';
    }
    return null;
  }

  /// Validates Candidate Name (2 to 60 characters)
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (trimmed.length > 60) {
      return 'Name cannot exceed 60 characters';
    }
    return null;
  }

  /// Validates OTP verification code
  static String? validateOtp(String? value, {int length = 6}) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the $length-digit verification code';
    }
    final clean = value.trim();
    if (!RegExp(r'^\d+$').hasMatch(clean)) {
      return 'OTP must contain numbers only';
    }
    if (clean.length < 4 || clean.length > length) {
      return 'Enter valid $length-digit code';
    }
    return null;
  }

  /// Validates Candidate Email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email optional if phone primary
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// General Required Field
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}

// ============================================================================
// 10. SUCCESS RATE / ACCURACY BADGE
// ============================================================================

/// Visual display of candidate accuracy / success rate
class PrepSuccessRateBadge extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final double? overrideRate;
  final bool showLabel;
  final double fontSize;

  const PrepSuccessRateBadge({
    super.key,
    this.correctCount = 0,
    this.totalCount = 0,
    this.overrideRate,
    this.showLabel = true,
    this.fontSize = 12,
  });

  double get rate =>
      overrideRate ?? (totalCount > 0 ? (correctCount / totalCount) * 100 : 0.0);

  Color getTierColor(AppColors colors) {
    if (rate >= 75.0) return colors.accentEmerald;
    if (rate >= 50.0) return const Color(0xFFF59E0B);
    return colors.dangerRed;
  }

  String getTierLabel() {
    if (rate >= 75.0) return 'High Mastery';
    if (rate >= 50.0) return 'Moderate';
    return 'Needs Practice';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = getTierColor(colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rate >= 50.0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: fontSize + 2,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            '${rate.toStringAsFixed(1)}%${showLabel ? ' • ${getTierLabel()}' : ''}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Comprehensive Accuracy & Success Rate Card
class PrepSuccessRateCard extends StatelessWidget {
  final int correctCount;
  final int wrongCount;
  final int totalCount;
  final double? targetCutoffRate; // e.g. 70.0% for BUET/BRACU

  const PrepSuccessRateCard({
    super.key,
    required this.correctCount,
    required this.wrongCount,
    required this.totalCount,
    this.targetCutoffRate,
  });

  double get rate => totalCount > 0 ? (correctCount / totalCount) * 100 : 0.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meetsCutoff = targetCutoffRate == null || rate >= targetCutoffRate!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Success Rate (Accuracy)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              PrepSuccessRateBadge(
                correctCount: correctCount,
                totalCount: totalCount,
                fontSize: 11,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (rate / 100).clamp(0.0, 1.0),
              backgroundColor: colors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 75.0
                    ? colors.accentEmerald
                    : (rate >= 50.0 ? const Color(0xFFF59E0B) : colors.dangerRed),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$correctCount correct / $totalCount attempted',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              if (targetCutoffRate != null)
                Text(
                  meetsCutoff
                      ? '✓ Above Cutoff (${targetCutoffRate!.toStringAsFixed(0)}%)'
                      : '⚠ Below Cutoff (${targetCutoffRate!.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: meetsCutoff ? colors.accentEmerald : colors.dangerRed,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
