import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/drink_model.dart';

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

  Future<User> consumeLunch({
    required String firstName,
    required String lastName,
    required String gender,
  }) async {
    try {
      final response = await _dio.post(
        '/lunch/',
        data: {
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

  Future<User> consumeDinner({
    required String firstName,
    required String lastName,
    required String gender,
  }) async {
    try {
      final response = await _dio.post(
        '/dinner/',
        data: {
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

  Future<Map<String, dynamic>> consumeDrink({
    required String firstName,
    required String lastName,
    required String gender,
    required String servingPoint,
    required String drinkName,
    int quantity = 1,
  }) async {
    try {
      final response = await _dio.post(
        '/drink/',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'gender': gender,
          'serving_point': servingPoint,
          'drink_name': drinkName,
          'quantity': quantity,
        },
      );

      final data = response.data;
      return {
        'user': User.fromJson(data['user']),
        'transaction': DrinkTransaction.fromJson(data['transaction']),
        'drink_stock_remaining': data['drink_stock_remaining'],
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
        return data['error'];
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
