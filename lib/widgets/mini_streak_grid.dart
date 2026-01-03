import 'package:flutter/material.dart';
import 'package:habit_builder/models/habit.dart';

class MiniStreakGrid extends StatelessWidget {
  final Habit habit;

  const MiniStreakGrid({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final totalDays = habit.targetDays;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      habit.startDate.year,
      habit.startDate.month,
      habit.startDate.day,
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Using Wrap instead of GridView to ensure it renders correctly regardless of count
    return Wrap(
      spacing: 4, // Horizontal space between boxes
      runSpacing: 4, // Vertical space between lines
      children: List.generate(totalDays, (index) {
        final dayDate = start.add(Duration(days: index));

        final isFuture = dayDate.isAfter(today);
        final isCompleted = habit.completedDates.any(
          (d) =>
              d.year == dayDate.year &&
              d.month == dayDate.month &&
              d.day == dayDate.day,
        );

        Color boxColor;
        if (isFuture) {
          boxColor = colorScheme.onSurface.withOpacity(0.12);
        } else if (isCompleted) {
          boxColor = Colors.green;
        } else if (dayDate.isAtSameMomentAs(today)) {
          boxColor = colorScheme.onSurface.withOpacity(0.25);
        } else {
          boxColor = Colors.redAccent.withOpacity(0.6);
        }

        return Container(
          width: 12, // Fixed size for reliability
          height: 12,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(2),
            border: dayDate.isAtSameMomentAs(today)
                ? Border.all(color: colorScheme.primary, width: 1.5)
                : null,
          ),
        );
      }),
    );
  }
}
