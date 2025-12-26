import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_builder/providers/habits_provider.dart';
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
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.deepPurple,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'My Daily Habits',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurple.shade800],
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
            if (habits.isEmpty) return _buildEmptyState();

            final activeHabits = habits.where((h) => !h.isArchived).toList();
            final archivedHabits = habits.where((h) => h.isArchived).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                if (activeHabits.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'ACTIVE CHALLENGES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  ...activeHabits.map((h) => _buildHabitCard(context, h)),
                ],
                if (archivedHabits.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 24, bottom: 8),
                    child: Text(
                      'COMPLETED JOURNEYS 🏆',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  ...archivedHabits.map(
                    (h) => _buildHabitCard(context, h, isArchived: true),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHabitCard(
    BuildContext context,
    Habit habit, {
    bool isArchived = false,
  }) {
    final isDoneToday = habit.isCompletedToday;
    final isActive = habit.isActiveNow && !isArchived;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(habit: habit)),
          );
        },
        child: Card(
          elevation: isActive ? 12 : 2,
          color: isArchived
              ? Colors.grey.shade100
              : (isActive
                    ? Colors.deepPurple.shade50
                    : (isDoneToday ? Colors.green.shade50 : Colors.white)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isActive
                ? const BorderSide(color: Colors.deepPurple, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'habit_name_${habit.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              decoration: isArchived
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isArchived)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _showDeleteDialog(context, habit),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.access_time,
                      _formatTime(habit.startTime),
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.flag_outlined,
                      '${habit.targetDays} days',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!isArchived) ...[
                  _buildStreakRow(habit),
                  const SizedBox(height: 16),
                  if (isActive && !isDoneToday) ...[
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FocusTimerScreen(habit: habit),
                          fullscreenDialog: true,
                        ),
                      ),
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('ENTER FOCUS SESSION'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildMarkDoneButton(habit),
                ] else
                  const Center(
                    child: Text(
                      'Completed successfully! 🎉',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(habitsProvider.notifier).deleteHabit(habit.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakRow(Habit habit) => Row(
    children: [
      Icon(
        Icons.whatshot_outlined,
        color: habit.currentStreak > 0 ? Colors.orangeAccent : Colors.grey,
      ),
      const SizedBox(width: 10),
      Text(
        'Streak: ${habit.currentStreak} days',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: habit.currentStreak > 0 ? Colors.orange[800] : Colors.grey,
        ),
      ),
    ],
  );

  Widget _buildMarkDoneButton(Habit habit) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () =>
          ref.read(habitsProvider.notifier).toggleDoneToday(habit.id),
      icon: Icon(habit.isCompletedToday ? Icons.undo : Icons.check_circle),
      label: Text(habit.isCompletedToday ? 'Undo Completion' : 'Mark as Done'),
      style: ElevatedButton.styleFrom(
        backgroundColor: habit.isCompletedToday
            ? Colors.orange.shade600
            : Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );

  Widget _buildInfoChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _buildFab(BuildContext context) => FloatingActionButton.extended(
    onPressed: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
    ),
    backgroundColor: Colors.deepPurple,
    icon: const Icon(Icons.add, color: Colors.white),
    label: const Text(
      'Add Habit',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildEmptyState() =>
      const Center(child: Text('No habits yet. Start your journey!'));
}
