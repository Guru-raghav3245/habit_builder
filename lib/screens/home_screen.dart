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
              expandedHeight: 120.0,
              pinned: true,
              stretch: true,
              scrolledUnderElevation: 0,
              backgroundColor: theme.colorScheme.primaryContainer,
              actions: [
                IconButton(
                  icon: const Icon(Icons.palette_rounded),
                  tooltip: 'Customize Theme',
                  onPressed: () => _showThemeSettings(context),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(bottom: 16),
                title: const Text(
                  'My Habits',
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
        fontSize: 12,
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

    // Determine status text/color
    String statusText = '';
    Color statusColor = Colors.grey;

    if (isActive) {
      statusText = 'NOW';
      statusColor = Colors.green;
    } else if (isFailed && !isDoneToday) {
      statusText = 'MISSED';
      statusColor = Colors.redAccent;
    } else if (isDoneToday) {
      statusText = 'DONE';
      statusColor = theme.colorScheme.primary;
    }

    return Card(
      elevation: isActive ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.5)
              : theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(habit: habit)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('h:mm a').format(
                                DateTime(
                                  2022,
                                  1,
                                  1,
                                  habit.startTime.hour,
                                  habit.startTime.minute,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (statusText.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.outlineVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Streak Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${habit.currentStreak}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weekly Grid Visualizer
              _buildHistoryGrid(context, habit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryGrid(BuildContext context, Habit habit) {
    final theme = Theme.of(context);
    final totalDays = habit.targetDays;
    final startDate = DateTime(
      habit.startDate.year,
      habit.startDate.month,
      habit.startDate.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Widget> rows = [];
    int currentDayIndex = 0;

    // Build rows until we cover all target days
    while (currentDayIndex < totalDays) {
      List<Widget> weekWidgets = [];

      // Build 7 days (or fewer for the last week)
      for (int i = 0; i < 7; i++) {
        if (currentDayIndex >= totalDays) {
          // Fill remaining space in the last row to maintain alignment
          weekWidgets.add(const Expanded(child: SizedBox()));
        } else {
          final date = startDate.add(Duration(days: currentDayIndex));
          final isToday = date.isAtSameMomentAs(today);

          Color color = theme.colorScheme.surfaceVariant.withOpacity(
            0.3,
          ); // Future/Default

          if (habit.isCompletedOn(date)) {
            color = Colors.green;
          } else if (date.isBefore(today)) {
            if (habit.isMissedOn(date)) {
              color = Colors.redAccent.withOpacity(0.5);
            }
          } else if (isToday) {
            // Today highlights
            color = theme.colorScheme.primary.withOpacity(0.15);
          }

          weekWidgets.add(
            Expanded(
              child: Container(
                height: 10, // Slim rectangle height
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  border: isToday && !habit.isCompletedOn(date)
                      ? Border.all(color: theme.colorScheme.primary, width: 1)
                      : null,
                ),
              ),
            ),
          );
        }
        currentDayIndex++;
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: weekWidgets),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _ThemeSettingsModal extends ConsumerWidget {
  const _ThemeSettingsModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    // Warm to Cold + Neutrals
    final List<Color> colors = [
      Colors.red,
      Colors.deepOrange,
      Colors.orange,
      Colors.amber,
      Colors.yellow,
      Colors.lime,
      Colors.lightGreen,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.lightBlue,
      Colors.blue,
      Colors.indigo,
      Colors.deepPurple,
      Colors.purple,
      Colors.pink,
      Colors.white,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
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
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Appearance',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SegmentedButton<ThemeMode>(
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
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Accent Color',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling list
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: colors.map((color) {
                final isSelected = settings.seedColor.value == color.value;
                final isBright =
                    ThemeData.estimateBrightnessForColor(color) ==
                    Brightness.light;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(settingsProvider.notifier).setSeedColor(color);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withOpacity(0.2),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: isBright ? Colors.black : Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
