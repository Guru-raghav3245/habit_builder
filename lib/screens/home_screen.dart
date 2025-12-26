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
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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

    // Simplified view for archived habits
    if (isArchived) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          title: Text(
            habit.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey,
            ),
          ),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
          subtitle: const Text('Goal Reached!'),
        ),
      );
    }

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
          color: isActive
              ? Colors.deepPurple.shade50
              : (isDoneToday ? Colors.green.shade50 : Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
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
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () => _showDeleteDialog(context, habit),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.access_time,
                      _formatTime(habit.startTime),
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.flag_outlined,
                      '${habit.targetDays} days',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress stats shown only for active habits
                _buildProgressStats(habit),

                const SizedBox(height: 20),
                _buildStreakRow(habit),
                const SizedBox(height: 16),
                if (isActive && !isDoneToday) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FocusTimerScreen(habit: habit),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    icon: const Icon(Icons.bolt_rounded),
                    label: const Text(
                      'ENTER FOCUS SESSION',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildMarkDoneButton(habit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStats(Habit habit) {
    final percentage = habit.completionPercentage;
    final displayPercent = (percentage * 100).toInt();
    final misses = habit.missDaysCount;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Overall Progress',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$displayPercent%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.deepPurple.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: misses > 0 ? Colors.redAccent : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              misses == 0
                  ? 'No misses yet!'
                  : '$misses day${misses == 1 ? "" : "s"} missed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: misses > 0 ? Colors.redAccent : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
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
        size: 28,
        color: habit.currentStreak > 0 ? Colors.orangeAccent : Colors.grey[400],
      ),
      const SizedBox(width: 8),
      Text(
        'Current Streak: ${habit.currentStreak} day${habit.currentStreak == 1 ? "" : "s"}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: habit.currentStreak > 0
              ? Colors.orange[800]
              : Colors.grey[600],
        ),
      ),
    ],
  );

  Widget _buildMarkDoneButton(Habit habit) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
        HapticFeedback.mediumImpact();
        ref.read(habitsProvider.notifier).toggleDoneToday(habit.id);
      },
      icon: Icon(
        habit.isCompletedToday
            ? Icons.undo_rounded
            : Icons.check_circle_outline,
        size: 24,
      ),
      label: Text(
        habit.isCompletedToday ? 'Undo Completion' : 'Mark as Done',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: habit.isCompletedToday
            ? Colors.orange.shade600
            : Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );

  Widget _buildInfoChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    ),
  );

  Widget _buildFab(BuildContext context) => FloatingActionButton.extended(
    onPressed: () {
      HapticFeedback.lightImpact();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
      );
    },
    backgroundColor: Colors.deepPurple,
    icon: const Icon(Icons.add, color: Colors.white),
    label: const Text(
      'Add Habit',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_graph_rounded, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          'No habits yet. Start your journey!',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    ),
  );
}
