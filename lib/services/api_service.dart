import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/drink_model.dart';

class AuthUser {
  final int id;
  final String username;
  final bool isStaff;

  AuthUser({required this.id, required this.username, required this.isStaff});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      username: (json['username'] ?? '').toString(),
      isStaff: json['is_staff'] == true,
    );
  }
}

class LoginResponse {
  final String access;
  final String refresh;
  final AuthUser user;

  LoginResponse({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      access: (json['access'] ?? '').toString(),
      refresh: (json['refresh'] ?? '').toString(),
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class ChatbotSendResponse {
  final int conversationId;
  final String title;
  final String message;

  ChatbotSendResponse({
    required this.conversationId,
    required this.title,
    required this.message,
  });

  factory ChatbotSendResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotSendResponse(
      conversationId: json['conversation_id'],
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class ChatbotMessage {
  final String role;
  final String content;
  final DateTime? createdAt;

  ChatbotMessage({required this.role, required this.content, this.createdAt});

  factory ChatbotMessage.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at']?.toString();
    return ChatbotMessage(
      role: (json['role'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: createdAtRaw == null || createdAtRaw.isEmpty
          ? null
          : DateTime.tryParse(createdAtRaw),
    );
  }
}

class ChatbotConversationHistory {
  final int conversationId;
  final String title;
  final List<ChatbotMessage> messages;

  ChatbotConversationHistory({
    required this.conversationId,
    required this.title,
    required this.messages,
  });

  factory ChatbotConversationHistory.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawMessages = json['messages'] ?? [];
    return ChatbotConversationHistory(
      conversationId: json['conversation_id'],
      title: (json['title'] ?? '').toString(),
      messages: rawMessages
          .whereType<Map<String, dynamic>>()
          .map(ChatbotMessage.fromJson)
          .toList(),
    );
  }
}

class ChatbotConversationSummary {
  final int id;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChatbotConversationSummary({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatbotConversationSummary.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at']?.toString();
    final updatedAtRaw = json['updated_at']?.toString();
    return ChatbotConversationSummary(
      id: json['id'],
      title: (json['title'] ?? 'Untitled').toString(),
      createdAt: createdAtRaw == null || createdAtRaw.isEmpty
          ? null
          : DateTime.tryParse(createdAtRaw),
      updatedAt: updatedAtRaw == null || updatedAtRaw.isEmpty
          ? null
          : DateTime.tryParse(updatedAtRaw),
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://strucure.cloud/main/api';
  // static const String baseUrl = 'http://192.168.1.64:8000/main/api';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static String? _accessToken;
  static String? _refreshToken;
  static bool _isRefreshing = false;
  static Completer<void>? _refreshCompleter;

  static bool get isLoggedIn =>
      _accessToken != null && _accessToken!.trim().isNotEmpty;

  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await initializeAuth();
          final hasAuthHeader = options.headers.containsKey('Authorization');
          if (_isConsumePath(options.path) && !hasAuthHeader && isLoggedIn) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final requestOptions = error.requestOptions;
          final alreadyRetried = requestOptions.extra['retried'] == true;
          final isAuthRoute = requestOptions.path.contains('/auth/login/') ||
              requestOptions.path.contains('/auth/refresh/');

          if (statusCode == 401 && !alreadyRetried && !isAuthRoute) {
            final refreshed = await _refreshAccessToken();
            if (refreshed) {
              try {
                final retryOptions = Options(
                  method: requestOptions.method,
                  headers: Map<String, dynamic>.from(requestOptions.headers)
                    ..['Authorization'] = 'Bearer $_accessToken',
                  responseType: requestOptions.responseType,
                  contentType: requestOptions.contentType,
                  receiveDataWhenStatusError:
                      requestOptions.receiveDataWhenStatusError,
                  followRedirects: requestOptions.followRedirects,
                  validateStatus: requestOptions.validateStatus,
                  sendTimeout: requestOptions.sendTimeout,
                  receiveTimeout: requestOptions.receiveTimeout,
                  extra: Map<String, dynamic>.from(requestOptions.extra)
                    ..['retried'] = true,
                );

                final retryResponse = await _dio.request<dynamic>(
                  requestOptions.path,
                  data: requestOptions.data,
                  queryParameters: requestOptions.queryParameters,
                  options: retryOptions,
                  cancelToken: requestOptions.cancelToken,
                  onReceiveProgress: requestOptions.onReceiveProgress,
                  onSendProgress: requestOptions.onSendProgress,
                );

                return handler.resolve(retryResponse);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }

            await logoutStatic();
          }

          handler.next(error);
        },
      ),
    );

    // Add interceptor for logging
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print(obj),
      ),
    );
  }

  static Future<void> initializeAuth() async {
    if (_accessToken != null) return;
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
  }

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login/',
        data: {'username': username, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final loginResponse = LoginResponse.fromJson(data);
      await _saveTokens(
        access: loginResponse.access,
        refresh: loginResponse.refresh,
      );

      return loginResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await logoutStatic();
  }

  static Future<void> logoutStatic() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    _accessToken = null;
    _refreshToken = null;
  }

  static Future<void> _saveTokens({
    required String access,
    required String refresh,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
    _accessToken = access;
    _refreshToken = refresh;
  }

  static bool _isConsumePath(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return normalized == '/lunch/' ||
        normalized == '/dinner/' ||
        normalized == '/bbq/' ||
        normalized == '/drink/';
  }

  static Future<bool> _refreshAccessToken() async {
    await initializeAuth();
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    if (_isRefreshing) {
      await _refreshCompleter?.future;
      return isLoggedIn;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await dio.post(
        '/auth/refresh/',
        data: {'refresh': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      final newAccess = (data['access'] ?? '').toString();
      if (newAccess.isEmpty) return false;

      final newRefresh = (data['refresh'] ?? refreshToken).toString();
      await _saveTokens(access: newAccess, refresh: newRefresh);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }

  Future<Options> _authorizedOptions() async {
    await initializeAuth();
    if (!isLoggedIn) {
      throw 'Authentication required. Please login again.';
    }

    return Options(
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
  }

  Future<User> consumeLunch({
    required String firstName,
    required String lastName,
    required String gender,
  }) async {
    try {
      final options = await _authorizedOptions();
      final response = await _dio.post(
        '/lunch/',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'gender': gender,
        },
        options: options,
      );

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> consumeDinner({
    required String firstName,
    required String lastName,
    required String gender,
  }) async {
    try {
      final options = await _authorizedOptions();
      final response = await _dio.post(
        '/dinner/',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'gender': gender,
        },
        options: options,
      );

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> consumeBbq({
    required String firstName,
    required String lastName,
    required String gender,
  }) async {
    try {
      final options = await _authorizedOptions();
      final response = await _dio.post(
        '/bbq/',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'gender': gender,
        },
        options: options,
      );

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> consumeDrink({
    required String firstName,
    required String lastName,
    required String gender,
    required String servingPoint,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final options = await _authorizedOptions();
      final response = await _dio.post(
        '/drink/',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'gender': gender,
          'serving_point': servingPoint,
          'items': items,
        },
        options: options,
      );

      final data = response.data as Map<String, dynamic>;
      final List<dynamic> rawTransactions = data['transactions'] ?? [];
      return {
        'user': User.fromJson(data['user']),
        'transactions': rawTransactions
            .whereType<Map<String, dynamic>>()
            .map(DrinkTransaction.fromJson)
            .toList(),
        'total_requested': data['total_requested'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> getUserStatus({
    required String firstName,
    required String lastName,
    required String gender,
  }) async {
    try {
      final response = await _dio.get(
        '/user/',
        queryParameters: {
          'first_name': firstName,
          'last_name': lastName,
          'gender': gender,
        },
      );

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Drink>> getAvailableDrinks() async {
    try {
      final response = await _dio.get('/drinks/');
      final List<dynamic> data = response.data;
      return data.map((json) => Drink.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ChatbotSendResponse> sendChatbotMessage({
    required String message,
    int? conversationId,
    String? sessionId,
  }) async {
    try {
      final payload = <String, dynamic>{'message': message};
      if (conversationId != null) {
        payload['conversation_id'] = conversationId;
      }
      if (sessionId != null && sessionId.isNotEmpty) {
        payload['session_id'] = sessionId;
      }

      final response = await _dio.post('/chatbot/send/', data: payload);
      return ChatbotSendResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ChatbotConversationHistory> getChatbotConversationHistory({
    required int conversationId,
    String? sessionId,
  }) async {
    try {
      final response = await _dio.get(
        '/chatbot/history/$conversationId/',
        queryParameters: {
          if (sessionId != null && sessionId.isNotEmpty)
            'session_id': sessionId,
        },
      );

      return ChatbotConversationHistory.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ChatbotConversationSummary>> listChatbotConversations({
    required String sessionId,
  }) async {
    try {
      final response = await _dio.get(
        '/chatbot/conversations/',
        queryParameters: {'session_id': sessionId},
      );

      final List<dynamic> data = response.data['conversations'] ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatbotConversationSummary.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    print('==========================================');
    print('DioException Type: ${e.type}');
    print('Status Code: ${e.response?.statusCode}');
    print('Response Data: ${e.response?.data}');
    print('Request URL: ${e.requestOptions.uri}');
    print('Request Method: ${e.requestOptions.method}');
    print('Request Data: ${e.requestOptions.data}');
    print('==========================================');

    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('error')) {
        return data['error'].toString();
      }
      if (data is Map && data.containsKey('detail')) {
        return data['detail'].toString();
      }
      if (data is Map && data.containsKey('non_field_errors')) {
        final errors = data['non_field_errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.join(', ');
        }
      }
      return 'Server error: ${e.response!.statusCode}';
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Please check your network.';
      case DioExceptionType.badResponse:
        return 'Invalid response from server.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'An unexpected error occurred: ${e.message}';
    }
  }
}
