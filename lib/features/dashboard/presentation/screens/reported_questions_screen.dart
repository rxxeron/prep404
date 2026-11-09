import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../main.dart';
import '../../../../core/services/question_report_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Dedicated screen for learners to view, track, and inspect all reported questions
class ReportedQuestionsScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ReportedQuestionsScreen({super.key, this.userId});

  @override
  ConsumerState<ReportedQuestionsScreen> createState() =>
      _ReportedQuestionsScreenState();
}

class _ReportedQuestionsScreenState
    extends ConsumerState<ReportedQuestionsScreen> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;
  int _selectedFilterIndex = 0; // 0: All, 1: In Review, 2: Resolved

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    final effectiveUid = widget.userId ?? ref.read(userProfileProvider)?.id;
    setState(() {
      _reportsFuture = QuestionReportService().fetchMine(userId: effectiveUid);
    });
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final month = months[dt.month - 1];
      final day = dt.day;
      final year = dt.year;
      final hour = dt.hour > 12
          ? dt.hour - 12
          : dt.hour == 0
              ? 12
              : dt.hour;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$month $day, $year · $hour:$minute $ampm';
    } catch (_) {
      return dateVal.toString();
    }
  }

  List<Map<String, dynamic>> _filterReports(
      List<Map<String, dynamic>> allReports) {
    if (_selectedFilterIndex == 0) return allReports;
    if (_selectedFilterIndex == 1) {
      // In Review or Open
      return allReports.where((r) {
        final st = (r['status'] ?? 'open').toString().toLowerCase();
        return st == 'open' || st == 'in_review';
      }).toList();
    }
    // Resolved or Dismissed
    return allReports.where((r) {
      final st = (r['status'] ?? '').toString().toLowerCase();
      return st == 'resolved' || st == 'dismissed';
    }).toList();
  }

  Widget _buildFilterChip({
    required String label,
    required int index,
    required int count,
    required AppColors colors,
  }) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : colors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : colors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppColors colors) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'resolved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Resolved';
        icon = Icons.check_circle_rounded;
        break;
      case 'in_review':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        label = 'In Review';
        icon = Icons.search_rounded;
        break;
      case 'dismissed':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'Dismissed';
        icon = Icons.cancel_outlined;
        break;
      case 'open':
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Open';
        icon = Icons.schedule_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, AppColors colors) {
    final catName = QuestionReportService.categories[category] ??
        category.replaceAll('_', ' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_rounded, size: 12, color: Color(0xFFDC2626)),
          const SizedBox(width: 4),
          Text(
            catName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetailsDialog(
      Map<String, dynamic> report, AppColors colors) {
    final category = report['category']?.toString() ?? 'other';
    final catTitle = QuestionReportService.categories[category] ??
        category.replaceAll('_', ' ');
    final status = report['status']?.toString() ?? 'open';
    final questionText = report['questionText']?.toString();
    final description = report['description']?.toString() ?? '';
    final resolutionNote = report['resolutionNote']?.toString();
    final resolvedBy = report['resolvedBy']?.toString();
    final createdAt = _formatDate(report['createdAt'] ?? report['created_at']);
    final resolvedAt =
        _formatDate(report['resolvedAt'] ?? report['resolved_at']);
    final subject = report['subjectName']?.toString();
    final topic = report['topicName']?.toString();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    createdAt,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(status, colors),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subject != null || topic != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    [if (subject != null) subject, if (topic != null) topic]
                        .join(' • '),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (questionText != null && questionText.trim().isNotEmpty) ...[
                Text(
                  'Question Stem:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    questionText,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                'Your Feedback:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (resolutionNote != null &&
                  resolutionNote.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Moderator Resolution:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF86EFAC).withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolutionNote,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (resolvedBy != null || resolvedAt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '— ${resolvedBy ?? 'Academic Staff'}${resolvedAt.isNotEmpty ? ' on $resolvedAt' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
      Map<String, dynamic> report, AppColors colors) {
    final category = report['category']?.toString() ?? 'other';
    final status = report['status']?.toString() ?? 'open';
    final questionText = report['questionText']?.toString();
    final description = report['description']?.toString() ?? '';
    final resolutionNote = report['resolutionNote']?.toString();
    final createdAt = _formatDate(report['createdAt'] ?? report['created_at']);
    final subject = report['subjectName']?.toString();
    final topic = report['topicName']?.toString();

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showReportDetailsDialog(report, colors),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: category chip and status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryChip(category, colors),
                  _buildStatusBadge(status, colors),
                ],
              ),
              const SizedBox(height: 10),

              // Subject and topic pill if present
              if (subject != null || topic != null) ...[
                Row(
                  children: [
                    Icon(Icons.school_outlined,
                        size: 13, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      [if (subject != null) subject, if (topic != null) topic]
                          .join(' • '),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Question stem preview if available
              if (questionText != null && questionText.trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: colors.border.withValues(alpha: 0.7)),
                  ),
                  child: Text(
                    questionText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Candidate's report description
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),

              // Resolution note preview if resolved
              if (resolutionNote != null &&
                  resolutionNote.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF86EFAC).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 15, color: Color(0xFF15803D)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          resolutionNote,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: 8),

              // Bottom footer: date and view details link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    createdAt,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 14, color: colors.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_rounded,
                size: 40,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Reported Questions Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Notice a typo, incorrect answer, or unclear explanation? While practicing or reviewing exams, tap "Report a problem" on any question to submit feedback directly to our academic team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.hikingRoadmap),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.quiz_rounded, size: 18),
              label: const Text(
                'Explore Practice Arena',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
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
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: Text(
          'Reported Questions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textPrimary),
            tooltip: 'Refresh reports',
            onPressed: _loadReports,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48, color: colors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Unable to load your reports',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please check your connection and try again.',
                      style: TextStyle(
                          fontSize: 13, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loadReports,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allReports = snapshot.data ?? const <Map<String, dynamic>>[];
          final openCount = allReports.where((r) {
            final st = (r['status'] ?? 'open').toString().toLowerCase();
            return st == 'open' || st == 'in_review';
          }).length;
          final resolvedCount = allReports.where((r) {
            final st = (r['status'] ?? '').toString().toLowerCase();
            return st == 'resolved' || st == 'dismissed';
          }).length;

          final filtered = _filterReports(allReports);

          return RefreshIndicator(
            onRefresh: () async => _loadReports(),
            child: Column(
              children: [
                // Filter Segmented Bar
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: colors.surface,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'All Reports',
                          index: 0,
                          count: allReports.length,
                          colors: colors,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'In Review',
                          index: 1,
                          count: openCount,
                          colors: colors,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Resolved',
                          index: 2,
                          count: resolvedCount,
                          colors: colors,
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.border),

                // Reports List or Empty State
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(colors)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildReportCard(filtered[index], colors);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
