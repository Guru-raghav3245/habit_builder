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
    final colorScheme = Theme.of(context).colorScheme;

    // Constants for layout
    const double boxSize = 12.0;
    const double spacing = 4.0;
    const int itemsPerRow = 7;

    // Calculate the width required for exactly 7 boxes (7 boxes + 6 spacings)
    const double gridWidth =
        (boxSize * itemsPerRow) + (spacing * (itemsPerRow - 1));

    return RepaintBoundary(
      child: SizedBox(
        width: gridWidth,
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(totalDays, (index) {
            final dayDate = start.add(Duration(days: index));
            final isToday = dayDate.isAtSameMomentAs(today);

            Color boxColor;
            if (dayDate.isAfter(today)) {
              boxColor = colorScheme.onSurface.withOpacity(0.12);
            } else if (habit.isCompletedOn(dayDate)) {
              boxColor = Colors.green;
            } else if (habit.isMissedOn(dayDate)) {
              boxColor = Colors.redAccent.withOpacity(0.6);
            } else if (isToday) {
              boxColor = colorScheme.onSurface.withOpacity(0.25);
            } else {
              boxColor = colorScheme.onSurface.withOpacity(0.12);
            }

            return Container(
              width: boxSize,
              height: boxSize,
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
      ),
    );
  }
}
