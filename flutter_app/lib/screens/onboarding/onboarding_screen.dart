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
  int _currentStep = 0;

  // Step 1: Courses
  List<dynamic> semesterCourses = [];
  final List<String> selectedCourseIds = [];
  bool isLoadingCourses = true;

  // Step 2: Interests
  final List<String> selectedInterests = [];
  final List<String> availableInterests = [
    'AI/ML', 'Web Development', 'Mobile Development', 'Cybersecurity',
    'Data Science', 'Cloud Computing', 'Blockchain', 'Game Development',
    'Robotics', 'IoT', 'NLP', 'Computer Vision'
  ];

  // Step 3: Preferences
  String selectedPace = 'Moderate';
  String selectedStyle = 'Reading';
  final List<String> selectedWeakSubjects = [];

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
          child: Obx(() => ElevatedButton(
            onPressed: authController.isLoading.value ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: authController.isLoading.value 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(_currentStep == 2 ? 'Finish' : 'Next'),
          )),
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                final isSelected = selectedCourseIds.contains(course['id'] ?? course['_id']);
                return CheckboxListTile(
                  title: Text(course['name']),
                  subtitle: Text(course['code']),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedCourseIds.add(course['id'] ?? course['_id']);
                      } else {
                        selectedCourseIds.remove(course['id'] ?? course['_id']);
                      }
                    });
                  },
                  activeColor: Colors.indigo,
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  label: Text(interest),
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
                  selectedColor: Colors.indigo.withOpacity(0.2),
                  checkmarkColor: Colors.indigo,
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text('Study Pace', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Slow', label: Text('Slow')),
              ButtonSegment(value: 'Moderate', label: Text('Moderate')),
              ButtonSegment(value: 'Fast', label: Text('Fast')),
            ],
            selected: {selectedPace},
            onSelectionChanged: (set) => setState(() => selectedPace = set.first),
          ),
          const SizedBox(height: 24),
          const Text('Learning Style', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedStyle,
            items: ['Visual', 'Reading', 'Practice', 'Auditary']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) => setState(() => selectedStyle = val!),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          const Text('Weak Subjects (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'e.g. Mathematics, Algorithms',
              border: OutlineInputBorder(),
              helperText: 'Type subjects you struggle with, separate by comma',
            ),
            onChanged: (val) {
              setState(() {
                selectedWeakSubjects.clear();
                selectedWeakSubjects.addAll(val.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
              });
            },
          ),
        ],
      ),
    );
  }
}
