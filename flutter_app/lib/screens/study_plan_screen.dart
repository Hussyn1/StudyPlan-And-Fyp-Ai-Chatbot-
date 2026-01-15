import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../controllers/progress_controller.dart';

class StudyPlanScreen extends StatelessWidget {
  const StudyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progressController = Get.find<ProgressController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => progressController.loadAiInsights(),
          ),
        ],
      ),
      body: Obx(() {
        if (progressController.isAiLoading.value && progressController.studyPlan.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (progressController.studyPlan.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_stories, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No study plan generated yet.'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => progressController.loadAiInsights(),
                  child: const Text('Generate Now'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Markdown(
              data: progressController.studyPlan.value,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                p: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            if (progressController.isAiLoading.value)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        );
      }),
    );
  }
}
