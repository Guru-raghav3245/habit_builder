import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/providers/habits_provider.dart';
import 'package:habit_builder/services/notification_service.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final Habit? habitToEdit;
  final bool isEmbedded; // For use inside DetailScreen without extra Scaffold

  const AddEditHabitScreen({
    super.key,
    this.habitToEdit,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TimeOfDay _selectedTime;
  late int _selectedDuration;
  late bool _reminderEnabled;
  late bool _focusModeEnabled;

  final List<int> durationPresets = [10, 20, 30];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habitToEdit?.name ?? '');
    _selectedTime = widget.habitToEdit?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    _selectedDuration = widget.habitToEdit?.durationMinutes ?? 20;
    _reminderEnabled = widget.habitToEdit?.reminderEnabled ?? true;
    _focusModeEnabled = widget.habitToEdit?.focusModeEnabled ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            hourMinuteColor: Colors.deepPurple.shade50,
            hourMinuteTextColor: Colors.deepPurple,
            dayPeriodColor: Colors.deepPurple.shade100,
            dayPeriodTextColor: Colors.deepPurple,
            dialBackgroundColor: Colors.deepPurple.shade50,
            dialHandColor: Colors.deepPurple,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _selectDuration(int minutes) => setState(() => _selectedDuration = minutes);

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(habitsProvider.notifier);

    if (widget.habitToEdit == null) {
      await notifier.addHabit(
        name: _nameController.text.trim(),
        startTime: _selectedTime,
        durationMinutes: _selectedDuration,
        reminderEnabled: _reminderEnabled,
      );
    } else {
      final updated = widget.habitToEdit!.copyWith(
        name: _nameController.text.trim(),
        startTime: _selectedTime,
        durationMinutes: _selectedDuration,
        reminderEnabled: _reminderEnabled,
        focusModeEnabled: _focusModeEnabled,
      );
      await notifier.updateHabit(updated);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.habitToEdit == null ? 'Habit added!' : 'Habit updated!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    }
  }

  Widget get content => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Habit name',
                  hintText: 'e.g., Morning Meditation',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.task_alt),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Please enter a habit name' : null,
              ),
              const SizedBox(height: 32),
              Text('Start time', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.deepPurple),
                      const SizedBox(width: 16),
                      Text(_selectedTime.format(context), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Duration', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...durationPresets.map((min) => FilterChip(
                        label: Text('$min min'),
                        selected: _selectedDuration == min,
                        onSelected: (_) => _selectDuration(min),
                        selectedColor: Colors.deepPurple,
                        checkmarkColor: Colors.white,
                      )),
                  FilterChip(
                    label: const Text('Custom'),
                    selected: !durationPresets.contains(_selectedDuration),
                    onSelected: (_) async {
                      final int? custom = await showDialog<int>(
                        context: context,
                        builder: (_) => _CustomDurationDialog(initial: _selectedDuration),
                      );
                      if (custom != null && custom > 0) setState(() => _selectedDuration = custom);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(child: Text('$_selectedDuration minutes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple))),
              const SizedBox(height: 32),
              SwitchListTile(
                title: const Text('Daily reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text('Will remind you daily at ${_selectedTime.format(context)}'),
                value: _reminderEnabled,
                activeColor: Colors.deepPurple,
                onChanged: (v) => setState(() => _reminderEnabled = v),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Focus Lockdown Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: const Text('Enable full-screen distraction-free timer for this habit'),
                value: _focusModeEnabled,
                activeColor: Colors.deepPurple,
                onChanged: (v) => setState(() => _focusModeEnabled = v),
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: NotificationService.testAlarm,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Test alarm sound'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveHabit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: Text(
                    widget.habitToEdit == null ? 'Add Habit' : 'Save Changes',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return widget.isEmbedded
        ? content
        : Scaffold(
            appBar: AppBar(title: const Text('New Habit'), centerTitle: true),
            body: content,
          );
  }
}

class _CustomDurationDialog extends StatefulWidget {
  final int initial;
  const _CustomDurationDialog({required this.initial});

  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom duration (minutes)'),
      content: TextField(controller: _controller, keyboardType: TextInputType.number, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final int? value = int.tryParse(_controller.text);
            if (value != null && value > 0) Navigator.pop(context, value);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}