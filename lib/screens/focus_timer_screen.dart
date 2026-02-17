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
  late Timer _ticker;
  late int _remainingSeconds;
  late int _totalSeconds;
  late AnimationController _holdController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    NotificationService.cancelLateReminder(widget.habit.id);

    _totalSeconds = widget.habit.durationMinutes * 60;
    _updateTime();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
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
    final now = DateTime.now();
<<<<<<< HEAD
    final startTime = DateTime(now.year, now.month, now.day, widget.habit.startTime.hour, widget.habit.startTime.minute);
    final endTime = startTime.add(Duration(minutes: widget.habit.durationMinutes));

    if (mounted) {
      setState(() {
        _remainingSeconds = now.isAfter(endTime) ? 0 : endTime.difference(now).inSeconds;
=======
    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      widget.habit.startTime.hour,
      widget.habit.startTime.minute,
    );
    final endTime = startTime.add(
      Duration(minutes: widget.habit.durationMinutes),
    );

    if (mounted) {
      setState(() {
        _remainingSeconds = now.isAfter(endTime)
            ? 0
            : endTime.difference(now).inSeconds;
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
      });
    }

    if (_remainingSeconds <= 0) {
      _completeSession();
    }
  }

  void _completeSession() {
    ref.read(habitsProvider.notifier).markAsDone(widget.habit.id);
    _exit();
    ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
      const SnackBar(content: Text('Well done! Habit completed. 🎉'), backgroundColor: Colors.green),
=======
      const SnackBar(
        content: Text('Well done! Habit completed. 🎉'),
        backgroundColor: Colors.green,
      ),
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
    );
  }

  void _giveUp() {
    ref.read(habitsProvider.notifier).markAsFailed(widget.habit.id);
    _exit();
    ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
      const SnackBar(content: Text('Session cancelled. Habit failed for today.'), backgroundColor: Colors.redAccent),
=======
      const SnackBar(
        content: Text('Session cancelled. Habit failed for today.'),
        backgroundColor: Colors.redAccent,
      ),
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
    );
  }

  void _exit() {
    _ticker.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ticker.cancel();
    _holdController.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');

<<<<<<< HEAD
    // Updated PopScope to use correct widget structure
    return AndroidGestureExclusionContainer(
      child: WillPopScope(
        onWillPop: () async => false,
=======
    return AndroidGestureExclusionContainer(
      child: PopScope(
        canPop: false,
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Text(
                  widget.habit.name.toUpperCase(),
<<<<<<< HEAD
                  style: const TextStyle(color: Colors.white38, letterSpacing: 6),
=======
                  style: const TextStyle(
                    color: Colors.white38,
                    letterSpacing: 6,
                  ),
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
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
<<<<<<< HEAD
                      style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w100, color: Colors.white, letterSpacing: 4),
=======
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w100,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
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
<<<<<<< HEAD
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
=======
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 40,
                      ),
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                        gradient: LinearGradient(
<<<<<<< HEAD
                          colors: [Colors.red.withOpacity(0.5), Colors.transparent],
=======
                          colors: [
                            Colors.red.withOpacity(0.5),
                            Colors.transparent,
                          ],
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
                          stops: [_holdController.value, _holdController.value],
                        ),
                      ),
                      child: Text(
<<<<<<< HEAD
                        _holdController.value > 0 ? 'KEEP HOLDING...' : 'HOLD TO GIVE UP',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
=======
                        _holdController.value > 0
                            ? 'KEEP HOLDING...'
                            : 'HOLD TO GIVE UP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
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
<<<<<<< HEAD
}
=======
}
>>>>>>> 04f3ca18835184e4d0699148f9c8d4abef065edd
