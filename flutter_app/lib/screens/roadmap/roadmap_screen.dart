import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';

class RoadmapScreen extends StatefulWidget {
  final String interest;

  const RoadmapScreen({super.key, required this.interest});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final AuthController authController = Get.find<AuthController>();
  bool _isLoading = true;
  Map<String, dynamic>? _roadmapData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRoadmap();
  }

  Future<void> _fetchRoadmap() async {
    try {
      final studentId = authController.currentStudent.value?.id;
      if (studentId == null) {
        throw "Student ID not found";
      }

      final data = await apiService.getInterestRoadmap(studentId, widget.interest);
      setState(() {
        _roadmapData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.interest} Roadmap', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.indigoAccent));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading roadmap:\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchRoadmap();
                },
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    if (_roadmapData == null) {
      return const Center(child: Text("No data available", style: TextStyle(color: Colors.white)));
    }

    final phases = _roadmapData!['phases'] as List<dynamic>? ?? [];
    final resources = _roadmapData!['resources'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          const Text(
            "Learning Path",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
          ),
          const SizedBox(height: 16),
          ...phases.asMap().entries.map((entry) => _buildPhaseCard(entry.value, entry.key)),
          const SizedBox(height: 24),
          const Text(
            "Recommended Resources",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
          ),
          const SizedBox(height: 16),
          ...resources.map((r) => _buildResourceTile(r)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.purple.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Personalized Guide",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Mastering ${widget.interest}",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(Map<String, dynamic> phase, int phaseIndex) {
    final topics = (phase['topics'] as List<dynamic>? ?? []);
    final isCompleted = phase['is_completed'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.white10),
      ),
      child: ExpansionTile(
        initiallyExpanded: phaseIndex == (_roadmapData?['current_phase_index'] ?? 0),
        title: Row(
          children: [
            if (isCompleted) const Icon(Icons.check_circle, color: Colors.green, size: 20),
            if (isCompleted) const SizedBox(width: 8),
            Text(
              phase['title'] ?? 'Phase',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        subtitle: Text(
          phase['duration'] ?? '',
          style: TextStyle(color: Colors.indigoAccent.withOpacity(0.8), fontSize: 12),
        ),
        collapsedIconColor: Colors.grey,
        iconColor: Colors.indigoAccent,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          _buildSectionTitle("Key Topics"),
          ...topics.asMap().entries.map((entry) {
             final index = entry.key;
             final topic = entry.value;
             return _buildTopicTile(topic, phaseIndex, index);
          }).toList(),
          const SizedBox(height: 16),
          _buildSectionTitle("Project Goal"),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.indigoAccent.withOpacity(0.2))
            ),
            child: Row(
              children: [
                const Icon(Icons.rocket_launch, color: Colors.orangeAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    phase['project'] ?? 'Complete a hands-on project.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicTile(dynamic topicData, int phaseIndex, int topicIndex) {
    // Handle both string (old schema) and object (new schema)
    String title = "";
    String status = "pending";
    
    if (topicData is String) {
      title = topicData;
    } else {
      title = topicData['title'] ?? "";
      status = topicData['status'] ?? "pending";
    }

    final isDone = status == "completed";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.withOpacity(0.1) : Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        leading: Checkbox(
          value: isDone,
          activeColor: Colors.green,
          side: const BorderSide(color: Colors.white54),
          onChanged: (val) {
             _updateTopicStatus(phaseIndex, topicIndex, val == true ? "completed" : "pending");
          },
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDone ? Colors.white54 : Colors.white,
            decoration: isDone ? TextDecoration.lineThrough : null,
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.indigoAccent),
          tooltip: "Ask Bot about this",
          onPressed: () {
            _askBotAboutTopic(title);
          },
        ),
      ),
    );
  }

  Future<void> _updateTopicStatus(int phaseIndex, int topicIndex, String status) async {
    // Optimistic Update
    setState(() {
       final phases = _roadmapData!['phases'] as List;
       final topics = phases[phaseIndex]['topics'] as List;
       if (topics[topicIndex] is Map) {
         topics[topicIndex]['status'] = status;
       } else {
         // Convert string to map if needed (fallback)
         topics[topicIndex] = {'title': topics[topicIndex], 'status': status};
       }
    });

    try {
      final studentId = authController.currentStudent.value?.id;
      if (studentId != null) {
        await apiService.updateRoadmapProgress(studentId, widget.interest, phaseIndex, topicIndex, status);
      }
    } catch (e) {
      // Revert if failed (omitted for brevity, ideally would revert)
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e")));
      }
    }
  }

  void _askBotAboutTopic(String topic) {
    // Navigate to Chat with pre-filled message
    // Assuming we have a ChatScreen that can accept an initial message or we just pop with a result
    // But since this is a separate screen, we likely use Get.toNamed('/chat', arguments: ...)
    // Or better, switch the Main Tab to Chat?
    // Let's use Get.toNamed if we have proper routing arguments, or direct navigation
    
    // Simplest: Go to ChatScreen with a "prompt" argument
    // We need to update ChatScreen to handle arguments
    Get.toNamed('/chat', arguments: {"initialMessage": "I want to learn about $topic in my ${widget.interest} roadmap. Can you help me?"});
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: Colors.indigoAccent, margin: const EdgeInsets.only(right: 8)),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildResourceTile(String resource) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.link, color: Colors.indigoAccent),
        title: Text(
          resource,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        onTap: () {
          // TODO: Open URL
        },
      ),
    );
  }
}
