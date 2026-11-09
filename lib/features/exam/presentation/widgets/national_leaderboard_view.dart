import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class NationalLeaderboardView extends StatelessWidget {
  final Future<List<Map<String, dynamic>>>? overallLeaderboardFuture;
  final AppColors colors;

  const NationalLeaderboardView({
    super.key,
    required this.overallLeaderboardFuture,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: overallLeaderboardFuture,
      builder: (context, snapshot) {
        final rankings = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

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
                      'National Overall Leaderboard',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Top candidates ranked by tests taken, score & accuracy',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accentEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'All Universities',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.accentEmerald,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (isLoading)
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else if (rankings.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  'No national test attempts recorded yet.',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rankings.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: colors.borderSubtle),
                  itemBuilder: (context, idx) {
                    final item = rankings[idx];
                    final rank = item['rank']?.toString() ?? '#${idx + 1}';
                    final name = item['name']?.toString() ?? 'Candidate';
                    final badge = item['badge']?.toString() ?? 'HSC Candidate';
                    final targetUni = item['targetUni']?.toString() ?? '';
                    final testsTaken = item['testsTaken'] ?? 0;
                    final scoreText = item['score']?.toString() ?? '';
                    final prepRating = item['prepRating'] ?? 0;

                    return ListTile(
                      leading: Text(rank, style: const TextStyle(fontSize: 18)),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (targetUni.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7A36)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                targetUni,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF7A36),
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '$badge • $testsTaken Tests • Rating: $prepRating',
                        style: TextStyle(
                            fontSize: 11, color: colors.textSecondary),
                      ),
                      trailing: Text(
                        scoreText,
                        style: TextStyle(
                          fontSize: 12,
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
