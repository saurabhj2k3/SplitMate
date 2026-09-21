import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? token;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.token,
    this.error,
  });

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? token,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoading: true)) {
    loadSession();
  }

  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('splitmate_auth_token');
      final userJson = prefs.getString('splitmate_auth_user');

      if (token != null && userJson != null) {
        await apiClient.setToken(token);
        final user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        state = AuthState(user: user, token: token, isLoading: false);
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (_) {
      state = const AuthState(isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.client.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });

      final data = response.data['data'];
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      await apiClient.setToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('splitmate_auth_user', jsonEncode(user.toJson()));

      state = AuthState(user: user, token: token, isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Login failed. Please check your credentials.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.client.post('/auth/register', data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'phone': phone?.trim(),
      });

      final data = response.data['data'];
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      await apiClient.setToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('splitmate_auth_user', jsonEncode(user.toJson()));

      state = AuthState(user: user, token: token, isLoading: false);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Registration failed. Please try again.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    try {
      final response = await apiClient.client.patch('/users/me', data: {
        if (name != null) 'name': name.trim(),
        if (phone != null) 'phone': phone.trim(),
      });
      final updatedUser = UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('splitmate_auth_user', jsonEncode(updatedUser.toJson()));
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.client.post('/auth/logout');
    } catch (_) {}
    await apiClient.setToken(null);
    state = const AuthState(isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
