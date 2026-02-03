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

  int get pendingTasksCount => tasks.where((t) => t.status != 'completed').length;

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

  Future<Map<String, dynamic>?> submitTask(String taskId, String content) async {
    final authController = Get.find<AuthController>();
    final studentId = authController.studentId.value;

    if (studentId == null) {
      errorMessage.value = 'Not authenticated';
      return null;
    }

    try {
      final response = await _apiService.submitTask(studentId, taskId, content);
      
      // Refresh tasks and progress
      await loadTasks();
      Get.find<ProgressController>().loadProgress();
      
      return response;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Submission Failed', errorMessage.value!);
      return null;
    }
  }

  Future<Task?> generateAiTask(String taskId) async {
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
    }
  }

  void clearData() {
    tasks.clear();
    errorMessage.value = null;
    isLoading.value = false;
  }
}
