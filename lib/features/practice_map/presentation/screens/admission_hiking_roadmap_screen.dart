import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/university_roadmap_service.dart';
import '../../../../core/services/admission_plan_service.dart';
import '../../../../core/widgets/prep_skeleton.dart';
import '../../../exam/presentation/screens/live_model_test_screen.dart';
import '../widgets/milestone_path_painter.dart';
import '../widgets/milestone_details_sheet.dart';
import '../widgets/university_track_picker_sheet.dart';
import '../widgets/horizon_picker_sheet.dart';
import '../widgets/roadmap_hud_bar.dart';
import '../widgets/roadmap_summit_gate.dart';
import '../widgets/roadmap_milestone_node.dart';

/// Prep404 Signature Identity Palette:
/// Tangerine (#FF7A36) + Cream (#FFF3E6) + Deep Plum (#542747 / #240E20) + Sunshine (#FFD166)
class AdmissionHikingRoadmapScreen extends StatefulWidget {
  final List<String>? targetUniversityKeys;
  final VoidCallback onStartTest;
  final bool isEnglish;

  const AdmissionHikingRoadmapScreen({
    super.key,
    this.targetUniversityKeys,
    required this.onStartTest,
    this.isEnglish = true,
  });

  @override
  State<AdmissionHikingRoadmapScreen> createState() =>
      _AdmissionHikingRoadmapScreenState();
}

class _AdmissionHikingRoadmapScreenState
    extends State<AdmissionHikingRoadmapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final UniversityRoadmapService _service = UniversityRoadmapService();
  final AdmissionPlanService _planService = AdmissionPlanService();

  // Signature Palette Constants
  Color get colorTangerine => context.colors.tangerine;
  Color get colorCream =>
      context.isDark ? context.colors.cream : context.colors.deepPlum;
  Color get colorDarkPlumBase =>
      context.isDark ? const Color(0xFF241026) : context.colors.background;
  Color get colorCardPlum =>
      context.isDark ? const Color(0xFF35152F) : context.colors.surface;
  Color get colorPlumBorder =>
      context.isDark ? const Color(0xFF542747) : context.colors.border;
  Color get colorSunshine => context.colors.accentSunshine;
  Color get colorTeal => context.colors.deepPlum;
  Color get colorIndigo => context.colors.tangerine;

  String _activeUniversityKey = 'brac';
  String _activeTrack = 'engineering';
  PlanHorizon _selectedHorizon = PlanHorizon.thirtyDays;
  PlanPreparationPillar _selectedPillar = PlanPreparationPillar.all;
  bool _hasUserOverriddenHorizon = false;
  bool _motionPreferenceInitialized = false;
  bool _reduceMotionEnabled = false;

  Future<AdmissionJourneyData>? _journeyFuture;

  @override
  void initState() {
    super.initState();
    _service.ensureActiveTarget(widget.targetUniversityKeys ?? []);
    _activeUniversityKey = _service.activeUniversityKey.value;
    _selectedHorizon =
        _planService.getAutoHorizonForUniversity(_activeUniversityKey);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _loadJourney();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_motionPreferenceInitialized && reduceMotion == _reduceMotionEnabled) {
      return;
    }
    _motionPreferenceInitialized = true;
    _reduceMotionEnabled = reduceMotion;
    if (reduceMotion) {
      _pulseController.stop();
      _pulseController.value = 0.5;
    } else {
      _pulseController.repeat(reverse: true);
    }
  }

  void _loadJourney() {
    setState(() {
      _journeyFuture = _planService.fetchAdmissionJourney(
        universityKey: _activeUniversityKey,
        category: _activeTrack,
        horizonDays: _selectedHorizon.days,
      );
    });
  }

  @override
  void didUpdateWidget(covariant AdmissionHikingRoadmapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _service.ensureActiveTarget(widget.targetUniversityKeys ?? []);
    if (_activeUniversityKey != _service.activeUniversityKey.value) {
      _activeUniversityKey = _service.activeUniversityKey.value;
      _loadJourney();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _launchExam(BuildContext context, AdmissionPlanItem item) {
    HapticFeedback.mediumImpact();
    if (GoRouter.maybeOf(context) != null) {
      context.push(
        AppRoutes.liveModelTest,
        extra: {
          'slug': item.slug,
          'title': item.title,
          'durationMinutes': item.durationMinutes,
          'negativeMark': item.negativeMark,
        },
      ).then((_) {
        if (mounted) _loadJourney();
      });
    } else {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) => LiveModelTestScreen(
            slug: item.slug,
            title: item.title,
            durationMinutes: item.durationMinutes,
            negativeMark: item.negativeMark,
            onExit: () {
              Navigator.of(context).pop();
              _planService.markItemCompleted(item.id);
              _planService.markItemCompleted(item.slug);
              _loadJourney();
            },
          ),
        ),
      )
          .then((_) {
        if (mounted) _loadJourney();
      });
    }
  }

  String _formatTrackName(String track) {
    switch (track.toLowerCase()) {
      case 'engineering':
        return 'Engineering & CSE';
      case 'business':
        return 'Business & BBA';
      case 'pharmacy':
        return 'Pharmacy & Life Sciences';
      case 'architecture':
        return 'Architecture & Design';
      case 'sciences':
        return 'Biological & Physical Sciences';
      case 'law':
        return 'Law & Justice';
      case 'humanities':
        return 'Humanities & Social Sciences';
      default:
        return track.isNotEmpty
            ? '${track[0].toUpperCase()}${track.substring(1)}'
            : 'General Track';
    }
  }

  Color _getPillarColor(PlanPreparationPillar pillar) {
    switch (pillar) {
      case PlanPreparationPillar.topicWise:
        return colorTeal;
      case PlanPreparationPillar.subjectWise:
        return colorIndigo;
      case PlanPreparationPillar.sectionWise:
        return colorTangerine;
      case PlanPreparationPillar.overall:
      case PlanPreparationPillar.all:
        return colorSunshine;
    }
  }

  String _getPillarBadgeLabel(PlanPreparationPillar pillar) {
    switch (pillar) {
      case PlanPreparationPillar.topicWise:
        return 'TOPIC SPEED DRILL';
      case PlanPreparationPillar.subjectWise:
        return 'SUBJECT MASTERY';
      case PlanPreparationPillar.sectionWise:
        return 'FACULTY PATTERN';
      case PlanPreparationPillar.overall:
      case PlanPreparationPillar.all:
        return 'GRAND MOCK';
    }
  }

  IconData _getPillarIcon(PlanPreparationPillar pillar) {
    switch (pillar) {
      case PlanPreparationPillar.topicWise:
        return Icons.bolt_rounded;
      case PlanPreparationPillar.subjectWise:
        return Icons.auto_stories_rounded;
      case PlanPreparationPillar.sectionWise:
        return Icons.pie_chart_rounded;
      case PlanPreparationPillar.overall:
      case PlanPreparationPillar.all:
        return Icons.military_tech_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorDarkPlumBase,
      body: SafeArea(
        child: FutureBuilder<AdmissionJourneyData>(
          future: _journeyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const PrepPageSkeleton(cardCount: 2);
            }

            final journey = snapshot.data;
            if (journey == null) {
              return Center(
                child: Text(
                  'Failed to load admission journey from database.',
                  style: GoogleFonts.bricolageGrotesque(color: colorCream),
                ),
              );
            }

            // Sync auto horizon if user hasn't overridden
            if (!_hasUserOverriddenHorizon) {
              if (journey.autoHorizonDays == 10) {
                _selectedHorizon = PlanHorizon.tenDays;
              } else if (journey.autoHorizonDays == 15) {
                _selectedHorizon = PlanHorizon.fifteenDays;
              } else if (journey.autoHorizonDays == 60) {
                _selectedHorizon = PlanHorizon.twoMonths;
              } else {
                _selectedHorizon = PlanHorizon.thirtyDays;
              }
            }

            // Ensure activeTrack exists in availableTracks
            if (journey.availableTracks.contains(_activeTrack) == false &&
                journey.availableTracks.isNotEmpty) {
              _activeTrack = journey.availableTracks.first;
            }

            final allItems = journey.allPlanItems;
            final completedCount = allItems.where((i) => i.isCompleted).length;
            final progressPercent = allItems.isEmpty
                ? 0
                : ((completedCount / allItems.length) * 100).round();

            // Filtered drill list
            final filteredItems = _selectedPillar == PlanPreparationPillar.all
                ? allItems
                : allItems.where((i) => i.pillar == _selectedPillar).toList();

            return Column(
              children: [
                _buildPageHeading(),
                // 1. Sleek Compact Top Bar (University & Track + Horizon Switchers)
                RoadmapTopSelectorBar(
                  journey: journey,
                  activeUniversityKey: _activeUniversityKey,
                  activeTrack: _activeTrack,
                  formatTrackName: _formatTrackName,
                  onTapUniversity: () =>
                      _showUniversityTrackPicker(context, journey),
                  onTapHorizon: () => _showHorizonPicker(context, journey),
                  colorCardPlum: colorCardPlum,
                  colorPlumBorder: colorPlumBorder,
                  colorCream: colorCream,
                  colorTangerine: colorTangerine,
                  colorSunshine: colorSunshine,
                ),

                // 2. Gamified Quest HUD Bar (Streak, XP, Stars, Countdown, Progress)
                RoadmapGamifiedHudCard(
                  journey: journey,
                  allItems: allItems,
                  completedCount: completedCount,
                  progressPercent: progressPercent,
                  colorCardPlum: colorCardPlum,
                  colorPlumBorder: colorPlumBorder,
                  colorCream: colorCream,
                  colorTangerine: colorTangerine,
                  colorSunshine: colorSunshine,
                ),

                // 3. Compact Pillar Filter Tabs (All, Topic, Subject, Section, Mock)
                RoadmapPillarFilterBar(
                  allItems: allItems,
                  selectedPillar: _selectedPillar,
                  onSelectPillar: (pillar) =>
                      setState(() => _selectedPillar = pillar),
                  colorTangerine: colorTangerine,
                  colorCardPlum: colorCardPlum,
                  colorCream: colorCream,
                  colorPlumBorder: colorPlumBorder,
                ),

                // 4. The Hero: Gamified Milestone Journey Path Map
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Text(
                            'No milestones found for this filter.',
                            style: GoogleFonts.bricolageGrotesque(
                              color: colorCream.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 12, bottom: 90),
                          child: _buildGamifiedMilestoneMap(
                              context, filteredItems, journey),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your study plan',
                  style: GoogleFonts.bricolageGrotesque(
                    color: colorCream,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'A clear path to your admission goal',
                  style: GoogleFonts.bricolageGrotesque(
                    color: colorCream.withValues(alpha: 0.68),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorCardPlum,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorPlumBorder),
            ),
            child: Icon(Icons.route_rounded, color: colorSunshine, size: 19),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. TOP SELECTOR BAR (Compact, Glass Capsule Header)
  Widget _buildGamifiedMilestoneMap(
    BuildContext context,
    List<AdmissionPlanItem> items,
    AdmissionJourneyData journey,
  ) {
    // Find first incomplete item index as current level
    int currentIndex = items.indexWhere((i) => !i.isCompleted);
    if (currentIndex == -1 && items.isNotEmpty) {
      currentIndex = items.length; // all completed
    }

    const double stepHeight = 120.0;
    const double tokenRadius = 32.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final centerX = screenWidth / 2;

        // Calculate node center offsets
        final List<Offset> nodePositions = [];
        for (int i = 0; i < items.length; i++) {
          double dx = 0;
          dx = i.isEven ? -34.0 : 34.0;
          final y = i * stepHeight + stepHeight / 2;
          nodePositions.add(Offset(centerX + dx, y));
        }

        // Add summit trophy position at end
        final summitY = items.length * stepHeight + 70.0;
        final summitPosition = Offset(centerX, summitY);
        nodePositions.add(summitPosition);

        final totalHeight = summitY + 160.0;

        return SizedBox(
          width: screenWidth,
          height: totalHeight,
          child: Stack(
            children: [
              // 1. The Dynamic Spline Path Behind Nodes
              CustomPaint(
                size: Size(screenWidth, totalHeight),
                painter: MilestonePathPainter(
                  points: nodePositions,
                  completedIndex: currentIndex,
                  activeColorStart: colorTangerine,
                  activeColorEnd: colorSunshine,
                  trackColor: colorPlumBorder.withValues(alpha: 0.22),
                ),
              ),

              // 2. The Milestone Nodes and Interactive Attached Cards
              for (int i = 0; i < items.length; i++) ...[
                RoadmapMilestoneNode(
                  index: i + 1,
                  item: items[i],
                  nodeCenter: nodePositions[i],
                  isCompleted: items[i].isCompleted,
                  isCurrent: i == currentIndex,
                  isLocked: i > currentIndex,
                  screenWidth: screenWidth,
                  tokenRadius: tokenRadius,
                  pulseAnimation: _pulseController,
                  pillarColor: _getPillarColor(items[i].pillar),
                  pillarBadgeLabel: _getPillarBadgeLabel(items[i].pillar),
                  pillarIcon: _getPillarIcon(items[i].pillar),
                  colorTangerine: colorTangerine,
                  colorSunshine: colorSunshine,
                  colorCardPlum: colorCardPlum,
                  colorPlumBorder: colorPlumBorder,
                  colorCream: colorCream,
                  onTap: () => _showMilestoneDetailsModal(
                    context,
                    items[i],
                    i + 1,
                    i > currentIndex,
                    items[i].isCompleted,
                  ),
                ),
              ],

              // 3. The Grand Admission Gate Summit (At Path Completion)
              Positioned(
                top: summitY - 40,
                left: 16,
                right: 16,
                child: RoadmapSummitGate(
                  journey: journey,
                  completedCount: items.where((i) => i.isCompleted).length,
                  totalCount: items.length,
                  colorSunshine: colorSunshine,
                  colorTangerine: colorTangerine,
                  colorCream: colorCream,
                  onConquerFinal: (finalTest) =>
                      _launchExam(context, finalTest),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMilestoneDetailsModal(
    BuildContext context,
    AdmissionPlanItem item,
    int milestoneNumber,
    bool isLocked,
    bool isCompleted,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MilestoneDetailsSheet(
        item: item,
        milestoneNumber: milestoneNumber,
        isLocked: isLocked,
        isCompleted: isCompleted,
        pillarColor: _getPillarColor(item.pillar),
        pillarBadgeLabel: _getPillarBadgeLabel(item.pillar),
        colorCardPlum: colorCardPlum,
        colorPlumBorder: colorPlumBorder,
        colorCream: colorCream,
        colorTangerine: colorTangerine,
        colorSunshine: colorSunshine,
        onStart: () => _launchExam(context, item),
      ),
    );
  }

  // ===========================================================================
  // 6. MODAL: UNIVERSITY & FACULTY TRACK PICKER
  // ===========================================================================
  void _showUniversityTrackPicker(
      BuildContext context, AdmissionJourneyData journey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return UniversityTrackPickerSheet(
          journey: journey,
          activeUniversityKey: _activeUniversityKey,
          activeTrack: _activeTrack,
          onUniversitySelected: (uniId) {
            _service.setActiveUniversity(uniId);
            setState(() {
              _activeUniversityKey = uniId;
              _hasUserOverriddenHorizon = false;
            });
            _loadJourney();
          },
          onTrackSelected: (track) {
            setState(() => _activeTrack = track);
            _loadJourney();
          },
          formatTrackName: _formatTrackName,
        );
      },
    );
  }

  // ===========================================================================
  // 7. MODAL: PREPARATION TIMELINE HORIZON PICKER
  // ===========================================================================
  void _showHorizonPicker(BuildContext context, AdmissionJourneyData journey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return HorizonPickerSheet(
          journey: journey,
          selectedHorizon: _selectedHorizon,
          onHorizonSelected: (horizon) {
            setState(() {
              _selectedHorizon = horizon;
              _hasUserOverriddenHorizon = true;
            });
            _loadJourney();
          },
        );
      },
    );
  }
}
