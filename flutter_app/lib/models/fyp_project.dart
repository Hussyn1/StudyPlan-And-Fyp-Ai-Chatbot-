class FYPProject {
  final String? id;
  final String title;
  final String description;
  final int score;
  final double matchScore;
  final String category;
  final List<String> matchingSkills;
  final String rationale;

  FYPProject({
    this.id,
    required this.title,
    required this.description,
    required this.score,
    required this.matchScore,
    required this.category,
    required this.matchingSkills,
    required this.rationale,
  });

  factory FYPProject.fromJson(Map<String, dynamic> json) {
    return FYPProject(
      id: json['_id'] ?? json['id']?.toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      score: json['score'] ?? 0,
      matchScore: ((json['match_score'] ?? 0.0) as num).toDouble(),
      category: json['category'] ?? 'General',
      matchingSkills: List<String>.from(json['matching_skills'] ?? []),
      rationale: json['rationale'] ?? '',
    );
  }
}
