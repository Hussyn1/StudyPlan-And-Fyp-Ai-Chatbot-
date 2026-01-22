import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/fyp_project.dart';
import '../controllers/fyp_controller.dart';
import 'fyp_details_sheet.dart';

class FypCard extends StatelessWidget {
  final FYPProject fyp;

  const FypCard({super.key, required this.fyp});

  @override
  Widget build(BuildContext context) {
    final fypController = Get.find<FypController>();
    final matchScore = fyp.matchScore;
    final skills = fyp.matchingSkills;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fyp.category,
                    style: const TextStyle(color: Colors.indigoAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(matchScore * 100).toInt()}% Match',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              fyp.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              fyp.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Text(
              'Matching Skills:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: skills.map((skill) => Chip(
                label: Text(skill, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                backgroundColor: Colors.black,
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Show loading
                  Get.dialog(
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                    barrierDismissible: false,
                  );

                  final details = await fypController.loadFypDetails(fyp.id ?? '');
                  Get.back(); // Close loading

                  if (details != null) {
                    Get.bottomSheet(
                      FypDetailsSheet(fyp: fyp, details: details),
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
