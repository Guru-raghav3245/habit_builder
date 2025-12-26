import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/providers/habits_provider.dart';

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
  late TextEditingController _goalDaysController;

  late ValueNotifier<int> _hourNotifier;
  late ValueNotifier<int> _minNotifier;
  late ValueNotifier<String> _periodNotifier;
  late ValueNotifier<int> _durationNotifier;

  late bool _isTimeExpanded;
  late bool _isDurationExpanded;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minController;
  late FixedExtentScrollController _periodController;
  late FixedExtentScrollController _durationController;

  final List<int> durationPresets = [5, 10, 15, 20, 30, 45, 60];
  final double _itemExtent = 45.0;

  @override
  void initState() {
    super.initState();
    final habit = widget.habitToEdit;
    _nameController = TextEditingController(text: habit?.name ?? '');
    _goalDaysController = TextEditingController(
      text: habit?.targetDays.toString() ?? '30',
    );

    final initialTime = habit?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    int displayHour = initialTime.hourOfPeriod == 0
        ? 12
        : initialTime.hourOfPeriod;
    String displayPeriod = initialTime.period == DayPeriod.am ? "AM" : "PM";

    _hourNotifier = ValueNotifier<int>(displayHour);
    _minNotifier = ValueNotifier<int>(initialTime.minute);
    _periodNotifier = ValueNotifier<String>(displayPeriod);
    _durationNotifier = ValueNotifier<int>(habit?.durationMinutes ?? 20);

    _isTimeExpanded = false;
    _isDurationExpanded = false;

    _hourController = FixedExtentScrollController(initialItem: displayHour - 1);
    _minController = FixedExtentScrollController(
      initialItem: initialTime.minute,
    );
    _periodController = FixedExtentScrollController(
      initialItem: displayPeriod == "AM" ? 0 : 1,
    );
    _durationController = FixedExtentScrollController(
      initialItem: _durationNotifier.value - 1,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalDaysController.dispose();
    _hourController.dispose();
    _minController.dispose();
    _periodController.dispose();
    _durationController.dispose();
    _hourNotifier.dispose();
    _minNotifier.dispose();
    _periodNotifier.dispose();
    _durationNotifier.dispose();
    super.dispose();
  }

  TimeOfDay _getFinalTime() {
    int h = _hourNotifier.value;
    final m = _minNotifier.value;
    final isPm = _periodNotifier.value == "PM";
    if (isPm && h < 12) h += 12;
    if (!isPm && h == 12) h = 0;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedTime = _getFinalTime();
    final goalDays = int.tryParse(_goalDaysController.text) ?? 30;
    final notifier = ref.read(habitsProvider.notifier);

    try {
      if (widget.habitToEdit == null) {
        await notifier.addHabit(
          name: _nameController.text.trim(),
          startTime: selectedTime,
          durationMinutes: _durationNotifier.value,
          targetDays: goalDays,
        );
      } else {
        final updated = widget.habitToEdit!.copyWith(
          name: _nameController.text.trim(),
          startTime: selectedTime,
          durationMinutes: _durationNotifier.value,
          targetDays: goalDays,
        );
        await notifier.updateHabit(updated);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving habit')));
    }
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
            _buildSectionLabel('Habit Name'),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 24),
            _buildSectionLabel('Goal Duration (Days)'),
            TextFormField(
              controller: _goalDaysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade50,
                hintText: 'e.g., 20, 90',
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            _buildCustomPicker(
              label: 'Start Time',
              icon: Icons.access_time,
              isExpanded: _isTimeExpanded,
              onToggle: () => setState(() {
                _isTimeExpanded = !_isTimeExpanded;
                if (_isTimeExpanded) _isDurationExpanded = false;
              }),
              headerValue: ValueListenableBuilder(
                valueListenable: _hourNotifier,
                builder: (_, h, __) => ValueListenableBuilder(
                  valueListenable: _minNotifier,
                  builder: (_, m, __) => ValueListenableBuilder(
                    valueListenable: _periodNotifier,
                    builder: (_, p, __) => Text(
                      '$h:${m.toString().padLeft(2, '0')} $p',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              expandedChild: _buildTimeWheelPicker(),
            ),
            const SizedBox(height: 20),
            _buildCustomPicker(
              label: 'Session Duration',
              icon: Icons.timer_outlined,
              isExpanded: _isDurationExpanded,
              onToggle: () => setState(() {
                _isDurationExpanded = !_isDurationExpanded;
                if (_isDurationExpanded) _isTimeExpanded = false;
              }),
              headerValue: ValueListenableBuilder(
                valueListenable: _durationNotifier,
                builder: (_, d, __) => Text(
                  '$d minutes',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              expandedChild: _buildDurationWheelPicker(),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                widget.habitToEdit == null ? 'Create Habit' : 'Save Changes',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return widget.isEmbedded
        ? content
        : Scaffold(
            appBar: AppBar(
              title: Text(
                widget.habitToEdit == null ? 'New Habit' : 'Edit Habit',
              ),
            ),
            body: content,
          );
  }

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black54,
      ),
    ),
  );

  Widget _buildCustomPicker({
    required String label,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget headerValue,
    required Widget expandedChild,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpanded ? Colors.deepPurple : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                onTap: onToggle,
                leading: Icon(icon, color: Colors.deepPurple),
                title: headerValue,
                trailing: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: isExpanded ? expandedChild : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeWheelPicker() {
    return SizedBox(
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _wheelColumn(_hourController, 12, _hourNotifier, '', offset: 1),
          const Text(
            ':',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          _wheelColumn(_minController, 60, _minNotifier, '', pad: true),
          _wheelColumnStrings(_periodController, ["AM", "PM"], _periodNotifier),
        ],
      ),
    );
  }

  Widget _buildDurationWheelPicker() {
    return SizedBox(
      height: 140,
      child: _wheelColumn(
        _durationController,
        120,
        _durationNotifier,
        'min',
        offset: 1,
      ),
    );
  }

  Widget _wheelColumn(
    FixedExtentScrollController controller,
    int count,
    ValueNotifier<int> notifier,
    String label, {
    int offset = 0,
    bool pad = false,
  }) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _itemExtent,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) => notifier.value = i + offset,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (_, i) {
            String val = (i + offset).toString();
            if (pad) val = val.padLeft(2, '0');
            return Center(
              child: Text('$val $label', style: const TextStyle(fontSize: 18)),
            );
          },
        ),
      ),
    );
  }

  Widget _wheelColumnStrings(
    FixedExtentScrollController controller,
    List<String> options,
    ValueNotifier<String> notifier,
  ) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: _itemExtent,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) => notifier.value = options[i],
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: options.length,
          builder: (_, i) => Center(
            child: Text(
              options[i],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
