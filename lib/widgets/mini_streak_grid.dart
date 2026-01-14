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

    return RepaintBoundary(
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(totalDays, (index) {
          final dayDate = start.add(Duration(days: index));
          final isFuture = dayDate.isAfter(today);
          final isCompleted = habit.isCompletedOn(dayDate);
          final isMissed = habit.isMissedOn(
            dayDate,
          ); // Uses new logic including failed IDs

          Color boxColor;
          if (isFuture) {
            boxColor = colorScheme.onSurface.withOpacity(0.12);
          } else if (isCompleted) {
            boxColor = Colors.green;
          } else if (isMissed) {
            boxColor = Colors.redAccent.withOpacity(
              0.6,
            ); // Will now trigger for "Give Ups" today
          } else if (dayDate.isAtSameMomentAs(today)) {
            boxColor = colorScheme.onSurface.withOpacity(0.25);
          } else {
            boxColor = colorScheme.onSurface.withOpacity(0.12);
          }

          return Container(
            key: ValueKey(dayDate.toString()),
            width: 12,
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
      ),
    );
  }
}
