import 'package:flutter/material.dart';
import 'package:habitit/services/notification_service.dart';

class NotificationTestScreen extends StatelessWidget {
  const NotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                // Uses existing testAlarm function for immediate notification
                await NotificationService.testAlarm();
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Immediate Notification'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                // Uses the new next-minute scheduling function
                await NotificationService.testScheduleNextMinute();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scheduled for the start of the next minute')),
                );
              },
              icon: const Icon(Icons.timer),
              label: const Text('Next Minute Notification'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}