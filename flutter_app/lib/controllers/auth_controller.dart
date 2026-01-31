import 'package:flutter/material.dart';
import 'package:flutter_app/models/models.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'chat_controller.dart';
import 'progress_controller.dart';
import 'fyp_controller.dart';
import 'task_controller.dart';

class AuthController extends GetxController {
  final ApiService _apiService = apiService;
  
  // Reactive variables
  final Rx<String?> studentId = Rx<String?>(null);
  final Rx<Student?> currentStudent = Rx<Student?>(null);
  final RxBool isLoading = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);
  final RxBool isAuthenticated = false.obs;
  final RxBool isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('student_id');
    if (id != null && id.isNotEmpty) {
      studentId.value = id;
      isAuthenticated.value = true;
      await getStudentProfile(); // Fetch profile details on start
    }
    isInitialized.value = true;
  }

  Future<bool> login(String rollNumber, String password) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _apiService.postRequest('auth/login', {
        'roll_number': rollNumber,
        'password': password,
      });

      if (response['student_id'] != null) {
        studentId.value = response['student_id'];
        isAuthenticated.value = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('student_id', response['student_id']);
        
        await getStudentProfile(); // Fetch full profile data after login
        
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = 'Invalid credentials';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Login Failed', 
        errorMessage.value!,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[800],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> studentData) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _apiService.postRequest('students', studentData);

      if (response['_id'] != null || response['id'] != null) {
        studentId.value = response['_id'] ?? response['id'];
        isAuthenticated.value = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('student_id', studentId.value!);
        
        await getStudentProfile(); // Fetch full profile data after registration
        
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = 'Registration failed';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Registration Failed', 
        errorMessage.value!,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[800],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
      isLoading.value = false;
      return false;
    }
  }

  Future<void> logout() async {
    // Clear all user-specific controllers
    try {
      Get.find<ChatController>().clearData();
      Get.find<ProgressController>().clearData();
      Get.find<FypController>().clearData();
      Get.find<TaskController>().clearData();
    } catch (e) {
      print("Error clearing controllers: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('student_id');
    studentId.value = null;
    currentStudent.value = null; // Clear student profile data
    isAuthenticated.value = false;
  }

  Future<bool> updateProfile(Map<String, dynamic> updateData) async {
    if (studentId.value == null) return false;
    isLoading.value = true;
    try {
      final response = await _apiService.putRequest('students/${studentId.value}', updateData);
      currentStudent.value = Student.fromJson(response); // Update reactive profile
      
      Get.snackbar(
        'Success', 
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[800],
        colorText: Colors.white,
      );
      
      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        'Update Failed', 
        errorMessage.value!,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[800],
        colorText: Colors.white,
      );
      isLoading.value = false;
      return false;
    }
  }

  Future<List<dynamic>> fetchSemesterCourses(int semester) async {
    try {
      final response = await _apiService.getRequest('courses/semester/$semester');
      return response as List<dynamic>;
    } catch (e) {
      errorMessage.value = e.toString();
      return [];
    }
  }

  Future<bool> enrollInCourses(List<String> courseIds) async {
    if (studentId.value == null) return false;
    isLoading.value = true;
    try {
      await _apiService.postRequest('students/${studentId.value}/enroll', {
        'course_ids': courseIds,
      });
      isLoading.value = false;
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
      return false;
    }
  }

  Future<Map<String, dynamic>?> getStudentProfile() async {
    if (studentId.value == null) return null;
    try {
      final response = await _apiService.getRequest('students/${studentId.value}');
      currentStudent.value = Student.fromJson(response);
      return response as Map<String, dynamic>;
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }
}
