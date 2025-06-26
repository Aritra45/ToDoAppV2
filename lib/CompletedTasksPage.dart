import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todoapp/notification_service.dart';

class CompletedTasksPage extends StatefulWidget {
  const CompletedTasksPage({super.key});

  @override
  State<CompletedTasksPage> createState() => _CompletedTasksPageState();
}

class _CompletedTasksPageState extends State<CompletedTasksPage> {
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/bg.jfif',
              fit: BoxFit.cover,
            ),
          ),
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchText = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search completed tasks...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: _buildTaskList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.bug_report),
        onPressed: () async {
          await NotificationService.scheduleNotification(
            id: 999,
            title: "🧪 Test Notification",
            body: "This is a debug notification",
            scheduledDate: DateTime.now().add(const Duration(seconds: 2)),
          );
          Fluttertoast.showToast(
              msg: "🧪 Debug notification scheduled (in 30s)");
        },
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('completed', isEqualTo: true)
          .orderBy('completedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading tasks"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final tasks = docs.where((doc) {
          final title = doc['title'].toString().toLowerCase();
          return title.contains(_searchText.toLowerCase());
        }).toList();

        if (tasks.isEmpty) {
          return const Center(
              child: Text(
            "No completed tasks.",
            style: TextStyle(color: Colors.white),
          ));
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final doc = tasks[index];
            final title = doc['title'];
            final createdAt = doc['createdAt'] as Timestamp?;
            final completedAt = doc['completedAt'] as Timestamp?;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Card(
                color: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _confirmDelete(context, doc.id);
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (createdAt != null)
                              Text(
                                'Created: ${_formatTimestamp(createdAt)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            if (completedAt != null)
                              Text(
                                'Completed: ${_formatTimestamp(completedAt)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            if (createdAt != null && completedAt != null)
                              Text(
                                'Time Taken: ${_calculateDuration(createdAt, completedAt)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                          ],
                        ),
                      ),
                      Switch(
                        value: false,
                        onChanged: (value) {
                          if (value) {
                            FirebaseFirestore.instance
                                .collection('tasks')
                                .doc(doc.id)
                                .update({
                              'completed': false,
                              'completedAt': null,
                            }).then((_) {
                              Fluttertoast.showToast(
                                msg: "Moved back to active tasks ✅",
                                backgroundColor: Colors.blue,
                                textColor: Colors.white,
                                gravity: ToastGravity.BOTTOM,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    final dateTime = timestamp.toDate();
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _calculateDuration(Timestamp? created, Timestamp? completed) {
    if (created == null || completed == null) return '-';
    final duration = completed.toDate().difference(created.toDate());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return hours > 0 ? '$hours hr $minutes min' : '$minutes min';
  }

  void _confirmDelete(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(taskId)
                  .delete();
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Task deleted",
                backgroundColor: Colors.red,
                textColor: Colors.white,
                gravity: ToastGravity.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
