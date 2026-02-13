import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/drink_model.dart';

class ApiService {
  static const String baseUrl = 'http://104.248.187.7:8000/main/api';
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for logging
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => print(obj),
    ));
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
