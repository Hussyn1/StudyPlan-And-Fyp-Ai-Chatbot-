import 'package:get/get.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';

class ProgressController extends GetxController {
  final ApiService _apiService = apiService;
  
  final RxList<dynamic> progressList = <dynamic>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);
  
  // New AI fields
  final RxString studyPlan = ''.obs;
  final RxString progressSummary = ''.obs;
  final RxBool isAiLoading = false.obs;

  Future<void> loadProgress() async {
    final authController = Get.find<AuthController>();
    final studentId = authController.studentId.value;

    if (studentId == null) {
      errorMessage.value = 'Not authenticated';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _apiService.getProgress(studentId);
      progressList.value = response as List? ?? [];
      
      // Load AI data as well
      loadAiInsights();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAiInsights() async {
    final authController = Get.find<AuthController>();
    final studentId = authController.studentId.value;
    if (studentId == null) return;

    isAiLoading.value = true;
    try {
      // Load summary and plan in parallel
      final results = await Future.wait([
        _apiService.getProgressSummary(studentId),
        _apiService.getStudyPlan(studentId),
      ]);
      
      progressSummary.value = results[0];
      studyPlan.value = results[1];
    } catch (e) {
      print("Error loading AI insights: $e");
    } finally {
      isAiLoading.value = false;
    }
  }
}
