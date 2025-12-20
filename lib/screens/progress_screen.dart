// lib/screens/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/widgets/streak_calendar.dart';

class ProgressScreen extends StatelessWidget {
  final Habit habit;

  const ProgressScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final currentStreak = habit.currentStreak;
    final longestStreak = habit.longestStreak;

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
                  currentStreak,
                  Icons.whatshot,
                  Colors.orange.shade800,
                  Colors.orange.shade50,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStreakCard(
                  context,
                  'Best streak',
                  longestStreak,
                  Icons.emoji_events,
                  Colors.green.shade800,
                  Colors.green.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Completion History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[800],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreakCalendar(habit: habit),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              currentStreak == 0
                  ? 'Today is the perfect day to start! 💪'
                  : 'Keep it up! Consistency is key. 🔥',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, String title, int value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}