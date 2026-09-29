import 'package:flutter/material.dart';

import '../providers/quiz_provider.dart';

/// Displays the current score, progress (solved / total), and remaining attempts.
class ScoreHeader extends StatelessWidget {
  const ScoreHeader({super.key, required this.quiz});

  final QuizProvider quiz;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.stars,
              label: 'Score',
              value: '${quiz.score}',
              color: Colors.amber.shade700,
            ),
            _StatItem(
              icon: Icons.flag,
              label: 'Solved',
              value: '${quiz.solvedCount} / ${quiz.totalCountries}',
              color: Colors.blue,
            ),
            _StatItem(
              icon: Icons.favorite,
              label: 'Attempts',
              value: '${quiz.remainingAttempts}',
              color: quiz.remainingAttempts == 1 ? Colors.red : Colors.green,
            ),
            _StatItem(
              icon: Icons.local_fire_department,
              label: 'Streak',
              value: '${quiz.currentStreak}',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
