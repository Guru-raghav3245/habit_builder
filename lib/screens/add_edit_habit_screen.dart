import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/providers/habits_provider.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final Habit? habitToEdit;
  final bool isEmbedded; // Added flag for UI improvement

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

  final List<int> durationPresets = [10, 20, 30];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habitToEdit?.name ?? '');
    _selectedTime = widget.habitToEdit?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    _selectedDuration = widget.habitToEdit?.durationMinutes ?? 20;
    _reminderEnabled = widget.habitToEdit?.reminderEnabled ?? true;
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
            hourMinuteColor: Colors.deepPurple.shade50,
            hourMinuteTextColor: Colors.deepPurple,
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
      );
      await notifier.updateHabit(updated);
    }

    if (mounted) {
      // Only pop if we are in the "Add" screen (not embedded)
      if (!widget.isEmbedded) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.habitToEdit == null ? 'Habit added!' : 'Changes saved!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habitToEdit != null;

    // Core UI content extracted for reuse
    Widget content = SingleChildScrollView(
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.task_alt),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Please enter a habit name' : null,
            ),
            const SizedBox(height: 24),
            const Text('Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              onTap: _pickTime,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              leading: const Icon(Icons.access_time, color: Colors.deepPurple),
              title: const Text('Start Time'),
              trailing: Text(
                _selectedTime.format(context),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Duration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ...durationPresets.map((min) => ChoiceChip(
                  label: Text('$min min'),
                  selected: _selectedDuration == min,
                  onSelected: (_) => setState(() => _selectedDuration = min),
                )),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: !durationPresets.contains(_selectedDuration),
                  onSelected: (_) async {
                    final int? custom = await showDialog<int>(
                      context: context,
                      builder: (_) => _CustomDurationDialog(initial: _selectedDuration),
                    );
                    if (custom != null) setState(() => _selectedDuration = custom);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Daily reminder', style: TextStyle(fontWeight: FontWeight.bold)),
              value: _reminderEnabled,
              onChanged: (v) => setState(() => _reminderEnabled = v),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveHabit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isEditing ? 'Update Settings' : 'Create Habit',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // If embedded in DetailScreen, return just the content. 
    // Otherwise, return a full Scaffold for the "Add New Habit" flow.
    return widget.isEmbedded 
        ? content 
        : Scaffold(
            appBar: AppBar(title: const Text('New Habit'), centerTitle: true),
            body: content,
          );
  }
}

// Keep the existing _CustomDurationDialog here...
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