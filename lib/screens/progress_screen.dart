import 'package:flutter/material.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/widgets/streak_calendar.dart';

class ProgressScreen extends StatelessWidget {
  final Habit habit;
  const ProgressScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  context,
                  'Current streak',
                  habit.currentStreak,
                  Icons.whatshot,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStreakCard(
                  context,
                  'Best streak',
                  habit.longestStreak,
                  Icons.emoji_events,
                  theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'History',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreakCalendar(habit: habit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(
    BuildContext context,
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
