import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';

/// In-App Notification Center & Inbox Screen
/// Supports rich attachments (images), multi-event action handlers,
/// tap tracking telemetry, and live read-state synchronization with PostgreSQL.
class NotificationCenterScreen extends StatefulWidget {
  final String? userId;

  const NotificationCenterScreen({
    super.key,
    this.userId,
  });

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final ExamRepository _examRepo = ExamRepository();
  bool _isLoading = true;
  List<AppNotification> _notifications = [];
  String _selectedFilter = 'all'; // 'all', 'unread', 'exam', 'system'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final effectiveUid = widget.userId ?? SupabaseService().currentUser?.id;
    try {
      final list = await _examRepo.fetchUserNotifications(userId: effectiveUid);
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<AppNotification> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'unread':
        return _notifications.where((n) => !n.isRead).toList();
      case 'exam':
        return _notifications
            .where((n) =>
                n.eventType.toLowerCase().contains('exam') ||
                n.eventType.toLowerCase().contains('live') ||
                n.eventType.toLowerCase().contains('challenge'))
            .toList();
      case 'system':
        return _notifications
            .where((n) =>
                n.eventType.toLowerCase().contains('streak') ||
                n.eventType.toLowerCase().contains('system') ||
                n.eventType.toLowerCase().contains('announcement') ||
                n.eventType.toLowerCase().contains('update'))
            .toList();
      default:
        return _notifications;
    }
  }

  Future<void> _markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });

    final effectiveUid = widget.userId ?? SupabaseService().currentUser?.id;
    for (final n in unread) {
      _examRepo.markNotificationAsRead(n.id, userId: effectiveUid);
    }
  }

  Future<void> _handleNotificationTap(AppNotification n,
      {String? customActionId}) async {
    final effectiveUid = widget.userId ?? SupabaseService().currentUser?.id;

    // 1. Mark as read immediately in local state and DB
    if (!n.isRead) {
      setState(() {
        final idx = _notifications.indexWhere((element) => element.id == n.id);
        if (idx != -1) {
          _notifications[idx] = n.copyWith(isRead: true);
        }
      });
      _examRepo.markNotificationAsRead(n.id, userId: effectiveUid);
    }

    // 2. Track tap telemetry event
    final actionIdToLog = customActionId ?? n.actionType;
    _examRepo.recordNotificationTapEvent(
      notificationId: n.id,
      campaignId: n.campaignId,
      userId: effectiveUid,
      event: 'tap',
      actionId: actionIdToLog,
      appState: 'foreground',
    );

    // 3. Dispatch action type routing
    if (n.actionType == 'deep_link' && n.targetRoute != null && n.targetRoute!.isNotEmpty) {
      final route = n.targetRoute!;
      if (GoRouter.maybeOf(context) != null) {
        context.push(route);
      }
    } else if (n.actionType == 'web_link' && n.externalUrl != null && n.externalUrl!.isNotEmpty) {
      try {
        final uri = Uri.parse(n.externalUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    } else if (n.actionType == 'app_open') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(n.title),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _iconForEvent(String eventType) {
    final lower = eventType.toLowerCase();
    if (lower.contains('streak')) return Icons.local_fire_department_rounded;
    if (lower.contains('exam') || lower.contains('live')) return Icons.assignment_turned_in_rounded;
    if (lower.contains('battle') || lower.contains('duel')) return Icons.bolt_rounded;
    if (lower.contains('promo') || lower.contains('discount')) return Icons.local_offer_rounded;
    if (lower.contains('system')) return Icons.notifications_active_rounded;
    return Icons.notifications_rounded;
  }

  Color _colorForEvent(String eventType, dynamic colors) {
    final lower = eventType.toLowerCase();
    if (lower.contains('streak')) return const Color(0xFFFF7A36);
    if (lower.contains('exam') || lower.contains('live')) return const Color(0xFF10B981);
    if (lower.contains('battle') || lower.contains('duel')) return const Color(0xFF8B5CF6);
    if (lower.contains('promo')) return const Color(0xFFEC4899);
    return const Color(0xFF3B82F6);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filtered = _filteredNotifications;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Text(
              'Notification Center',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.tangerine,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: Icon(Icons.done_all_rounded, size: 16, color: colors.tangerine),
              label: Text(
                'Mark Read',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.tangerine,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: colors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All (${_notifications.length})', colors),
                  const SizedBox(width: 8),
                  _buildFilterChip('unread', 'Unread ($_unreadCount)', colors),
                  const SizedBox(width: 8),
                  _buildFilterChip('exam', 'Exams & Live', colors),
                  const SizedBox(width: 8),
                  _buildFilterChip('system', 'Streaks & Alerts', colors),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // Content List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadNotifications,
              color: colors.tangerine,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _buildEmptyState(colors)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final n = filtered[index];
                            return _buildNotificationCard(n, colors);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, dynamic colors) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.tangerine : colors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.tangerine : colors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic colors) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(Icons.notifications_none_rounded, size: 36, color: colors.textMuted),
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedFilter == 'unread'
                    ? 'You are all caught up! No unread notifications.'
                    : 'Important announcements and alerts will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(AppNotification n, dynamic colors) {
    final eventColor = _colorForEvent(n.eventType, colors);
    final hasImage = n.imageUrl != null && n.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: () => _handleNotificationTap(n),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: n.isRead ? colors.surface : colors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead ? colors.border : colors.tangerine.withValues(alpha: 0.45),
            width: n.isRead ? 1 : 1.5,
          ),
          boxShadow: n.isRead ? colors.cardShadow : [
            BoxShadow(
              color: colors.tangerine.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon, Event tag, Relative timestamp, Unread Dot
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconForEvent(n.eventType), color: eventColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      n.eventType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: eventColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(n.createdAt),
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                  ),
                  if (!n.isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.tangerine,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                n.title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),

              // Body
              Text(
                n.body,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
              ),

              // Rich Image attachment if provided
              if (hasImage) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    n.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140,
                        color: colors.borderSubtle,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Multi-action Buttons (Custom actions or actionType CTA)
              const SizedBox(height: 12),
              if (n.actions.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: n.actions.map((act) {
                    final title = act['title']?.toString() ?? 'Action';
                    final actId = act['action']?.toString() ?? 'custom_action';
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: colors.tangerine),
                      ),
                      onPressed: () => _handleNotificationTap(n, customActionId: actId),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: colors.tangerine,
                        ),
                      ),
                    );
                  }).toList(),
                )
              else if (n.actionType == 'deep_link' && n.targetRoute != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Details →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.tangerine,
                      ),
                    ),
                  ],
                )
              else if (n.actionType == 'web_link' && n.externalUrl != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 14, color: colors.tangerine),
                    const SizedBox(width: 4),
                    Text(
                      'Open Link',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.tangerine,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
