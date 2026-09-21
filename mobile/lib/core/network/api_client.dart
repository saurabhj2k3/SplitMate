import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static const String _tokenKey = 'splitmate_auth_token';
  static const String _userKey = 'splitmate_auth_user';

  final Dio _dio;
  String? _token;

  ApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? _getDefaultBaseUrl(),
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Extract user-friendly error message
          String message = 'Unable to connect. Please check your connection and try again.';
          if (error.response?.data != null && error.response?.data is Map) {
            final data = error.response!.data as Map;
            if (data['message'] != null) {
              message = data['message'].toString();
            }
          }
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: message,
              message: message,
            ),
          );
        },
      ),
    );
  }

  static String _getDefaultBaseUrl() {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.contains('localhost') || host == '127.0.0.1') {
        return 'http://localhost:5000/api/v1';
      }
      return 'https://split-mate-blcq.vercel.app/api/v1';
    }
    // Android emulator / physical device fallback
    return 'https://split-mate-blcq.vercel.app/api/v1';
  }

  Dio get client => _dio;

  Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    }
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
}

final apiClient = ApiClient();
