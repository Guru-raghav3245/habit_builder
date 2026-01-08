import 'package:flutter/material.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/screens/add_edit_habit_screen.dart';
import 'package:habit_builder/screens/progress_screen.dart';

class DetailScreen extends StatefulWidget {
  final Habit habit;
  const DetailScreen({super.key, required this.habit});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize with 2 tabs for Settings and Progress
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 150.0,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.habit.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                centerTitle: true,
              ),
            ),
            // Removed the SliverPersistentHeader from here to move it to the bottom
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            AddEditHabitScreen(habitToEdit: widget.habit, isEmbedded: true),
            ProgressScreen(habit: widget.habit),
          ],
        ),
      ),
      // Added bottomNavigationBar to place the TabBar at the bottom of the screen
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
              Tab(icon: Icon(Icons.insights_rounded), text: 'Progress'),
            ],
          ),
        ),
      ),
    );
  }
}
