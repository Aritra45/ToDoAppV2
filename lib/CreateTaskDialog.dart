import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todoapp/notification_service.dart'; // ✅ Use your service
import 'package:timezone/timezone.dart' as tz;

class CreateTaskDialog extends StatefulWidget {
  const CreateTaskDialog({super.key});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final TextEditingController _controller = TextEditingController();
  DateTime? _startTime;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("New Task"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: "Enter task name"),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text("Start Time:"),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickStartTime,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _startTime != null
                ? _formatDateTime(_startTime!)
                : 'No start time selected',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addTask,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Add Task"),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _pickStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _startTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _addTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter task name and start time")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch device FCM token (make sure you've initialized FirebaseMessaging!)
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        Fluttertoast.showToast(msg: "⚠ Could not retrieve FCM token");
        return;
      }

      await FirebaseFirestore.instance
          .collection('scheduled_notifications')
          .add({
        'title': title,
        'token': token,
        'scheduledTime': _startTime,
        'createdAt': FieldValue.serverTimestamp(),
        'isSent': false,
      });

      Fluttertoast.showToast(
          msg: "⏰ Notification scheduled on server for $_startTime");

      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error scheduling via Firebase: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Future<void> _scheduleLocalNotification(String title, DateTime time) async {
  //   final now = DateTime.now();
  //   final scheduled = tz.TZDateTime.from(time, tz.local);

  //   if (scheduled.isBefore(
  //       tz.TZDateTime.from(now.add(Duration(seconds: 5)), tz.local))) {
  //     Fluttertoast.showToast(
  //       msg: "⚠ Please select a valid future time",
  //       toastLength: Toast.LENGTH_LONG,
  //       gravity: ToastGravity.BOTTOM,
  //       backgroundColor: Colors.red,
  //       textColor: Colors.white,
  //     );
  //     throw ArgumentError("Scheduled time must be in the future");
  //   }

  //   await NotificationService.scheduleNotification(
  //     id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  //     title: "⏰ Task Reminder",
  //     body: title,
  //     scheduledDate: time,
  //   );
  // }
}
