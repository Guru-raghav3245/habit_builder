import 'package:flutter/material.dart';
import 'package:habit_builder/models/habit.dart';
import 'dart:math';

class MiniStreakGrid extends StatelessWidget {
  final Habit habit;

  const MiniStreakGrid({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final totalDays = habit.targetDays;
    // Calculate a square-ish grid (e.g., 25 days = 5 columns)
    final crossAxisCount = sqrt(totalDays).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      habit.startDate.year,
      habit.startDate.month,
      habit.startDate.day,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalDays,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        // dayDate represents which specific day of the journey this box is
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
          boxColor = Colors.grey.shade200; // Future day
        } else if (isCompleted) {
          boxColor = Colors.green; // Completed day
        } else if (dayDate.isAtSameMomentAs(today)) {
          boxColor = Colors.grey.shade300; // Today (not yet done)
        } else {
          boxColor = Colors.redAccent.withOpacity(0.6); // Missed past day
        }

        return Container(
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(3),
            border: dayDate.isAtSameMomentAs(today)
                ? Border.all(color: Colors.deepPurple, width: 1.5)
                : null,
          ),
        );
      },
    );
  }
}
