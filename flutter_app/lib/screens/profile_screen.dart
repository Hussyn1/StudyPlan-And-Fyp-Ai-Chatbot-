import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../models/models.dart';
import 'roadmap/roadmap_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController authController = Get.find<AuthController>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _uniController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();
  final TextEditingController _weakSubjectsController = TextEditingController();
  
  String _selectedPace = 'Moderate';
  String _selectedStyle = 'Reading';

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final student = authController.currentStudent.value;
    if (student != null) {
      _nameController.text = student.name;
      _uniController.text = student.uniName;
      _semesterController.text = student.currentSemester.toString();
      _interestsController.text = student.interests.join(', ');
      _weakSubjectsController.text = student.weakSubjects.join(', ');
      _selectedPace = student.studyPace;
      _selectedStyle = student.learningStyle;
    }
  }

  void _saveProfile() async {
    final Map<String, dynamic> updateData = {
      'name': _nameController.text,
      'uni_name': _uniController.text,
      'current_semester': int.tryParse(_semesterController.text) ?? 1,
      'interests': _interestsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'weak_subjects': _weakSubjectsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'study_pace': _selectedPace,
      'learning_style': _selectedStyle,
    };

    await authController.updateProfile(updateData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 30),
            _buildSection(
              title: 'Personal Information',
              icon: Icons.person_outline,
              children: [
                _buildTextField('Full Name', _nameController, Icons.badge_outlined),
                _buildTextField('University', _uniController, Icons.account_balance_outlined),
                _buildTextField('Current Semester', _semesterController, Icons.school_outlined, isNumber: true),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Learning Preferences',
              icon: Icons.psychology_outlined,
              children: [
                _buildDropdown('Study Pace', ['Slow', 'Moderate', 'Fast'], _selectedPace, (v) => setState(() => _selectedPace = v!)),
                _buildDropdown('Learning Style', ['Visual', 'Reading', 'Practice'], _selectedStyle, (v) => setState(() => _selectedStyle = v!)),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Academic Focus',
              icon: Icons.interests_outlined,
              children: [
                _buildTextField('Interests (comma separated)', _interestsController, Icons.star_outline),
                _buildTextField('Weak Subjects (comma separated)', _weakSubjectsController, Icons.warning_amber_outlined),
              ],
            ),
            const SizedBox(height: 40),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Obx(() {
      final student = authController.currentStudent.value;
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Colors.indigoAccent, Colors.purpleAccent]),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[900],
              child: Text(
                student?.name.isNotEmpty == true ? student!.name[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            student?.name ?? 'User',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            student?.rollNumber ?? 'Roll Number',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      );
    });
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.indigoAccent, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const Divider(height: 30, color: Colors.white10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigoAccent)),
          filled: true,
          fillColor: Colors.black,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        style: const TextStyle(color: Colors.white),
        dropdownColor: Colors.grey[900],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.tune, size: 20, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigoAccent)),
          filled: true,
          fillColor: Colors.black,
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () {
               final interest = _interestsController.text.split(',').firstOrNull?.trim() ?? "Computer Science";
               Get.to(() => RoadmapScreen(interest: interest));
            },
            icon: const Icon(Icons.map, color: Colors.white),
            label: const Text('Generate Roadmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton.icon(
            onPressed: () {
              authController.logout();
              Get.offAllNamed('/login');
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
