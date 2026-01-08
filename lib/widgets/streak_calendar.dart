import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_builder/models/habit.dart';

class StreakCalendar extends StatelessWidget {
  final Habit habit;
  const StreakCalendar({super.key, required this.habit});

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final today = _normalize(DateTime.now());
    final start = _normalize(habit.startDate);
    final end =
        _normalize(start.add(Duration(days: habit.targetDays - 1)));

    DayVisual? visualFor(DateTime date) {
      final d = _normalize(date);

      if (d.isBefore(start) || d.isAfter(end)) return null;

      final completed = habit.isCompletedOn(d);

      return DayVisual(
        completed: completed,
        missed: d.isBefore(today) && !completed,
        isToday: d == today,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar(
          firstDay: start,
          lastDay: end,
          focusedDay: today,
          availableGestures: AvailableGestures.horizontalSwipe,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) {
              final visual = visualFor(day);
              if (visual == null) return null;

              return _buildDayCell(
                day: day.day.toString(),
                visual: visual,
                cs: cs,
              );
            },
            todayBuilder: (context, day, _) {
              final visual = visualFor(day);
              if (visual == null) return null;

              return _buildDayCell(
                day: day.day.toString(),
                visual: visual,
                cs: cs,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _legendItem('Completed', Colors.green),
            _legendItem('Missed', Colors.redAccent),
            _legendItem(
              'Today',
              Colors.transparent,
              outline: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCell({
    required String day,
    required DayVisual visual,
    required ColorScheme cs,
  }) {
    Color fill = cs.surfaceVariant.withOpacity(0.3);
    Border? border;

    if (visual.completed) {
      fill = Colors.green;
    } else if (visual.missed) {
      fill = Colors.redAccent;
    }

    if (visual.isToday) {
      border = Border.all(color: Colors.blue, width: 2);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Text(
        day,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color, {Color? outline}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: outline != null
                ? Border.all(color: outline, width: 2)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class DayVisual {
  final bool completed;
  final bool missed;
  final bool isToday;

  const DayVisual({
    this.completed = false,
    this.missed = false,
    this.isToday = false,
  });
}
