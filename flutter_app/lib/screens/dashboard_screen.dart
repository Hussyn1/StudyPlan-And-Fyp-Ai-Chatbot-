import 'dart:ui';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Learning Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => progressController.loadProgress(),
          ),
        ],
      ),
      body: Obx(() {
        if (progressController.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (progressController.progressList.isEmpty) {
          return const Center(child: Text('No progress data available.', style: TextStyle(color: Colors.white70)));
        }

        // Show list with AI summary at the top
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI Summary Section
            FadeInDown(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900]!.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'AI Learning Coach',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (progressController.isAiLoading.value && progressController.progressSummary.isEmpty)
                            const LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.black, color: Colors.white)
                          else
                            Text(
                              progressController.progressSummary.value.isEmpty
                                  ? "Complete some tasks to get AI feedback on your progress!"
                                  : progressController.progressSummary.value,
                              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white70),
                            ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => Get.to(() => const StudyPlanScreen()),
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('Weekly Study Plan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Course Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
