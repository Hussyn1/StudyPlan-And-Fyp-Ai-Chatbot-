import 'package:get/get.dart';
import '../services/api_service.dart';
import '../models/fyp_project.dart';
import 'auth_controller.dart';

class FypController extends GetxController {
  final ApiService _apiService = apiService;
  
  final RxList<FYPProject> suggestions = <FYPProject>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  Future<void> loadSuggestions() async {
    final authController = Get.find<AuthController>();
    final studentId = authController.studentId.value;

    if (studentId == null) {
      errorMessage.value = 'Not authenticated';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _apiService.getFypSuggestions(studentId);
      
      if (response['suggestions'] != null) {
        suggestions.value = (response['suggestions'] as List)
            .map((json) => FYPProject.fromJson(json))
            .toList();
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
