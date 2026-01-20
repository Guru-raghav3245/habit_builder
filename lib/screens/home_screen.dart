import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_builder/providers/habits_provider.dart';
import 'package:habit_builder/providers/settings_provider.dart'; // Added import
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutomatedLogic());

    // Performance Optimization: Increased from 5s to 30s to reduce main thread load
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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

    ref.read(habitsProvider.notifier).refreshHabitStatuses();

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
          ).then((_) {
            _isTransitioning = false;
          });
          break;
        }
      }
    });
  }

  // New method to show the theme settings modal
  void _showThemeSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ThemeSettingsModal(),
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
              actions: [
                // New Theme Button
                IconButton(
                  icon: const Icon(Icons.palette_rounded),
                  tooltip: 'Customize Theme',
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
            if (habits.isEmpty) {
              return const Center(child: Text('No habits yet.'));
            }

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

class HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isArchived;
  const HabitCard({super.key, required this.habit, this.isArchived = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDoneToday = habit.isCompletedToday;
    final isFailed = habit.isFailedToday;
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
                  _buildTimeChip(context, habit),
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

  Widget _buildTimeChip(BuildContext context, Habit habit) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      DateFormat('h:mm a').format(
        DateTime(2022, 1, 1, habit.startTime.hour, habit.startTime.minute),
      ),
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

// New Modal Widget for Theme Settings
class _ThemeSettingsModal extends ConsumerWidget {
  const _ThemeSettingsModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    // List of available colors
    final List<Color> colors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lime,
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
      Colors.pink,
      Colors.blueGrey,
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Customize Look',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Appearance',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Toggle Buttons for Light/Dark/System
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              ref
                  .read(settingsProvider.notifier)
                  .setThemeMode(newSelection.first);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Accent Color',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Color Selection Wrap
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) {
              final isSelected = settings.seedColor.value == color.value;
              return GestureDetector(
                onTap: () {
                  ref.read(settingsProvider.notifier).setSeedColor(color);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
