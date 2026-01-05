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
  bool _isBinOpen = false; // State to control the Trash Bin mini-screen

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
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
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ThemeSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 180.0,
                  pinned: true,
                  stretch: true,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  // Moved Palette Icon to Top-Left
                  leading: IconButton(
                    icon: const Icon(Icons.palette_outlined),
                    onPressed: () => _showThemeSettings(context),
                  ),
                  // Bin Icon with Badge on Top-Right
                  actions: [_buildBinIcon(habitsAsync)],
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
            body: habitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (habits) {
                // Filter out deleted habits from main list
                final activeHabits = habits
                    .where((h) => !h.isArchived && !h.isDeleted)
                    .toList();
                final archivedHabits = habits
                    .where((h) => h.isArchived && !h.isDeleted)
                    .toList();

                if (activeHabits.isEmpty && archivedHabits.isEmpty)
                  return const _EmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount:
                      (activeHabits.isNotEmpty ? activeHabits.length + 1 : 0) +
                      (archivedHabits.isNotEmpty
                          ? archivedHabits.length + 1
                          : 0),
                  itemBuilder: (context, index) {
                    if (activeHabits.isNotEmpty) {
                      if (index == 0)
                        return const _SectionHeader(title: 'ACTIVE CHALLENGES');
                      if (index <= activeHabits.length) {
                        return HabitCard(habit: activeHabits[index - 1]);
                      }
                    }

                    final archivedStartIndex = activeHabits.isNotEmpty
                        ? activeHabits.length + 1
                        : 0;
                    final relativeArchivedIndex = index - archivedStartIndex;

                    if (archivedHabits.isNotEmpty) {
                      if (relativeArchivedIndex == 0) {
                        return const _SectionHeader(
                          title: 'COMPLETED JOURNEYS 🏆',
                          color: Colors.green,
                          topPadding: 24,
                        );
                      }
                      return HabitCard(
                        habit: archivedHabits[relativeArchivedIndex - 1],
                        isArchived: true,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          // Trash Bin Mini-Screen Overlay
          if (_isBinOpen) _buildBinOverlay(context, habitsAsync),
        ],
      ),
      // Hide FAB when Bin is open to prevent overlap
      floatingActionButton: _isBinOpen ? null : _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBinIcon(AsyncValue<List<Habit>> habitsAsync) {
    // Count only soft-deleted habits
    final deletedCount =
        habitsAsync.value?.where((h) => h.isDeleted).length ?? 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => setState(() => _isBinOpen = true),
        ),
        if (deletedCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$deletedCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBinOverlay(
    BuildContext context,
    AsyncValue<List<Habit>> habitsAsync,
  ) {
    final deletedHabits =
        habitsAsync.value?.where((h) => h.isDeleted).toList() ?? [];
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(
              child: Column(
                children: [
                  AppBar(
                    title: const Text('Trash Bin'),
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _isBinOpen = false),
                    ),
                  ),
                  Expanded(
                    child: deletedHabits.isEmpty
                        ? const Center(child: Text("Your bin is empty"))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: deletedHabits.length,
                            itemBuilder: (context, i) {
                              final h = deletedHabits[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                title: Text(
                                  h.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${h.completedDates.length} completions preserved',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.restore,
                                        color: Colors.green,
                                      ),
                                      tooltip: 'Restore Habit',
                                      onPressed: () => ref
                                          .read(habitsProvider.notifier)
                                          .restoreHabit(h.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_forever,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'Delete Permanently',
                                      onPressed: () => ref
                                          .read(habitsProvider.notifier)
                                          .permanentlyDeleteHabit(h.id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
  final String title;
  final Color? color;
  final double topPadding;

  const _SectionHeader({required this.title, this.color, this.topPadding = 8});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color ?? Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class HabitCard extends ConsumerWidget {
  final Habit habit;
  final bool isArchived;

  const HabitCard({super.key, required this.habit, this.isArchived = false});

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat('h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDoneToday = habit.isCompletedToday;
    final isActive = habit.isActiveNow && !isArchived;

    return Card(
      elevation: isActive ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isActive
            ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
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
                        color: isDoneToday
                            ? Colors.grey
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildInfoChip(
                    context,
                    isDoneToday ? Icons.task_alt : Icons.access_time,
                    _formatTime(habit.startTime),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCompactProgress(context, habit),
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
                  if (isActive && !isDoneToday)
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FocusTimerScreen(habit: habit),
                          fullscreenDialog: true,
                        ),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('FOCUS'),
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(habitsProvider.notifier)
                        .toggleDoneToday(habit.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDoneToday
                          ? Colors.orange
                          : theme.colorScheme.secondaryContainer,
                      foregroundColor: isDoneToday
                          ? Colors.white
                          : theme.colorScheme.onSecondaryContainer,
                      elevation: 0,
                    ),
                    child: Text(isDoneToday ? 'UNDO' : 'DONE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactProgress(BuildContext context, Habit habit) {
    final theme = Theme.of(context);
    return Column(
      children: [
        LinearProgressIndicator(
          value: habit.completionPercentage,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          color: theme.colorScheme.primary,
          minHeight: 4,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${habit.targetDays} day challenge',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11),
                children: [
                  TextSpan(
                    text: '${habit.completedDates.length}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${habit.daysElapsed}',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('No habits yet. Start your journey!'));
}

class ThemeSettingsSheet extends ConsumerWidget {
  const ThemeSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colors = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.red,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 24),
          Text("Accent Color", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final color = colors[index];
                final isSelected = settings.seedColor.value == color.value;
                return GestureDetector(
                  onTap: () =>
                      ref.read(settingsProvider.notifier).setSeedColor(color),
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
