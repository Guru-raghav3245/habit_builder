import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:android_gesture_exclusion/android_gesture_exclusion.dart';
import 'package:habitit/models/habit.dart';
import 'package:habitit/services/notification_service.dart';
import 'package:habitit/providers/habits_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FocusTimerScreen extends ConsumerStatefulWidget {
  final Habit habit;
  const FocusTimerScreen({super.key, required this.habit});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen>
    with TickerProviderStateMixin {
  Timer? _ticker;
  late int _remainingSeconds;
  late int _totalSeconds;
  late AnimationController _holdController;
  bool _sessionEnded = false; // guard against calling _completeSession twice

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    NotificationService.cancelLateReminder(widget.habit.id);

    _totalSeconds = widget.habit.durationMinutes * 60;

    // Fix: was created twice before — only create once
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _updateTime();

    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        _giveUp();
      }
    });
  }

  void _updateTime() {
    // Guard: if widget is disposed or session already ended, stop
    if (!mounted || _sessionEnded) {
      _ticker?.cancel();
      return;
    }

    final now = DateTime.now();
    final startTime = DateTime(
      now.year, now.month, now.day,
      widget.habit.startTime.hour,
      widget.habit.startTime.minute,
    );
    final endTime = startTime.add(Duration(minutes: widget.habit.durationMinutes));

    setState(() {
      _remainingSeconds = now.isAfter(endTime) ? 0 : endTime.difference(now).inSeconds;
    });

    if (_remainingSeconds <= 0) {
      _completeSession();
    }
  }

  void _completeSession() {
    // Guard: only run once, and only if still mounted
    if (_sessionEnded || !mounted) return;
    _sessionEnded = true;
    _ticker?.cancel();

    ref.read(habitsProvider.notifier).markAsDone(widget.habit.id);

    Navigator.of(context).pop();

    // Show snackbar after pop using the parent context via a post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Well done! Habit completed. 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _giveUp() {
    if (_sessionEnded || !mounted) return;
    _sessionEnded = true;
    _ticker?.cancel();

    ref.read(habitsProvider.notifier).markAsFailed(widget.habit.id);

    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session cancelled. Habit failed for today.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _holdController.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return AndroidGestureExclusionContainer(
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Text(
                  widget.habit.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white38, letterSpacing: 6),
                ),
                const Spacer(),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: CircularProgressIndicator(
                        value: _remainingSeconds / _totalSeconds,
                        strokeWidth: 2,
                        color: Colors.deepPurpleAccent.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      '$m:$s',
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w100,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTapDown: (_) => _holdController.forward(),
                  onTapUp: (_) => _holdController.reverse(),
                  onTapCancel: () => _holdController.reverse(),
                  child: AnimatedBuilder(
                    animation: _holdController,
                    builder: (context, _) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                        gradient: LinearGradient(
                          colors: [Colors.red.withOpacity(0.5), Colors.transparent],
                          stops: [_holdController.value, _holdController.value],
                        ),
                      ),
                      child: Text(
                        _holdController.value > 0 ? 'KEEP HOLDING...' : 'HOLD TO GIVE UP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}