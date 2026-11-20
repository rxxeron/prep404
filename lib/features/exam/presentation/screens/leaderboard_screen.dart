import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/resilient_api_client.dart';
import '../../../../core/repositories/exam_repository.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/university_roadmap_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/daily_exam_university_filter.dart';
import '../widgets/national_leaderboard_view.dart';
import '../widgets/university_leaderboard_view.dart';

/// Dedicated Leaderboard Tab — Live University & National Overall Standings
class LeaderboardScreen extends StatefulWidget {
  final String? userId;
  final List<String> targetUniversityKeys;

  const LeaderboardScreen({
    super.key,
    this.userId,
    this.targetUniversityKeys = const [],
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final UniversityRoadmapService _roadmapService = UniversityRoadmapService();
  final ExamRepository _examRepository = ExamRepository();

  int _modeIndex = 0; // 0 = University Today, 1 = National Overall
  late String _activeUniKey;
  Future<Map<String, dynamic>>? _uniLeaderboardFuture;
  Future<List<Map<String, dynamic>>>? _overallLeaderboardFuture;

  @override
  void initState() {
    super.initState();
    _activeUniKey = _roadmapService.activeUniversityKey.value;
    _roadmapService.activeUniversityKey.addListener(_onGlobalUniChanged);
    _loadData();
  }

  @override
  void dispose() {
    _roadmapService.activeUniversityKey.removeListener(_onGlobalUniChanged);
    super.dispose();
  }

  void _onGlobalUniChanged() {
    final next = _roadmapService.activeUniversityKey.value;
    if (next != _activeUniKey && mounted) {
      setState(() {
        _activeUniKey = next;
      });
      _loadData();
    }
  }

  Future<Map<String, dynamic>> _fetchUniversityStandings(String uniCode) async {
    try {
      final res = await ResilientApiClient().getWithFallback(
        '/api/v1/daily-test/today?university=${uniCode.toUpperCase()}',
        headers: {
          if (SupabaseService().currentAccessToken != null)
            'Authorization': 'Bearer ${SupabaseService().currentAccessToken}',
        },
        timeout: const Duration(seconds: 4),
      );
      if (res != null && res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) return data;
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> _loadData() async {
    final uniFuture = _fetchUniversityStandings(_activeUniKey);
    final overallFuture = _examRepository.fetchOverallLeaderboard();
    if (mounted) {
      setState(() {
        _uniLeaderboardFuture = uniFuture;
        _overallLeaderboardFuture = overallFuture;
      });
    }
    await Future.wait([uniFuture, overallFuture]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final roadmaps = _roadmapService.allRoadmaps;
    final activeUni = _roadmapService.getRoadmap(_activeUniKey);

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: colors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Leaderboard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Verified university & national admission rankings',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded,
                        size: 20, color: colors.textMuted),
                    tooltip: 'Refresh rankings',
                    onPressed: _loadData,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Mode Toggle (University vs National)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTogglePill(
                        colors: colors,
                        label: '${activeUni.shortCode} Today',
                        icon: Icons.account_balance_rounded,
                        isSelected: _modeIndex == 0,
                        onTap: () => setState(() => _modeIndex = 0),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildTogglePill(
                        colors: colors,
                        label: 'National Overall',
                        icon: Icons.public_rounded,
                        isSelected: _modeIndex == 1,
                        onTap: () => setState(() => _modeIndex = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_modeIndex == 0) ...[
                DailyExamUniversityFilter(
                  roadmaps: roadmaps,
                  activeKey: _activeUniKey,
                  onSelectUniversity: (key) {
                    setState(() => _activeUniKey = key);
                    _roadmapService.activeUniversityKey.value = key;
                    _loadData();
                  },
                ),
                const SizedBox(height: 14),
                UniversityLeaderboardView(
                  leaderboardFuture: _uniLeaderboardFuture,
                  activeUni: activeUni,
                  colors: colors,
                ),
              ] else ...[
                NationalLeaderboardView(
                  overallLeaderboardFuture: _overallLeaderboardFuture,
                  colors: colors,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTogglePill({
    required AppColors colors,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
