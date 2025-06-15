import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userRole = prefs.getString('user_role');
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userPhone = prefs.getString('user_phone');
      final userBusinessName = prefs.getString('user_business_name');

      if (token != null && userRole != null && userId != null) {
        _token = token;
        _user = User(
          id: userId,
          name: userName ?? '',
          email: userEmail ?? '',
          role: userRole,
          phone: userPhone,
          businessName: userBusinessName,
        );
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, String role) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.login(email, password, role);
      
      if (response['success'] == true) {
        _token = response['token'];
        _user = User.fromJson(response['user']);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_role', _user!.role);
        await prefs.setString('user_id', _user!.id);
        await prefs.setString('user_name', _user!.name);
        await prefs.setString('user_email', _user!.email);
        if (_user!.phone != null) {
          await prefs.setString('user_phone', _user!.phone!);
        }
        if (_user!.businessName != null) {
          await prefs.setString('user_business_name', _user!.businessName!);
        }

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.register(userData);
      
      if (response['success'] == true) {
        _token = response['token'];
        _user = User.fromJson(response['user']);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_role', _user!.role);
        await prefs.setString('user_id', _user!.id);
        await prefs.setString('user_name', _user!.name);
        await prefs.setString('user_email', _user!.email);
        if (_user!.phone != null) {
          await prefs.setString('user_phone', _user!.phone!);
        }
        if (_user!.businessName != null) {
          await prefs.setString('user_business_name', _user!.businessName!);
        }

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Registration error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    _user = null;
    _token = null;
    notifyListeners();
  }

  bool isOwner() => _user?.role == 'owner';
  bool isCustomer() => _user?.role == 'customer';

  // TEMPORARY: Method for testing - set fake user
  void setFakeUserForTesting() {
    _user = User(
      id: 'user_1749785616229', // Same user ID from the logs
      name: 'Test User',
      email: 'test@example.com',
      role: 'customer',
    );
    _token = 'fake_token_for_testing';
    notifyListeners();
  }
} 