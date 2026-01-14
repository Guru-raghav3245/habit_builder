import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_builder/providers/habits_provider.dart';
import 'package:habit_builder/providers/settings_provider.dart';
import 'package:habit_builder/screens/add_edit_habit_screen.dart';
import 'package:habit_builder/screens/detail_screen.dart';
import 'package:habit_builder/screens/focus_timer_screen.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/widgets/mini_streak_grid.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _autoCheckTimer;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Automated Check Loop
    _autoCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _runAutomatedLogic(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutomatedLogic());
  }

  void _runAutomatedLogic() {
    if (!mounted || _isTransitioning) return;

    // 1. Refresh "Missed/Failed" logic in provider
    ref.read(habitsProvider.notifier).refreshHabitStatuses();

    // 2. Automated Redirection to Focus Mode
    final habitsState = ref.read(habitsProvider);
    habitsState.habits.whenData((habits) {
      for (final habit in habits) {
        bool isFailed = habitsState.failedHabitIds.contains(habit.id);
        if (habit.isActiveNow &&
            !habit.isCompletedToday &&
            !habit.isArchived &&
            !isFailed) {
          _isTransitioning = true;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FocusTimerScreen(habit: habit),
              fullscreenDialog: true,
            ),
          ).then((_) => _isTransitioning = false);
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(habitsProvider.notifier).loadHabits();
    }
  }

  void _showThemeSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ThemeSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsState = ref.watch(habitsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 180.0,
            pinned: true,
            backgroundColor: theme.colorScheme.primaryContainer,
            actions: [
              IconButton(
                icon: const Icon(Icons.palette_outlined, color: Colors.white),
                onPressed: () => _showThemeSettings(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'My Daily Habits',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: habitsState.habits.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (habits) {
            if (habits.isEmpty)
              return const Center(child: Text('No habits yet.'));
            final active = habits.where((h) => !h.isArchived).toList();
            final archived = habits.where((h) => h.isArchived).toList();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount:
                  (active.isNotEmpty ? active.length + 1 : 0) +
                  (archived.isNotEmpty ? archived.length + 1 : 0),
              itemBuilder: (context, index) {
                if (active.isNotEmpty && index == 0)
                  return const _SectionHeader(text: 'ACTIVE CHALLENGES');
                if (active.isNotEmpty && index <= active.length)
                  return HabitCard(habit: active[index - 1]);

                final arcIndex =
                    index - (active.isNotEmpty ? active.length + 1 : 0);
                if (archived.isNotEmpty && arcIndex == 0)
                  return const _SectionHeader(
                    text: 'COMPLETED JOURNEYS 🏆',
                    color: Colors.green,
                  );
                if (archived.isNotEmpty)
                  return HabitCard(
                    habit: archived[arcIndex - 1],
                    isArchived: true,
                  );

                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Habit'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final Color? color;
  const _SectionHeader({required this.text, this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: color ?? Colors.grey,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class HabitCard extends ConsumerWidget {
  final Habit habit;
  final bool isArchived;
  const HabitCard({super.key, required this.habit, this.isArchived = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habitsState = ref.watch(habitsProvider);
    final isFailed = habitsState.failedHabitIds.contains(habit.id);
    final isActive =
        habit.isActiveNow &&
        !isArchived &&
        !isFailed &&
        !habit.isCompletedToday;

    return Card(
      elevation: isActive ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isActive
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(habit: habit)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (habit.isCompletedToday)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 22,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: (habit.isCompletedToday || isFailed)
                            ? Colors.grey
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _InfoChip(
                    label: DateFormat('h:mm a').format(
                      DateTime(
                        2022,
                        1,
                        1,
                        habit.startTime.hour,
                        habit.startTime.minute,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: habit.completionPercentage,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 12),
              MiniStreakGrid(habit: habit),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.whatshot,
                    size: 16,
                    color: habit.currentStreak > 0
                        ? Colors.orange
                        : Colors.grey,
                  ),
                  Text(
                    ' ${habit.currentStreak}d streak',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: habit.currentStreak > 0
                          ? Colors.orange
                          : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (isActive)
                    const Text(
                      'STARTING NOW...',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  if (isFailed && !habit.isCompletedToday)
                    const Text(
                      'MISSED TODAY',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}

// Keep ThemeSettingsSheet as is...
class ThemeSettingsSheet extends ConsumerWidget {
  const ThemeSettingsSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Appearance", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text("Light"),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text("Dark"),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.settings),
                label: Text("System"),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (newSet) =>
                ref.read(settingsProvider.notifier).setThemeMode(newSet.first),
          ),
        ],
      ),
    );
  }
}
