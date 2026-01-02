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
      if (mounted) {
        if (!widget.isEmbedded) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Habit saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving habit')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardWrapper(
              title: 'General Information',
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Habit Name',
                  hint: 'e.g., Morning Yoga',
                  icon: Icons.edit_note_rounded,
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _goalDaysController,
                  label: 'Challenge Duration (Days)',
                  hint: '30',
                  icon: Icons.flag_rounded,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildCardWrapper(
              title: 'Schedule & Timing',
              children: [
                _buildExpandablePicker(
                  label: 'Start Time',
                  icon: Icons.access_time_filled_rounded,
                  isExpanded: _isTimeExpanded,
                  onToggle: () => setState(() {
                    _isTimeExpanded = !_isTimeExpanded;
                    if (_isTimeExpanded) _isDurationExpanded = false;
                  }),
                  headerValue: ValueListenableBuilder(
                    valueListenable: _hourNotifier,
                    builder: (_, h, _) => ValueListenableBuilder(
                      valueListenable: _minNotifier,
                      builder: (_, m, _) => ValueListenableBuilder(
                        valueListenable: _periodNotifier,
                        builder: (_, p, _) => Text(
                          '$h:${m.toString().padLeft(2, '0')} $p',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),
                  ),
                  expandedChild: _buildTimeWheelPicker(),
                ),
                const Divider(height: 32),
                _buildExpandablePicker(
                  label: 'Focus Session',
                  icon: Icons.timer_rounded,
                  isExpanded: _isDurationExpanded,
                  onToggle: () => setState(() {
                    _isDurationExpanded = !_isDurationExpanded;
                    if (_isDurationExpanded) _isTimeExpanded = false;
                  }),
                  headerValue: ValueListenableBuilder(
                    valueListenable: _durationNotifier,
                    builder: (_, d, _) => Text(
                      '$d minutes',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  expandedChild: _buildDurationWheelPicker(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                widget.habitToEdit == null ? 'Create Habit' : 'Save Changes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (widget.habitToEdit != null && widget.isEmbedded) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                label: const Text(
                  'Delete Habit',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );

    return widget.isEmbedded
        ? content
        : Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              title: Text(
                widget.habitToEdit == null ? 'New Habit' : 'Edit Habit',
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
            body: content,
          );
  }

  Widget _buildCardWrapper({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.deepPurple.shade300),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildExpandablePicker({
    required String label,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget headerValue,
    required Widget expandedChild,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: Colors.deepPurple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    headerValue,
                  ],
                ),
              ),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Column(children: [const SizedBox(height: 16), expandedChild])
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTimeWheelPicker() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _wheelColumn(_hourController, 12, _hourNotifier, '', offset: 1),
          const Text(
            ':',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          _wheelColumn(_minController, 60, _minNotifier, '', pad: true),
          _wheelColumnStrings(_periodController, ["AM", "PM"], _periodNotifier),
        ],
      ),
    );
  }

  Widget _buildDurationWheelPicker() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
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
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick();
          notifier.value = i + offset;
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (_, i) {
            String val = (i + offset).toString();
            if (pad) val = val.padLeft(2, '0');
            return Center(
              child: Text(
                '$val $label',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick();
          notifier.value = options[i];
        },
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: const Text(
          'This will permanently erase your progress for this habit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(habitsProvider.notifier)
                  .deleteHabit(widget.habitToEdit!.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Exit detail screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
