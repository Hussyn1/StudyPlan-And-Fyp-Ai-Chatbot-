import 'package:dio/dio.dart';
import '../utils/constants.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    String url = AppConstants.baseUrl;
    if (!url.endsWith('/')) {
      url = '$url/';
    }

    _dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ));

    // Add logging to help debug connectivity
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('API_LOG: $obj'),
    ));

    // add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // We need to avoid circular dependency, so we read prefs directly here
        // or inject AuthProvider later. Reading prefs is safer for now.
        // Actually, we can just read validation from prefs.
        // But better: Let the caller handle token, or read from storage here.
        // Since we are inside ApiService, let's look for token in SharedPreferences
        // Note: importing shared_preferences here
        return handler.next(options); 
      },
    ));
  }

  // Generic POST
  Future<dynamic> postRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Generic GET
  Future<dynamic> getRequest(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParameters);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Generic PUT
  Future<dynamic> putRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  void setToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<Map<String, dynamic>> chat(String studentId, String message) async {
    try {
      final response = await _dio.post('chat', data: {
        'student_id': studentId,
        'message': message,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getProgress(String studentId) async {
    try {
      final response = await _dio.get('progress/$studentId');
      return response.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getTasks(String studentId, {String? courseId, String? status}) async {
    try {
      final response = await _dio.get('tasks/$studentId', queryParameters: {
        if (courseId != null) 'course_id': courseId,
        if (status != null) 'status': status,
      });
      return response.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFypSuggestions(String studentId) async {
    try {
      final response = await _dio.get('fyp/suggestions/$studentId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getAllCourses() async {
    try {
      final response = await _dio.get('courses');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitTask(String studentId, String taskId, String content) async {
    try {
      final response = await _dio.post('tasks/submit', data: {
        'student_id': studentId,
        'task_id': taskId,
        'submission_content': content,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> generateAiTask(String taskId) async {
    try {
      final response = await _dio.post('tasks/$taskId/ai-generate');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getStudyPlan(String studentId) async {
    try {
      final response = await _dio.get('students/$studentId/study-plan');
      return response.data['study_plan'] ?? '';
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getProgressSummary(String studentId) async {
    try {
      final response = await _dio.get('students/$studentId/progress-summary');
      return response.data['summary'] ?? '';
    } catch (e) {
      rethrow;
    }
  }
}

final apiService = ApiService();
