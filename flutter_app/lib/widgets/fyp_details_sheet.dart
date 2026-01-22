import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../models/fyp_project.dart';

class FypDetailsSheet extends StatelessWidget {
  final FYPProject fyp;
  final Map<String, dynamic> details;

  const FypDetailsSheet({super.key, required this.fyp, required this.details});

  @override
  Widget build(BuildContext context) {
    final roadmap = (details['roadmap'] as List? ?? []);
    final techStack = (details['tech_stack'] as Map? ?? {});
    final features = (details['key_features'] as List? ?? []);
    final gems = (details['learning_gems'] as List? ?? []);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fyp.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(fyp.category, style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${(fyp.matchScore * 100).toInt()}%',
                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 32),
            
            _buildSectionTitle('Implementation Roadmap', Icons.alt_route),
            const SizedBox(height: 16),
            ...roadmap.map((phase) => _buildRoadmapPhase(
                  phase['phase'] ?? 'Next Step',
                  (phase['tasks'] as List? ?? []).cast<String>(),
                )),
                
            const SizedBox(height: 24),
            _buildSectionTitle('Recommended Tech Stack', Icons.architecture),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: techStack.entries.map((e) => _buildTechItem(e.key, e.value.toString())).toList(),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Key Features', Icons.featured_play_list),
            const SizedBox(height: 12),
            ...features.map((f) => _buildBulletItem(f.toString())),

            const SizedBox(height: 24),
            _buildSectionTitle('Learning Gems', Icons.diamond_outlined),
            const SizedBox(height: 12),
            ...gems.map((g) => _buildGemItem(g.toString())),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Start Working on This', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigoAccent, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildRoadmapPhase(String phase, List<String> tasks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Text(phase, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tasks.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text('• $t', style: const TextStyle(color: Colors.white60, fontSize: 13)),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(String type, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildGemItem(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 16),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
