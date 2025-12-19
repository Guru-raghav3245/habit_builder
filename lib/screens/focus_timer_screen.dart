import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:habit_builder/models/habit.dart';

class FocusTimerScreen extends StatefulWidget {
  final Habit habit;

  const FocusTimerScreen({super.key, required this.habit});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  late Timer _ticker;
  late Timer _navigationHideTimer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    WakelockPlus.enable();
    _calculateRemainingTime();

    // Ticker that forces the UI to stay in sync with the actual clock
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemainingTime();
    });

    // Aggressive navigation bar hiding timer (reduced to 10ms)
    _navigationHideTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
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

    setState(() {
      if (now.isAfter(endTime)) {
        _remainingSeconds = 0;
      } else {
        _remainingSeconds = endTime.difference(now).inSeconds;
      }
    });

    if (_remainingSeconds <= 0) {
      _exitWithSuccess();
    }
  }

  void _hideNavigationBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  void _exitWithSuccess() {
    _ticker.cancel();
    _navigationHideTimer.cancel();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session complete! You did it! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    _navigationHideTimer.cancel();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          // CRITICAL: Capture ALL gestures including edge swipes
          behavior: HitTestBehavior.translucent,
          onTap: _hideNavigationBar,
          onPanStart: (_) => _hideNavigationBar(),
          onPanUpdate: (_) => _hideNavigationBar(),
          onPanEnd: (_) => _hideNavigationBar(),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$minutes:$seconds',
                        style: const TextStyle(
                          fontSize: 110,
                          fontWeight: FontWeight.w100,
                          color: Colors.white,
                          letterSpacing: 10,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: GestureDetector(
                  onLongPress: () {
                    _ticker.cancel();
                    _navigationHideTimer.cancel();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 45,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'HOLD TO GIVE UP',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
