import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import '../controllers/fyp_controller.dart';
import '../widgets/task_tile.dart';
import '../widgets/fyp_card.dart';

class FypScreen extends StatefulWidget {
  const FypScreen({super.key});

  @override
  State<FypScreen> createState() => _FypScreenState();
}

class _FypScreenState extends State<FypScreen> {
  final TaskController taskController = Get.find<TaskController>();
  final FypController fypController = Get.find<FypController>();

  @override
  void initState() {
    super.initState();
    taskController.loadTasks();
    fypController.loadSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Tasks & FYP'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Learning Tasks', icon: Icon(Icons.assignment)),
              Tab(text: 'FYP Suggestions', icon: Icon(Icons.rocket_launch)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTasksTab(),
            _buildFypTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    return Obx(() {
      if (taskController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (taskController.tasks.isEmpty) {
        return const Center(child: Text('No tasks found. Register for courses to get tasks!'));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: taskController.tasks.length,
        itemBuilder: (context, index) {
          final task = taskController.tasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TaskTile(
              task: task,
              onTap: () async {
                if (task.status == 'completed') {
                  Get.snackbar('Task Completed', 'You have already finished this task!',
                      snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                  return;
                }

                // Check if it's a "placeholder" task (not AI generated yet)
                if (task.description.contains('Learn and master the concepts') || !task.title.contains('Practice:')) {
                  // Show loading dialog
                  Get.dialog(
                    const Center(child: CircularProgressIndicator()),
                    barrierDismissible: false,
                  );
                  
                  final updatedTask = await taskController.generateAiTask(task.id ?? '');
                  Get.back(); // Close loading dialog
                  
                  if (!mounted) return;
                  
                  if (updatedTask != null) {
                    _showTaskSubmissionDialog(context, updatedTask);
                  } else {
                    Get.snackbar('Error', 'Failed to generate AI task. Try again.');
                  }
                } else {
                  _showTaskSubmissionDialog(context, task);
                }
              },
            ),
          );
        },
      );
    });
  }

  void _showTaskSubmissionDialog(BuildContext context, dynamic task) {
    final TextEditingController answerController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.type.toString().toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            const SizedBox(height: 16),
            TextField(
              controller: answerController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter your answer or code here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (answerController.text.trim().isEmpty) {
                Get.snackbar('Error', 'Please enter some content');
                return;
              }
              final response = await taskController.submitTask(
                task.id ?? '',
                answerController.text,
              );
              
              if (response != null) {
                Get.back(); // Close submission dialog
                
                final bool verified = response['verified'] ?? false;
                final int score = response['score'] ?? 0;
                final String feedback = response['feedback'] ?? 'No feedback provided.';

                Get.dialog(
                  AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Row(
                      children: [
                        Icon(
                          verified ? Icons.check_circle : Icons.error,
                          color: verified ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(verified ? 'Task Accepted' : 'Refinement Needed'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: verified ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Score: $score%',
                            style: TextStyle(
                              color: verified ? Colors.green[700] : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(feedback),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Got it!'),
                      ),
                    ],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            child: const Text('Submit Solution'),
          ),
        ],
      ),
    );
  }

  Widget _buildFypTab() {
    return Obx(() {
      if (fypController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (fypController.suggestions.isEmpty) {
        return const Center(child: Text('No FYP suggestions available yet.'));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: fypController.suggestions.length,
        itemBuilder: (context, index) {
          final fyp = fypController.suggestions[index];
          return FypCard(fyp: fyp);
        },
      );
    });
  }
}
