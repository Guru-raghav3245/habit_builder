import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/services/habit_storage.dart';
import 'package:habit_builder/services/notification_service.dart';

class HabitsState {
  final AsyncValue<List<Habit>> habits;
  final Set<String> failedHabitIds;

  HabitsState({required this.habits, this.failedHabitIds = const {}});

  HabitsState copyWith({
    AsyncValue<List<Habit>>? habits,
    Set<String>? failedHabitIds,
  }) {
    return HabitsState(
      habits: habits ?? this.habits,
      failedHabitIds: failedHabitIds ?? this.failedHabitIds,
    );
  }
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, HabitsState>(
  (ref) => HabitsNotifier(),
);

class HabitsNotifier extends StateNotifier<HabitsState> {
  HabitsNotifier() : super(HabitsState(habits: const AsyncValue.loading())) {
    loadHabits();
  }

  void _sortAndSet(List<Habit> habits) {
    habits.sort((a, b) {
      if (a.startTime.hour != b.startTime.hour)
        return a.startTime.hour.compareTo(b.startTime.hour);
      return a.startTime.minute.compareTo(b.startTime.minute);
    });
    state = state.copyWith(habits: AsyncValue.data(habits));
  }

  Future<void> loadHabits() async {
    try {
      final habits = await HabitStorage.loadHabits();
      _sortAndSet(habits);
      refreshHabitStatuses();
    } catch (e, s) {
      state = state.copyWith(habits: AsyncValue.error(e, s));
    }
  }

  void refreshHabitStatuses() {
    state.habits.whenData((habits) {
      final currentFailed = <String>{...state.failedHabitIds};
      bool changed = false;

      for (final habit in habits) {
        // Automatically mark as failed if the time window passed and it wasn't done
        if (habit.hasWindowPassedToday && !habit.isCompletedToday) {
          if (!currentFailed.contains(habit.id)) {
            currentFailed.add(habit.id);
            changed = true;
          }
        }
      }
      if (changed) {
        state = state.copyWith(failedHabitIds: currentFailed);
      }
    });
  }

  void markAsFailed(String id) {
    state = state.copyWith(failedHabitIds: {...state.failedHabitIds, id});
  }

  Future<void> markAsDone(String id) async {
    final list = state.habits.value ?? [];
    final i = list.indexWhere((h) => h.id == id);
    if (i == -1) return;

    final habit = list[i];
    if (habit.isCompletedToday) return;

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final updated = list
        .map(
          (h) => h.id == id
              ? h.copyWith(completedDates: [...h.completedDates, today])
              : h,
        )
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
  }) async {
    final list = state.habits.value ?? [];
    final habit = Habit(
      id: const Uuid().v4(),
      name: name,
      startTime: startTime,
      durationMinutes: durationMinutes,
      startDate: DateTime.now(),
      targetDays: targetDays,
    );
    final updated = [...list, habit];
    await HabitStorage.saveHabits(updated);
    _sortAndSet(updated);
    await NotificationService.scheduleDailyReminder(habit);
  }

  Future<void> updateHabit(Habit h) async {
    final list = state.habits.value ?? [];
    final updated = list.map((item) => item.id == h.id ? h : item).toList();
    await HabitStorage.saveHabits(updated);
    _sortAndSet(updated);
    await NotificationService.scheduleDailyReminder(h);
  }

  Future<void> deleteHabit(String id) async {
    final list = state.habits.value ?? [];
    final updated = list.where((h) => h.id != id).toList();
    await HabitStorage.saveHabits(updated);
    _sortAndSet(updated);
    await NotificationService.cancelAllHabitReminders(id);
  }
}
