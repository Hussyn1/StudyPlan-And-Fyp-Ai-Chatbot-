class FYPProject {
  final String title;
  final String description;
  final int score;
  final double matchScore;
  final String category;
  final List<String> matchingSkills;
  final String rationale;

  FYPProject({
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
