import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:android_gesture_exclusion/android_gesture_exclusion.dart';
import 'package:habit_builder/models/habit.dart';
import 'package:habit_builder/services/notification_service.dart';

class FocusTimerScreen extends StatefulWidget {
  final Habit habit;

  const FocusTimerScreen({super.key, required this.habit});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
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

    // Phase 4: User has entered the focus screen, cancel the "Late" reminder
    NotificationService.cancelLateReminder(widget.habit.id);

    _totalSeconds = widget.habit.durationMinutes * 60;
    _calculateRemainingTime();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemainingTime();
    });

    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        _exitManual();
      }
    });
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
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
        if (now.isAfter(endTime)) {
          _remainingSeconds = 0;
        } else {
          _remainingSeconds = endTime.difference(now).inSeconds;
        }
      });
    }

    if (_remainingSeconds <= 0) {
      _exitWithSuccess();
    }
  }

  void _exitWithSuccess() {
    _cleanupAndExit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session complete! You did it! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _exitManual() {
    _cleanupAndExit();
  }

  void _cleanupAndExit() {
    _ticker.cancel();
    if (mounted) {
      Navigator.of(context).pop();
    }
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
    return AndroidGestureExclusionContainer(
      verticalExclusionMargin: 0,
      horizontalExclusionMargin: 0,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Text(
                  widget.habit.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: _remainingSeconds / _totalSeconds,
                            end: _remainingSeconds / _totalSeconds,
                          ),
                          duration: const Duration(seconds: 1),
                          curve: Curves.linear,
                          builder: (context, value, child) {
                            return SizedBox(
                              width: 300,
                              height: 300,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 2,
                                color: Colors.deepPurpleAccent.withOpacity(0.4),
                                backgroundColor: Colors.white10,
                              ),
                            );
                          },
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TimerDisplay(seconds: _remainingSeconds),
                            const Text(
                              'FOCUS ACTIVE',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                letterSpacing: 4,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: GestureDetector(
                    onTapDown: (_) {
                      _holdController.forward();
                      HapticFeedback.lightImpact();
                    },
                    onTapUp: (_) {
                      if (_holdController.status != AnimationStatus.completed) {
                        _holdController.reverse();
                      }
                    },
                    onTapCancel: () {
                      if (_holdController.status != AnimationStatus.completed) {
                        _holdController.reverse();
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _holdController,
                      builder: (context, child) {
                        final isHolding =
                            _holdController.isAnimating ||
                            _holdController.value > 0;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 45,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.withOpacity(0.6),
                                Colors.transparent,
                              ],
                              stops: [
                                _holdController.value,
                                _holdController.value,
                              ],
                            ),
                          ),
                          child: Text(
                            isHolding ? 'HOLDING...' : 'HOLD TO GIVE UP',
                            style: TextStyle(
                              color: isHolding ? Colors.white : Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimerDisplay extends StatelessWidget {
  final int seconds;
  const TimerDisplay({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');

    return Text(
      '$m:$s',
      style: const TextStyle(
        fontSize: 100,
        fontWeight: FontWeight.w100,
        color: Colors.white,
        letterSpacing: 5,
      ),
    );
  }
}
