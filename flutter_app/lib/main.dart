import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'bindings/global_binding.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/fyp_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AuthController first to load saved session
  final authController = Get.put(AuthController(), permanent: true);
  await authController.checkAuthStatus();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI Study Chatbot',
      debugShowCheckedModeBanner: false,
      initialBinding: GlobalBinding(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Use AuthWrapper to determine initial route based on auth status
      home: const AuthWrapper(),
      getPages: [
        GetPage(name: '/', page: () => const AuthWrapper()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
        GetPage(name: '/chat', page: () => const ChatScreen()),
        GetPage(name: '/fyp', page: () => const FypScreen()),
      ],
    );
  }
}

// AuthWrapper to handle authentication-based routing
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    
    return Obx(() {
      // Show loading while checking auth status
      if (!authController.isInitialized.value) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      // Route based on authentication status
      if (authController.isAuthenticated.value) {
        return const HomeScreen();
      } else {
        return const LoginScreen();
      }
    });
  }
}
