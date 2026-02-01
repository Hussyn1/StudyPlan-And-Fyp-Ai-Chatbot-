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

  // Centralized Error Handler
  String _handleError(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.sendTimeout) {
        return "Connection timed out. Please check your internet.";
      } else if (e.type == DioExceptionType.connectionError) {
        return "Unable to connect to the server. Is it running?";
      } else if (e.response != null) {
        // Server responded with error
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'];
        }
        return "Server Error: ${e.response?.statusCode}";
      }
    }
    return "An unexpected error occurred: ${e.toString()}";
  }

  // Generic POST
  Future<dynamic> postRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Generic GET
  Future<dynamic> getRequest(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParameters);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Generic PUT
  Future<dynamic> putRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } catch (e) {
      throw _handleError(e);
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
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getProgress(String studentId) async {
    try {
      final response = await _dio.get('progress/$studentId');
      return response.data as List<dynamic>;
    } catch (e) {
      throw _handleError(e);
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
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getFypSuggestions(String studentId) async {
    try {
      final response = await _dio.get('fyp/suggestions/$studentId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getFypDetails(String projectId) async {
    try {
      final response = await _dio.get('fyp/details/$projectId');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getAllCourses() async {
    try {
      final response = await _dio.get('courses');
      return response.data;
    } catch (e) {
      throw _handleError(e);
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
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> generateAiTask(String taskId) async {
    try {
      final response = await _dio.post('tasks/$taskId/ai-generate');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> generateNewTask(String studentId, String courseId, String topic) async {
    try {
      final response = await _dio.post('chat/generate-task', data: {
        'student_id': studentId,
        'course_id': courseId,
        'topic': topic,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> getStudyPlan(String studentId) async {
    try {
      final response = await _dio.get('students/$studentId/study-plan');
      final data = response.data;
      if (data is Map) {
        return data['study_plan']?.toString() ?? '';
      }
      return '';
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> getProgressSummary(String studentId) async {
    try {
      final response = await _dio.get('students/$studentId/progress-summary');
      final data = response.data;
      if (data is Map) {
        return data['summary']?.toString() ?? '';
      }
      return '';
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getInterestRoadmap(String studentId, String? interest) async {
    try {
      final response = await _dio.get('students/$studentId/roadmap', queryParameters: {
        if (interest != null && interest.isNotEmpty) 'interest': interest,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  Future<Map<String, dynamic>> updateRoadmapProgress(String studentId, String interest, int phaseIndex, int topicIndex, String status) async {
    try {
      final response = await _dio.post('students/$studentId/roadmap/update', data: {
        'status': status,
      }, queryParameters: {
        'interest': interest,
        'phase_index': phaseIndex,
        'topic_index': topicIndex,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
}

final apiService = ApiService();
