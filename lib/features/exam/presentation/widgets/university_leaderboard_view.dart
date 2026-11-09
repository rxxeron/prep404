import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/university_roadmap_service.dart';

class UniversityLeaderboardView extends StatelessWidget {
  final Future<Map<String, dynamic>>? leaderboardFuture;
  final UniversityRoadmapData activeUni;
  final AppColors colors;

  const UniversityLeaderboardView({
    super.key,
    required this.leaderboardFuture,
    required this.activeUni,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: leaderboardFuture,
      builder: (context, snapshot) {
        final isLoaded = snapshot.hasData && snapshot.data != null;
        final testData = snapshot.data;

        final userRank = isLoaded
            ? (testData!['userRank']?.toString() ?? 'Unranked (Take 1 test)')
            : 'Unranked (Take 1 test)';

        final rawLeaderboard =
            isLoaded ? (testData!['leaderboard'] as List? ?? []) : [];

        final leaderboardItems = rawLeaderboard.isNotEmpty
            ? rawLeaderboard.map((item) {
                final m = item as Map<String, dynamic>;
                return UniversityLeaderboardEntry(
                  rank: m['rank']?.toString() ?? '#',
                  name: m['name']?.toString() ?? 'Candidate',
                  score: m['score']?.toString() ?? '0.0',
                  badge:
                      m['badge']?.toString() ?? '${activeUni.shortCode} Batch',
                );
              }).toList()
            : <UniversityLeaderboardEntry>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${activeUni.shortCode} Today\'s Live Leaderboard',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Live participant scores for ${activeUni.shortCode}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFF3E6)),
                  ),
                  child: Text(
                    userRank,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF542747),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            leaderboardItems.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 28),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                            !isLoaded
                                ? Icons.cloud_off_rounded
                                : Icons.emoji_events_outlined,
                            size: 40,
                            color:
                                colors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          !isLoaded
                              ? 'Leaderboard Offline'
                              : 'No Submissions Yet Today',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !isLoaded
                              ? 'Start the backend server on port 4040 to sync live participant scores and ranks.'
                              : 'Be the first ${activeUni.shortCode} candidate to take today\'s exam and claim the #1 spot!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: leaderboardItems.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: colors.borderSubtle),
                      itemBuilder: (context, idx) {
                        final item = leaderboardItems[idx];
                        return ListTile(
                          leading: Text(item.rank,
                              style: const TextStyle(fontSize: 18)),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            item.badge,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                          trailing: Text(
                            item.score,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        );
      },
    );
  }
}
