import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AuthController authController = Get.find<AuthController>();
  final PageController _pageController = PageController();
  final TextEditingController _weakSubjectsController = TextEditingController();
  int _currentStep = 0;

  // Step 1: Courses
  List<dynamic> semesterCourses = [];
  final List<String> selectedCourseIds = [];
  bool isLoadingCourses = true;

  // Step 2: Interests
  final List<String> selectedInterests = [];
  final List<String> availableInterests = [
    'AI/ML',
    'Web Development',
    'Mobile Development',
    'Cybersecurity',
    'Data Science',
    'Cloud Computing',
    'Blockchain',
    'Game Development',
    'Robotics',
    'IoT',
    'NLP',
    'Computer Vision',
  ];

  // Step 3: Preferences
  String selectedPace = 'Moderate';
  String selectedStyle = 'Reading';
  final List<String> selectedWeakSubjects = [];

  @override
  void dispose() {
    _pageController.dispose();
    _weakSubjectsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadOnboardingData();
  }

  Future<void> _loadOnboardingData() async {
    final profile = await authController.getStudentProfile();
    if (profile != null) {
      final semester = profile['current_semester'] ?? 1;
      final courses = await authController.fetchSemesterCourses(semester);

      setState(() {
        semesterCourses = courses;
        isLoadingCourses = false;

        // Pre-fill interests
        if (profile['interests'] != null && profile['interests'] is List) {
          selectedInterests.clear();
          for (var i in profile['interests']) {
            if (availableInterests.contains(i.toString())) {
              selectedInterests.add(i.toString());
            }
          }
        }

        // Pre-fill preferences
        if (profile['study_pace'] != null) {
          selectedPace = profile['study_pace'];
        }

        if (profile['learning_style'] != null) {
          final style = profile['learning_style'];
          if (['Visual', 'Reading', 'Practice', 'Auditary'].contains(style)) {
            selectedStyle = style;
          }
        }

        if (profile['weak_subjects'] != null &&
            profile['weak_subjects'] is List) {
          selectedWeakSubjects.clear();
          final subjects = (profile['weak_subjects'] as List)
              .map((e) => e.toString())
              .toList();
          selectedWeakSubjects.addAll(subjects);
          _weakSubjectsController.text = subjects.join(', ');
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    // 1. Enroll in courses
    if (selectedCourseIds.isNotEmpty) {
      await authController.enrollInCourses(selectedCourseIds);
    }

    // 2. Update profile with interests and preferences
    await authController.updateProfile({
      'interests': selectedInterests,
      'study_pace': selectedPace,
      'learning_style': selectedStyle,
      'weak_subjects': selectedWeakSubjects,
    });

    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Onboarding: Step ${_currentStep + 1} of 3'),
        automaticallyImplyLeading: false,
        actions: [
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                setState(() => _currentStep--);
              },
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildCourseStep(),
          _buildInterestStep(),
          _buildPreferenceStep(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Obx(
            () => ElevatedButton(
              onPressed: authController.isLoading.value ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: authController.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(
                      _currentStep == 2 ? 'Finish' : 'Next',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseStep() {
    if (isLoadingCourses) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Semester Courses',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the courses you are currently taking',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: semesterCourses.length,
              itemBuilder: (context, index) {
                final course = semesterCourses[index];
                final courseId = (course['id'] ?? course['_id']).toString();
                final isSelected = selectedCourseIds.contains(courseId);
                return CheckboxListTile(
                  title: Text(
                    course['name'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    course['code'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedCourseIds.add(courseId);
                      } else {
                        selectedCourseIds.remove(courseId);
                      }
                    });
                  },
                  activeColor: Colors.indigoAccent,
                  checkColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Areas of Interest',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select domains you want to explore for projects',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableInterests.map((interest) {
                final isSelected = selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(
                    interest,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedInterests.add(interest);
                      } else {
                        selectedInterests.remove(interest);
                      }
                    });
                  },
                  selectedColor: Colors.white,
                  checkmarkColor: Colors.black,
                  backgroundColor: Colors.grey[900],
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalize Your Plan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Study Pace',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Slow', label: Text('Slow')),
              ButtonSegment(value: 'Moderate', label: Text('Moderate')),
              ButtonSegment(value: 'Fast', label: Text('Fast')),
            ],
            selected: {selectedPace},
            onSelectionChanged: (set) =>
                setState(() => selectedPace = set.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.black,
              selectedBackgroundColor: Colors.white,
              selectedForegroundColor: Colors.black,
              foregroundColor: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Learning Style',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedStyle,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            items: ['Visual', 'Reading', 'Practice', 'Auditary']
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: const TextStyle(color: Colors.white)),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => selectedStyle = val!),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Weak Subjects (Optional)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weakSubjectsController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. Mathematics, Algorithms',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              helperText: 'Type subjects you struggle with, separate by comma',
              helperStyle: const TextStyle(color: Colors.grey),
            ),
            onChanged: (val) {
              setState(() {
                selectedWeakSubjects.clear();
                selectedWeakSubjects.addAll(
                  val
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty),
                );
              });
            },
          ),
        ],
      ),
    );
  }
}
