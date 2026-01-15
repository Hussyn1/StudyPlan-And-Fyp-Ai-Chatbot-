import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../onboarding/onboarding_screen.dart';

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
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rollNumberController,
                decoration: const InputDecoration(
                  labelText: 'Roll Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) => value!.isEmpty ? 'Roll number is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _uniNameController,
                decoration: const InputDecoration(
                  labelText: 'University Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                validator: (value) => value!.isEmpty ? 'University name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _semesterController,
                decoration: const InputDecoration(
                  labelText: 'Current Semester (1-8)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Semester is required';
                  final sem = int.tryParse(value);
                  if (sem == null || sem < 1 || sem > 8) return 'Enter 1-8';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) => 
                  value!.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 24),
              Obx(() => SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authController.isLoading.value 
                        ? null 
                        : () async {
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
                                Get.snackbar(
                                  'Registration Failed',
                                  authController.errorMessage.value ?? 'Please try again',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: authController.isLoading.value 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Register', style: TextStyle(fontSize: 16)),
                    ),
                  )),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
