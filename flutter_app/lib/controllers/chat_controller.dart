import 'package:get/get.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'auth_controller.dart';

class ChatController extends GetxController {
  final ApiService _apiService = apiService;
  
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  Future<void> sendMessage(String message) async {
    final authController = Get.find<AuthController>();
    final studentId = authController.studentId.value;

    if (studentId == null) {
      errorMessage.value = 'Not authenticated';
      return;
    }

    // Add user message
    messages.add(ChatMessage(
      message: message,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    ));

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _apiService.chat(studentId, message);
      
      final bool isError = response['is_error'] ?? false;
      
      // Add AI response
      messages.add(ChatMessage(
        message: response['response'] ?? 'No response',
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
      ));

      if (isError) {
        errorMessage.value = response['response'];
      }
    } catch (e) {
      errorMessage.value = e.toString();
      // We don't show snackbar here because the chat bubble itself can show the error message 
      // or we can just append an error message to the list.
    } finally {
      isLoading.value = false;
    }
  }

  void clearData() {
    messages.clear();
    errorMessage.value = null;
    isLoading.value = false;
  }
}
