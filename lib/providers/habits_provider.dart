import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/services/habit_storage.dart';
import 'package:habit_builder/services/notification_service.dart';
import 'package:flutter_riverpod/legacy.dart';

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, AsyncValue<List<Habit>>>(
      (ref) => HabitsNotifier(),
    );

class HabitsNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  HabitsNotifier() : super(const AsyncValue.loading()) {
    loadHabits();
  }

  void _sortAndSet(List<Habit> habits) {
    habits.sort((a, b) {
      if (a.startTime.hour != b.startTime.hour)
        return a.startTime.hour.compareTo(b.startTime.hour);
      return a.startTime.minute.compareTo(b.startTime.minute);
    });
    state = AsyncValue.data(habits);
  }

  Future<void> loadHabits() async {
    try {
      final habits = await HabitStorage.loadHabits();
      _sortAndSet(habits);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  /// Strictly marks a habit as completed for today.
  /// This cannot be undone by the user manually.
  Future<void> markAsDone(String id) async {
    final list = state.value ?? [];
    final i = list.indexWhere((h) => h.id == id);
    if (i == -1) return;

    final habit = list[i];
    if (habit.isCompletedToday) return;

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    List<DateTime> dates = List.from(habit.completedDates);
    dates.add(today);

    final updated = list
        .map((h) => h.id == id ? h.copyWith(completedDates: dates) : h)
        .toList();

    await HabitStorage.saveHabits(updated);
    _sortAndSet(updated);

    await NotificationService.cancelLateReminder(id);
  }

  Future<void> addHabit({
    required String name,
    required TimeOfDay startTime,
    required int durationMinutes,
    required int targetDays,
    bool reminderEnabled = true,
  }) async {
    final list = state.value ?? [];
    final habit = Habit(
      id: const Uuid().v4(),
      name: name,
      startTime: startTime,
      durationMinutes: durationMinutes,
      reminderEnabled: reminderEnabled,
      startDate: DateTime.now(),
      targetDays: targetDays,
    );

    final updated = [...list, habit];
    await HabitStorage.saveHabits(updated);
    _sortAndSet(updated);

    await NotificationService.scheduleDailyReminder(habit);
  }

  Future<void> updateHabit(Habit h) async {
    final list = state.value ?? [];
    final updated = list.map((item) => item.id == h.id ? h : item).toList();
    await HabitStorage.saveHabits(updated);
    _sortAndSet(updated);

    await NotificationService.scheduleDailyReminder(h);
  }

  Future<void> deleteHabit(String id) async {
    final list = state.value ?? [];
    final updated = list.where((h) => h.id != id).toList();
    await HabitStorage.saveHabits(updated);
    _sortAndSet(updated);

    await NotificationService.cancelAllHabitReminders(id);
  }
}
