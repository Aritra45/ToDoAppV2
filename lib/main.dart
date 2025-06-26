import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:todoapp/notification_service.dart';
import 'TodoHomePage.dart';
import 'CompletedTasksPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Init local notifications
  await NotificationService.init();

  // Ask for permission (required Android 13+)
  final alarmStatus = await Permission.scheduleExactAlarm.request();
  if (alarmStatus != PermissionStatus.granted) {
    Fluttertoast.showToast(msg: "Alarm permission not granted");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lizu Tasks',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeWithTabs(),
    );
  }
}

class HomeWithTabs extends StatelessWidget {
  const HomeWithTabs({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.amber,
            title: const Text("Lizu Tasks"),
            bottom: const TabBar(tabs: [
              Tab(text: 'Tasks'),
              Tab(text: 'Completed'),
            ]),
          ),
          body: TabBarView(children: [
            TodoHomePage(),
            CompletedTasksPage(),
          ]),
        ),
      );
}
