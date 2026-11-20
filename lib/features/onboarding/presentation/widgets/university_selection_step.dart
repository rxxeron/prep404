import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/models/university_target.dart';
import '../../../../core/repositories/university_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_sorter.dart';
import '../../../../core/widgets/prep_skeleton.dart';
import '../../../../core/widgets/prep_staggered_list.dart';
import '../controllers/onboarding_controller.dart';

/// Step 3: Targeted Private Universities & Disciplines (Dynamic from Supabase)
class UniversitySelectionStep extends StatefulWidget {
  final OnboardingController controller;
  final AppLanguage language;

  const UniversitySelectionStep({
    super.key,
    required this.controller,
    this.language = AppLanguage.english,
  });

  @override
  State<UniversitySelectionStep> createState() =>
      _UniversitySelectionStepState();
}

class _UniversitySelectionStepState extends State<UniversitySelectionStep> {
  final UniversityRepository _repo = UniversityRepository();
  List<PrivateUniversity> _universities = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadUniversities(forceRefresh: true);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.currentStep == 2 && !_isLoading && !_isRefreshing) {
      _loadUniversities(forceRefresh: true);
    }
  }

  Future<void> _loadUniversities({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_universities.isEmpty) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    final unis = await _repo.getUniversities(forceRefresh: forceRefresh);
    final sorted = AppSorter.sortBy<PrivateUniversity>(
      unis,
      (u) => u.fullName,
    );
    if (mounted) {
      setState(() {
        _universities = sorted;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Color _getUniversityAccent(String code) {
    switch (code) {
      case 'NSU':
        return const Color(0xFFFF7A36); // Tangerine
      case 'BRACU':
        return const Color(0xFF542747); // Deep Plum
      case 'IUB':
        return const Color(0xFFFF7A36); // Tangerine
      case 'EWU':
        return const Color(0xFF542747); // Deep Plum
      case 'AUST':
        return const Color(0xFFFF7A36); // Tangerine
      case 'AIUB':
        return const Color(0xFF542747); // Deep Plum
      case 'UIU':
        return const Color(0xFFFF7A36); // Tangerine
      case 'UAP':
        return const Color(0xFF542747); // Deep Plum
      default:
        return const Color(0xFFFF7A36);
    }
  }

  String _formatDate(DateTime dt) {
    const enMonths = [
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
    final m = enMonths[dt.month - 1];
    return '${dt.day} $m ${dt.year}';
  }

  Widget _buildUniversityLogo(Color accent, PrivateUniversity uni) {
    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: (uni.logoUrl != null && uni.logoUrl!.isNotEmpty)
            ? Image.network(
                uni.logoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    _buildFallbackBadge(accent, uni.code),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  );
                },
              )
            : _buildFallbackBadge(accent, uni.code),
      ),
    );
  }

  Widget _buildFallbackBadge(Color accent, String code) {
    return Center(
      child: Text(
        code,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildExamTypeBadge(
      AppColors colors, AppStrings strings, String type) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (type) {
      case 'centralized':
        badgeColor = const Color(0xFF542747); // Deep Plum
        label = strings.centralizedExamBadge;
        icon = Icons.hub_outlined;
        break;
      case 'department_wise':
        badgeColor = const Color(0xFFFF7A36); // Tangerine
        label = strings.departmentWiseExamBadge;
        icon = Icons.account_tree_outlined;
        break;
      case 'faculty_wide':
      default:
        badgeColor = const Color(0xFFFF7A36); // Tangerine
        label = strings.facultyWideExamBadge;
        icon = Icons.school_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = AppStrings(widget.language);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.targetUniTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              IconButton(
                icon: _isRefreshing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                        ),
                      )
                    : Icon(Icons.refresh_rounded, size: 20, color: colors.textMuted),
                tooltip: 'Refresh upcoming schedules',
                onPressed: _isRefreshing
                    ? null
                    : () => _loadUniversities(forceRefresh: true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings.targetUniSubtitle,
            style: TextStyle(
                fontSize: 14, color: colors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: PrepInlineSkeleton(count: 4),
            )
          else
            ..._universities.asMap().entries.map(
                  (entry) => PrepStaggeredItem(
                    index: entry.key,
                    slideOffset: 16,
                    child: _buildUniversityTile(
                      context,
                      colors,
                      strings,
                      entry.value,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildUniversityTile(
    BuildContext context,
    AppColors colors,
    AppStrings strings,
    PrivateUniversity uni,
  ) {
    final isSelected = widget.controller.isUniversitySelected(uni.id);
    final accent = _getUniversityAccent(uni.code);
    final hasCycles = uni.admissionCycles.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? accent : colors.border,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : colors.cardShadow,
      ),
      child: Material(
        color: isSelected ? colors.primaryLight : colors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Checkbox
            CheckboxListTile(
              value: isSelected,
              activeColor: accent,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  _buildUniversityLogo(accent, uni),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: accent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                uni.code,
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                uni.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            uni.location,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildExamTypeBadge(colors, strings, uni.examFormatType),
                  ],
                ),
              ),
              onChanged: (_) {
                setState(() {
                  widget.controller.toggleUniversity(uni);
                });
              },
            ),

            // Admission Schedule & Slots Container
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: colors.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cycle Title & Status
                    Row(
                      children: [
                        Icon(Icons.event_note_outlined,
                            size: 14, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          hasCycles
                              ? '${uni.admissionCycles.first.season} ${uni.admissionCycles.first.academicYear} ${strings.upcomingAdmissionLabel}'
                              : strings.upcomingAdmissionLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Builder(
                          builder: (_) {
                            final isTba = hasCycles &&
                                uni.admissionCycles
                                    .every((c) => c.examDate == null);
                            final pillColor = isTba
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: pillColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isTba ? 'TBA' : 'Upcoming',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: pillColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    // Slot Details
                    if (hasCycles) ...[
                      const SizedBox(height: 8),
                      ...uni.admissionCycles.map((cycle) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: colors.border.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        cycle.slotTitle.isNotEmpty
                                            ? cycle.slotTitle
                                            : '${strings.slotLabel} ${cycle.slotNumber}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    cycle.applicationFee,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 11, color: colors.textMuted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      cycle.examDate != null
                                          ? '${strings.examDateLabel}: ${_formatDate(cycle.examDate!)}${cycle.examTime.isNotEmpty ? ' (${cycle.examTime})' : ''}'
                                          : '${strings.examDateLabel}: To Be Announced',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: cycle.examDate != null
                                              ? colors.textPrimary
                                              : colors.textSecondary,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              if (cycle.applicationDeadline != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.timer_outlined,
                                        size: 11, color: colors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${strings.applicationDeadlineLabel}: ${_formatDate(cycle.applicationDeadline!)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: colors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                              if (cycle.notes.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.verified_outlined,
                                        size: 11, color: colors.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        cycle.notes,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: colors.textMuted),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (cycle.venue.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.business_outlined,
                                        size: 11, color: colors.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        cycle.venue,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: colors.textMuted,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],

                    // Exam Pattern Summary Note
                    if (uni.examPatternSummary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 12, color: colors.textMuted),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              uni.examPatternSummary,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: colors.textSecondary,
                                  height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Expandable Undergraduate Programs Selector if University is selected
            if (isSelected) ...[
              Divider(height: 1, color: colors.border),
              Container(
                padding: const EdgeInsets.all(16),
                color: colors.surfaceElevated.withValues(alpha: 0.5),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.undergraduateProgramsLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${uni.disciplines.length} Programs',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Builder(
                      builder: (context) {
                        final Map<String, List<UniversityDiscipline>> grouped =
                            {};
                        for (final d in uni.disciplines) {
                          final dept = d.department.isNotEmpty
                              ? d.department
                              : 'Other Programs';
                          grouped.putIfAbsent(dept, () => []).add(d);
                        }

                        final sortedEntries = grouped.entries.toList()
                          ..sort((a, b) => AppSorter.compareAZ09(a.key, b.key));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sortedEntries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.account_balance_outlined,
                                          size: 12, color: accent),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: entry.value.map((disc) {
                                      final isDiscSelected = widget.controller
                                          .isDisciplineSelected(
                                              uni.id, disc.id);
                                      return FilterChip(
                                        selected: isDiscSelected,
                                        label: Text(
                                          disc.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isDiscSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isDiscSelected
                                                ? Colors.white
                                                : colors.textPrimary,
                                          ),
                                        ),
                                        selectedColor: accent,
                                        checkmarkColor: Colors.white,
                                        backgroundColor: colors.surface,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          side: BorderSide(
                                            color: isDiscSelected
                                                ? accent
                                                : colors.border,
                                          ),
                                        ),
                                        onSelected: (_) {
                                          setState(() {
                                            widget.controller.toggleDiscipline(
                                                uni.id, disc.id);
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
