import 'package:get/get.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'auth_controller.dart';
import 'progress_controller.dart';

class TaskController extends GetxController {
  final ApiService _apiService = apiService;
  
  final RxList<Task> tasks = <Task>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  Future<void> loadTasks({String? courseId, String? status}) async {
    final authController = Get.find<AuthController>();
    final studentId = authController.studentId.value;

    if (studentId == null) {
      errorMessage.value = 'Not authenticated';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _apiService.getTasks(
        studentId,
        courseId: courseId,
        status: status,
      );
      
      tasks.value = response.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitTask(String taskId, String content) async {
    final authController = Get.find<AuthController>();
    final studentId = authController.studentId.value;

    if (studentId == null) {
      errorMessage.value = 'Not authenticated';
      return false;
    }

    try {
      await _apiService.submitTask(studentId, taskId, content);
      
      // Refresh tasks and progress
      await loadTasks();
      Get.find<ProgressController>().loadProgress();
      
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    }
  }

  Future<Task?> generateAiTask(String taskId) async {
    isLoading.value = true;
    try {
      final response = await _apiService.generateAiTask(taskId);
      final updatedTask = Task.fromJson(response);
      
      // Update local task in list
      int index = tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        tasks[index] = updatedTask;
      }
      
      return updatedTask;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
