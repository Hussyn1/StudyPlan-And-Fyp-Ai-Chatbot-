import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../controllers/progress_controller.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  final ProgressController progressController = Get.find<ProgressController>();

  @override
  void initState() {
    super.initState();
    // Proactively load if empty
    if (progressController.studyPlan.isEmpty) {
      progressController.loadAiInsights();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (progressController.studyPlan.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_stories, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No study plan generated yet.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => progressController.loadAiInsights(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Generate Now'),
                ),
              ],
            ),
          );
        }

        return SelectionArea(
          child: Stack(
            children: [
              Markdown(
                data: progressController.studyPlan.value,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  p: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white70),
                  tableBody: const TextStyle(fontSize: 14, color: Colors.white70),
                  tableHead: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  tableCellsPadding: const EdgeInsets.all(8),
                  tableBorder: TableBorder.all(color: Colors.white24, width: 1),
                ),
              ),
              if (progressController.isAiLoading.value)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(backgroundColor: Colors.black, color: Colors.white),
                ),
            ],
          ),
        );
      }),
    );
  }
}
