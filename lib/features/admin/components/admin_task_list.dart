// lib/features/admin/components/admin_task_list.dart

import 'package:flutter/material.dart';
import 'product_mirror_card.dart';

class AdminTaskList extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final Function(
    String,
    String,
    Map<String, dynamic>,
    String,
    Map<String, dynamic>,
  )
  onUpdate;
  final Function(String, String) onPurge;
  final Function(String) onArchive;

  const AdminTaskList({
    super.key,
    required this.tasks,
    required this.onUpdate,
    required this.onPurge,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    // Debugging: Identify exactly what is being passed to the list
    debugPrint('--- [ADMIN TASK LIST DEBUG] ---');
    debugPrint('Tasks received in list: ${tasks.length}');

    if (tasks.isEmpty) {
      debugPrint('DEBUG: Tasks list is empty, rendering "Empty" state.');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              "No tasks found in this section",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      // Using physics to ensure smooth scrolling inside the TabBarView
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final String taskId = task['id']?.toString() ?? 'unknown_$index';
        final String? productId = task['product_id'];

        // Debug log for every individual item to verify the link
        debugPrint('Index $index: TaskID $taskId -> ProductID $productId');

        return ProductMirrorCard(
          // Using a String-based ValueKey to prevent type-mismatch rebuild errors
          key: ValueKey('task_$taskId'),
          task: task,
          onUpdate: onUpdate,
          onPurge: onPurge,
          onArchive: onArchive,
        );
      },
    );
  }
}
