import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/fyp_controller.dart';
import '../controllers/progress_controller.dart';
import '../controllers/task_controller.dart';

class GlobalBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is already put in main() for immediate check
    // but we can also use lazyPut here with fenix: true to ensure it stays available
    Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => ChatController(), fenix: true);
    Get.lazyPut(() => FypController(), fenix: true);
    Get.lazyPut(() => ProgressController(), fenix: true);
    Get.lazyPut(() => TaskController(), fenix: true);
  }
}
