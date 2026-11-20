import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';

/// Prep404 5-Tab Navigation Bar
class PrepBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const PrepBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final strings = AppStrings.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final navHeight = 72 + math.max(0.0, textScale - 1) * 40;

    final items = [
      NavItemData(
        label: strings.navHome,
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
      ),
      NavItemData(
        label: strings.navPlan,
        activeIcon: Icons.trending_up_rounded,
        inactiveIcon: Icons.trending_up_outlined,
      ),
      NavItemData(
        label: strings.navQuestionBank,
        activeIcon: Icons.inventory_2_rounded,
        inactiveIcon: Icons.inventory_2_outlined,
      ),
      NavItemData(
        label: strings.navDailyTest,
        activeIcon: Icons.edit_note_rounded,
        inactiveIcon: Icons.edit_note_outlined,
      ),
      NavItemData(
        label: strings.navHistory,
        activeIcon: Icons.history_rounded,
        inactiveIcon: Icons.history_outlined,
      ),
      const NavItemData(
        label: 'Ranks',
        activeIcon: Icons.emoji_events_rounded,
        inactiveIcon: Icons.emoji_events_outlined,
      ),
    ];

    return Container(
      height: navHeight,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.borderSubtle, width: 1.2)),
        boxShadow: colors.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (idx) {
          final isSelected = selectedIndex == idx;
          final item = items[idx];
          void handleTap() {
            HapticFeedback.lightImpact();
            onItemSelected(idx);
          }

          return Expanded(
            child: Semantics(
              container: true,
              button: true,
              selected: isSelected,
              label: item.label,
              onTap: handleTap,
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: handleTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primaryLight
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.inactiveIcon,
                            color: isSelected
                                ? colors.tangerine
                                : const Color(0xFF6B7280),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? colors.tangerine
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class NavItemData {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const NavItemData({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}
