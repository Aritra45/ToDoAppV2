import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:todoapp/CreateTaskDialog.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/bg.jfif', // replace with your actual image path
              fit: BoxFit.cover,
            ),
          ),
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
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
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true, // enables background color
                      fillColor: Colors.white, // sets background to white
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('tasks')
                        .where('completed', isEqualTo: false)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Center(child: Text("Error loading tasks"));
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      final tasks = docs.where((doc) {
                        final title = doc['title'].toString().toLowerCase();
                        return doc['createdAt'] != null &&
                            title.contains(_searchText.toLowerCase());
                      }).toList();

                      if (tasks.isEmpty) {
                        return const Center(
                            child: Text(
                          "No tasks found.",
                          style: TextStyle(color: Colors.white),
                        ));
                      }

                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final doc = tasks[index];
                          final title = doc['title'];
                          final completed = doc['completed'] ?? false;
                          final createdAt = doc['createdAt'] as Timestamp?;
                          final Timestamp? startTime = doc['startTime'];
                          final completedAt = doc['completedAt'] as Timestamp?;
                          final switchValue = !completed;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 6.0),
                            child: Card(
                              color: Colors.green[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        _confirmDelete(context, doc.id);
                                      },
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (createdAt != null)
                                            Text(
                                              'Start Time: ${_formatTimestamp(startTime)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: switchValue,
                                      onChanged: (value) {
                                        final isCompleted = !value;

                                        FirebaseFirestore.instance
                                            .collection('tasks')
                                            .doc(doc.id)
                                            .update({
                                          'completed': isCompleted,
                                          'completedAt': isCompleted
                                              ? FieldValue.serverTimestamp()
                                              : null,
                                        }).then((_) {
                                          Fluttertoast.showToast(
                                            msg: isCompleted
                                                ? "Task marked as completed ✅"
                                                : "Moved back to active tasks 🔄",
                                            backgroundColor: isCompleted
                                                ? Colors.green
                                                : Colors.blue,
                                            textColor: Colors.white,
                                            gravity: ToastGravity.BOTTOM,
                                          );
                                        });
                                      },
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditDialog(context, doc.id,
                                              title.toString());
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog(
            context: context,
            builder: (context) => const CreateTaskDialog(),
          );
          if (result == true) {
            Fluttertoast.showToast(
              msg: "Task added successfully!",
              backgroundColor: Colors.green,
              textColor: Colors.white,
              gravity: ToastGravity.BOTTOM,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
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

  void _showEditDialog(
      BuildContext context, String taskId, String currentTitle) {
    final TextEditingController controller =
        TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new task title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                FirebaseFirestore.instance
                    .collection('tasks')
                    .doc(taskId)
                    .update({'title': newText}).then((_) {
                  Fluttertoast.showToast(
                    msg: "Task updated successfully!",
                    backgroundColor: Colors.blue,
                    textColor: Colors.white,
                    gravity: ToastGravity.BOTTOM,
                  );
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (context) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text("Are you sure you want to delete this task?"),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);
                        try {
                          await FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(taskId)
                              .delete();
                          if (context.mounted) Navigator.pop(context);
                          Fluttertoast.showToast(
                            msg: "Task deleted",
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            gravity: ToastGravity.BOTTOM,
                          );
                        } catch (e) {
                          setState(() => isDeleting = false);
                          Fluttertoast.showToast(
                            msg: "Delete failed: $e",
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Delete"),
              ),
            ],
          ),
        );
      },
    );
  }
}
