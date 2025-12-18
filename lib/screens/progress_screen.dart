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
          // Streak Summary Cards
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.whatshot, size: 48, color: Colors.orange[700]),
                        const SizedBox(height: 12),
                        Text(
                          '$currentStreak',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                        Text(
                          'Current streak',
                          style: TextStyle(fontSize: 16, color: Colors.orange[700]),
                        ),
                        Text(
                          'day${currentStreak == 1 ? "" : "s"}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.emoji_events, size: 48, color: Colors.green[700]),
                        const SizedBox(height: 12),
                        Text(
                          '$longestStreak',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                        Text(
                          'Best streak',
                          style: TextStyle(fontSize: 16, color: Colors.green[700]),
                        ),
                        Text(
                          'day${longestStreak == 1 ? "" : "s"}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Calendar Title
          Text(
            'Completion History',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[800],
                ),
          ),
          const SizedBox(height: 16),

          // Streak Calendar
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StreakCalendar(habit: habit),
            ),
          ),
          const SizedBox(height: 24),

          // Motivational note
          Center(
            child: Text(
              currentStreak == 0
                  ? 'You haven\'t started yet. Today is the perfect day to begin! 💪'
                  : 'Keep going! Every day counts. 🔥',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}