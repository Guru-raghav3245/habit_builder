import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:habit_builder/models/habit.dart';

class FocusTimerScreen extends StatefulWidget {
  final Habit habit;
  final int initialSeconds;

  const FocusTimerScreen({
    super.key,
    required this.habit,
    required this.initialSeconds,
  });

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late int _remainingSeconds;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    
    // Safety check for duration
    final duration = Duration(seconds: _remainingSeconds > 0 ? _remainingSeconds : 1);
    
    _controller = AnimationController(
      vsync: this,
      duration: duration,
    )..addListener(() {
        setState(() {
          _remainingSeconds = (_controller.duration! * (1 - _controller.value)).inSeconds;
        });
      });

    WakelockPlus.enable();
    _startTimer();
  }

  void _startTimer() {
    _isRunning = true;
    _controller.reverse(from: 1.0);
  }

  void _pauseTimer() {
    _isRunning = false;
    _controller.stop();
  }

  void _showGiveUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Give Up?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to end this focus session early?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay Focused', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, _remainingSeconds);
            },
            child: const Text('Give Up', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    // Only auto-pop if the timer actually reached 0 while running.
    if (_remainingSeconds <= 0 && _isRunning && _controller.value == 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session complete! You did it! 🎉'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    }

    return WillPopScope(
      onWillPop: () async {
        _pauseTimer();
        _showGiveUpDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 32),
                      onPressed: () {
                        _pauseTimer();
                        _showGiveUpDialog();
                      },
                    ),
                    const Spacer(),
                    Text(
                      widget.habit.name,
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
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
                          fontSize: 96,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        _isRunning ? 'Stay focused...' : 'Paused',
                        style: const TextStyle(fontSize: 24, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(40),
                child: GestureDetector(
                  onLongPress: () {
                    _pauseTimer();
                    _showGiveUpDialog();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: const Text(
                      'Hold to Give Up',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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