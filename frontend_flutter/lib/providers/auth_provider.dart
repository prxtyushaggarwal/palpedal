import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  UserModel? _user;
  bool _isLoading = false;

  String? get token => _token;
  UserModel? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');
    if (userJson != null) {
      _user = UserModel.fromJson(jsonDecode(userJson));
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.login(username, password);
      _isLoading = false;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        _user = UserModel.fromJson(data['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_user', jsonEncode(data['user']));

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Login error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.register(
        username: username,
        email: email,
        password: password,
      );
      _isLoading = false;

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        _user = UserModel.fromJson(data['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_user', jsonEncode(data['user']));

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Register error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    notifyListeners();
  }
}
