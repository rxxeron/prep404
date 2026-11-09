import 'package:flutter/material.dart';

/// Clean countdown timer pill widget with low-time warning indicator
class ExamTimerPill extends StatelessWidget {
  final int remainingSeconds;

  const ExamTimerPill({
    super.key,
    required this.remainingSeconds,
  });

  String _formatTimer(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = remainingSeconds < 180;
    final primaryColor = isUrgent ? const Color(0xFFEF4444) : const Color(0xFFFF7A36);
    final bgColor = isUrgent
        ? const Color(0xFFEF4444).withValues(alpha: 0.2)
        : const Color(0xFFFF7A36).withValues(alpha: 0.2);
    final borderColor = isUrgent ? const Color(0xFFEF4444) : const Color(0xFFFF7A36);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            _formatTimer(remainingSeconds),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
