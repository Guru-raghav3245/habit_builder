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

class _DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit.name),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Edit'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Progress'),
          ],
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Edit tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: AddEditHabitScreen(habitToEdit: widget.habit),
          ),
          // Progress tab
          ProgressScreen(habit: widget.habit),
        ],
      ),
    );
  }
}