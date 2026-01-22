class Student {
  final String id;
  final String rollNumber;
  final String name;
  final String uniName;
  final int currentSemester;
  final List<String> interests;
  final List<String> weakSubjects;
  final String studyPace; // Slow, Moderate, Fast
  final String learningStyle; // Visual, Reading, Practice

  Student({
    required this.id,
    required this.rollNumber,
    required this.name,
    required this.uniName,
    required this.currentSemester,
    required this.interests,
    required this.weakSubjects,
    required this.studyPace,
    required this.learningStyle,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? json['id'] ?? '',
      rollNumber: json['roll_number'] ?? '',
      name: json['name'] ?? '',
      uniName: json['uni_name'] ?? '',
      currentSemester: json['current_semester'] ?? 1,
      interests: List<String>.from(json['interests'] ?? []),
      weakSubjects: List<String>.from(json['weak_subjects'] ?? []),
      studyPace: json['study_pace'] ?? 'Moderate',
      learningStyle: json['learning_style'] ?? 'Reading',
    );
  }
}

class Course {
  final String id;
  final String code;
  final String name;
  final String? description;
  final int semester;
  final List<String> topics;

  Course({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.semester,
    required this.topics,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      semester: json['semester'] ?? 1,
      topics: List<String>.from(json['topics'] ?? []),
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String? courseId;
  final String studentId;
  final String status; // pending, completed, failed
  final String type; // theory, coding, mcq
  final String difficulty; // easy, medium, hard
  final int score;
  final DateTime createdAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.courseId,
    required this.studentId,
    required this.status,
    required this.type,
    required this.difficulty,
    this.score = 0,
    required this.createdAt,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      courseId: json['course_id'],
      studentId: json['student_id'] ?? '',
      status: json['status'] ?? 'pending',
      type: json['type'] ?? 'theory',
      difficulty: json['difficulty'] ?? 'medium',
      score: json['score'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
    );
  }
}

enum MessageSender { user, assistant }

class ChatMessage {
  final String message;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.sender,
    required this.timestamp,
  });
}
