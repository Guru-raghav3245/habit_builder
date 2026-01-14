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

    // Run automated logic immediately on launch
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutomatedLogic());

    // Check every 5 seconds for status changes and auto-redirects
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _runAutomatedLogic();
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
      _runAutomatedLogic();
    }
  }

  void _runAutomatedLogic() {
    if (_isTransitioning || !mounted) return;

    // 1. Refresh "Missed/Failed" logic in provider
    ref.read(habitsProvider.notifier).refreshHabitStatuses();

    // 2. Automated Redirection to Focus Mode
    final habitsState = ref.read(habitsProvider);
    habitsState.habits.whenData((habits) {
      for (final habit in habits) {
        // Prevent re-opening if already failed or completed today
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
          ).then((_) {
            _isTransitioning = false;
          });
          break;
        }
      }
    });
  }

  void _showThemeSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              pinned: true,
              stretch: true,
              scrolledUnderElevation: 0,
              backgroundColor: theme.colorScheme.primaryContainer,
              surfaceTintColor: Colors.transparent,
              foregroundColor: theme.colorScheme.onPrimary,
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
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: habitsState.habits.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (habits) {
            if (habits.isEmpty) return const _EmptyState();

            final activeHabits = habits.where((h) => !h.isArchived).toList();
            final archivedHabits = habits.where((h) => h.isArchived).toList();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount:
                  (activeHabits.isNotEmpty ? activeHabits.length + 1 : 0) +
                  (archivedHabits.isNotEmpty ? archivedHabits.length + 1 : 0),
              itemBuilder: (context, index) {
                if (activeHabits.isNotEmpty) {
                  if (index == 0) {
                    return const _SectionHeader(text: 'ACTIVE CHALLENGES');
                  }
                  if (index <= activeHabits.length) {
                    final habit = activeHabits[index - 1];
                    // Inject the failure state so widgets can render red boxes
                    final isFailed = habitsState.failedHabitIds.contains(
                      habit.id,
                    );
                    return HabitCard(
                      habit: habit.copyWith(isFailedToday: isFailed),
                    );
                  }
                }

                final archivedStartIndex = activeHabits.isNotEmpty
                    ? activeHabits.length + 1
                    : 0;
                final relativeArchivedIndex = index - archivedStartIndex;

                if (archivedHabits.isNotEmpty) {
                  if (relativeArchivedIndex == 0) {
                    return const _SectionHeader(
                      text: 'COMPLETED JOURNEYS 🏆',
                      color: Colors.green,
                    );
                  }
                  final habit = archivedHabits[relativeArchivedIndex - 1];
                  return HabitCard(habit: habit, isArchived: true);
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFab(BuildContext context) => FloatingActionButton.extended(
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
    ),
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
    icon: const Icon(Icons.add),
    label: const Text('Add Habit'),
  );
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
    final isDoneToday = habit.isCompletedToday;
    final isFailed = habit.isFailedToday; // Now coming from injected copyWith
    final isActive =
        habit.isActiveNow && !isArchived && !isFailed && !isDoneToday;

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
                  if (isDoneToday)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 22,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDoneToday || isFailed
                            ? Colors.grey
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildInfoChip(
                    context,
                    DateFormat('h:mm a').format(
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
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                color: theme.colorScheme.primary,
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
                  const SizedBox(width: 4),
                  Text(
                    '${habit.currentStreak}d streak',
                    style: TextStyle(
                      fontSize: 13,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.redAccent,
                        letterSpacing: 1.2,
                      ),
                    ),
                  if (isFailed && !isDoneToday)
                    const Text(
                      'MISSED TODAY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
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

  Widget _buildInfoChip(BuildContext context, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('No habits yet.'));
}

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
