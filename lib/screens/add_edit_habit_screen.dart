import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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
  late bool _isDurationExpanded;
  late FixedExtentScrollController _durationController;

  // Duolingo / Calm–style presets
  final List<int> durationPresets = [5, 10, 15, 20, 30, 45, 60];
  final double _itemExtent = 50.0;
  final int _maxDuration = 120;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.habitToEdit?.name ?? '',
    );
    _selectedTime =
        widget.habitToEdit?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    _selectedDuration = widget.habitToEdit?.durationMinutes ?? 20;
    _reminderEnabled = widget.habitToEdit?.reminderEnabled ?? true;
    _focusModeEnabled = widget.habitToEdit?.focusModeEnabled ?? false;
    _isDurationExpanded = false;
    _durationController = FixedExtentScrollController();
    _durationController.addListener(_onDurationScroll);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _onDurationScroll() {
    final index = (_durationController.offset / _itemExtent).round().clamp(0, _maxDuration - 1);
    final newDuration = index + 1;
    if (newDuration != _selectedDuration) {
      setState(() => _selectedDuration = newDuration);
    }
  }

  void _toggleDurationExpansion() {
    setState(() => _isDurationExpanded = !_isDurationExpanded);
    if (_isDurationExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _durationController.animateTo(
          (_selectedDuration - 1) * _itemExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _onPresetSelected(int minutes) {
    setState(() => _selectedDuration = minutes);
    _durationController.animateTo(
      (minutes - 1) * _itemExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onDoneDuration() {
    setState(() => _isDurationExpanded = false);
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
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Habit name',
              hintText: 'e.g., Morning Meditation',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              prefixIcon: const Icon(Icons.task_alt),
            ),
            validator: (v) =>
                v?.trim().isEmpty ?? true ? 'Please enter a habit name' : null,
          ),
          const SizedBox(height: 32),
          Text(
            'Start time',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickTime,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.deepPurple),
                  const SizedBox(width: 16),
                  Text(
                    _selectedTime.format(context),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Duration',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _toggleDurationExpansion,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.deepPurple),
                  const SizedBox(width: 16),
                  Text(
                    '$_selectedDuration minutes',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: _isDurationExpanded ? Colors.deepPurple : null,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isDurationExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Select duration',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      // Presets chips
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: durationPresets.map((minutes) {
                          final selected = _selectedDuration == minutes;
                          return ChoiceChip(
                            label: Text('$minutes min'),
                            selected: selected,
                            selectedColor: Colors.deepPurple.shade50,
                            labelStyle: TextStyle(
                              color: selected ? Colors.deepPurple : null,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) => _onPresetSelected(minutes),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // Wheel picker
                      SizedBox(
                        height: 200,
                        child: ListWheelScrollView.useDelegate(
                          perspective: 0.002,
                          physics: const FixedExtentScrollPhysics(),
                          controller: _durationController,
                          itemExtent: _itemExtent,
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              final minutes = index + 1;
                              final isPreset = durationPresets.contains(minutes);
                              return Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  '$minutes min',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: isPreset ? FontWeight.bold : FontWeight.normal,
                                    color: isPreset ? Colors.deepPurple : null,
                                  ),
                                ),
                              );
                            },
                            childCount: _maxDuration,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Done button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onDoneDuration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 40),
          Center(
            child: OutlinedButton.icon(
              onPressed: NotificationService.testAlarm,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Test alarm sound'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveHabit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.deepPurple,
              ),
              child: Text(
                widget.habitToEdit == null ? 'Add Habit' : 'Save Changes',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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