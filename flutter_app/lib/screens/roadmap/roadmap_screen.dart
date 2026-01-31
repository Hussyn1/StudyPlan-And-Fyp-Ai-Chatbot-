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
          ...phases.map((phase) => _buildPhaseCard(phase)),
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

  Widget _buildPhaseCard(Map<String, dynamic> phase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ExpansionTile(
        title: Text(
          phase['title'] ?? 'Phase',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          phase['duration'] ?? '',
          style: TextStyle(color: Colors.indigoAccent.withOpacity(0.8), fontSize: 12),
        ),
        collapsedIconColor: Colors.grey,
        iconColor: Colors.indigoAccent,
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          _buildSectionTitle("Key Topics"),
          Wrap(
            spacing: 8,
            children: (phase['topics'] as List<dynamic>? ?? []).map<Widget>((topic) {
              return Chip(
                label: Text(topic.toString(), style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.indigo.withOpacity(0.2),
                labelStyle: const TextStyle(color: Colors.white),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildSectionTitle("Project Goal"),
          Text(
            phase['project'] ?? 'Complete a hands-on project.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
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
