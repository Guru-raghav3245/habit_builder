import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/providers/habits_provider.dart';
import 'package:habit_builder/services/notification_service.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final Habit? habitToEdit;
  final bool isEmbedded;

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
  
  // Use ValueNotifier to prevent full-screen lag during scrolls
  late ValueNotifier<int> _durationNotifier;
  late bool _reminderEnabled;
  late bool _focusModeEnabled;
  late bool _isDurationExpanded;
  late FixedExtentScrollController _durationController;

  final List<int> durationPresets = [5, 10, 15, 20, 30, 45, 60];
  final double _itemExtent = 45.0;
  final int _maxDuration = 120;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habitToEdit?.name ?? '');
    _selectedTime = widget.habitToEdit?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    
    final initialDuration = widget.habitToEdit?.durationMinutes ?? 20;
    _durationNotifier = ValueNotifier<int>(initialDuration);
    
    _reminderEnabled = widget.habitToEdit?.reminderEnabled ?? true;
    _focusModeEnabled = widget.habitToEdit?.focusModeEnabled ?? false;
    _isDurationExpanded = false;
    _durationController = FixedExtentScrollController(initialItem: initialDuration - 1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _durationNotifier.dispose();
    super.dispose();
  }

  void _onPresetSelected(int minutes) {
    HapticFeedback.mediumImpact();
    _durationNotifier.value = minutes;
    _durationController.animateToItem(
      minutes - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.decelerate,
    );
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(habitsProvider.notifier);

    if (widget.habitToEdit == null) {
      await notifier.addHabit(
        name: _nameController.text.trim(),
        startTime: _selectedTime,
        durationMinutes: _durationNotifier.value,
        reminderEnabled: _reminderEnabled,
      );
    } else {
      final updated = widget.habitToEdit!.copyWith(
        name: _nameController.text.trim(),
        startTime: _selectedTime,
        durationMinutes: _durationNotifier.value,
        reminderEnabled: _reminderEnabled,
        focusModeEnabled: _focusModeEnabled,
      );
      await notifier.updateHabit(updated);
    }
    if (mounted && !widget.isEmbedded) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(),
            const SizedBox(height: 32),
            _buildTimePicker(),
            const SizedBox(height: 32),
            _buildDurationSection(), // Optimized Section
            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
      ),
    );

    return widget.isEmbedded
        ? content
        : Scaffold(
            appBar: AppBar(title: Text(widget.habitToEdit == null ? 'New Habit' : 'Edit Habit'), centerTitle: true),
            body: content,
          );
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Habit name',
        prefixIcon: const Icon(Icons.task_alt, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      validator: (v) => v?.trim().isEmpty ?? true ? 'Please enter a name' : null,
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Start time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: _selectedTime);
            if (picked != null) setState(() => _selectedTime = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Text(_selectedTime.format(context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Toggle
              ListTile(
                onTap: () => setState(() => _isDurationExpanded = !_isDurationExpanded),
                leading: const Icon(Icons.timer_outlined, color: Colors.deepPurple),
                title: ValueListenableBuilder(
                  valueListenable: _durationNotifier,
                  builder: (context, value, _) => Text(
                    '$value minutes',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                trailing: Icon(_isDurationExpanded ? Icons.expand_less : Icons.expand_more),
              ),
              
              // Animated Expanded Part
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: _isDurationExpanded
                    ? Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            const Divider(),
                            const SizedBox(height: 12),
                            // Presets
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: durationPresets.map((m) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ValueListenableBuilder(
                                    valueListenable: _durationNotifier,
                                    builder: (context, current, _) => ChoiceChip(
                                      label: Text('$m min'),
                                      selected: current == m,
                                      onSelected: (_) => _onPresetSelected(m),
                                      selectedColor: Colors.deepPurple,
                                      labelStyle: TextStyle(color: current == m ? Colors.white : Colors.black),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Optimized Wheel
                            SizedBox(
                              height: 140,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: 40,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  ListWheelScrollView.useDelegate(
                                    controller: _durationController,
                                    itemExtent: _itemExtent,
                                    physics: const FixedExtentScrollPhysics(),
                                    onSelectedItemChanged: (index) {
                                      HapticFeedback.selectionClick();
                                      _durationNotifier.value = index + 1;
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      childCount: _maxDuration,
                                      builder: (context, index) => Center(
                                        child: Text(
                                          '${index + 1} min',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: NotificationService.testAlarm,
          icon: const Icon(Icons.notifications_active),
          label: const Text('Test Alarm'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saveHabit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(widget.habitToEdit == null ? 'Create Habit' : 'Save Changes', 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}