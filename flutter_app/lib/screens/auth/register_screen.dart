import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../onboarding/onboarding_screen.dart';
import 'package:animate_do/animate_do.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _uniNameController = TextEditingController();
  final _semesterController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController authController = Get.find<AuthController>();

  @override
  void dispose() {
    _nameController.dispose();
    _rollNumberController.dispose();
    _uniNameController.dispose();
    _semesterController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Join AI Study',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start your intelligent learning journey',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 32),
                      _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_rollNumberController, 'Roll Number', Icons.badge_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_uniNameController, 'University', Icons.school_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(_semesterController, 'Semester (1-8)', Icons.calendar_today_outlined, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscureText: true),
                      const SizedBox(height: 32),
                      Obx(() => SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: authController.isLoading.value ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: authController.isLoading.value
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          )),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Already have an account? Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black,
        prefixIcon: Icon(icon, size: 22, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final success = await authController.register({
        'name': _nameController.text,
        'roll_number': _rollNumberController.text,
        'password': _passwordController.text,
        'uni_name': _uniNameController.text,
        'current_semester': int.parse(_semesterController.text),
        'interests': [],
        'weak_subjects': [],
        'study_pace': 'Moderate',
        'learning_style': 'Reading',
      });
      if (success) {
        Get.off(() => const OnboardingScreen());
      } else {
        Get.snackbar('Error', authController.errorMessage.value ?? 'Registration failed', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }
}

