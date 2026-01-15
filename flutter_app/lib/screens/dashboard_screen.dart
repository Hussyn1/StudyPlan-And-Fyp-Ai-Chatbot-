import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/progress_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/progress_card.dart';
import 'study_plan_screen.dart';
import 'package:animate_do/animate_do.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ProgressController progressController = Get.find<ProgressController>();

  @override
  void initState() {
    super.initState();
    progressController.loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => progressController.loadProgress(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Get.find<AuthController>().logout();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
      body: Obx(() {
        if (progressController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (progressController.progressList.isEmpty) {
          return const Center(child: Text('No progress data available.'));
        }

        // Show list with AI summary at the top
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI Summary Section
            FadeInDown(
              child: Card(
                color: Colors.indigo[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.indigo),
                          const SizedBox(width: 8),
                          Text(
                            'AI Progress Insights',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (progressController.isAiLoading.value && progressController.progressSummary.isEmpty)
                        const LinearProgressIndicator()
                      else
                        Text(
                          progressController.progressSummary.value.isEmpty
                              ? "Complete some tasks to get AI feedback on your progress!"
                              : progressController.progressSummary.value,
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Get.to(() => const StudyPlanScreen()),
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('View Weekly Study Plan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo,
                            side: const BorderSide(color: Colors.indigo),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Course Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...progressController.progressList.map((progress) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ProgressCard(
                  title: progress['course_name'] ?? 'Unknown Course',
                  progress: ((progress['accuracy'] ?? 0.0) as num).toDouble() * 100,
                  completed: progress['tasks_completed'] ?? 0,
                  total: progress['total_tasks'] ?? 0,
                  avgScore: ((progress['grade'] ?? 0.0) as num).toDouble(),
                ),
              );
            }),
          ],
        );
      }),
    );
  }
}
