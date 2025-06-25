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
      final userBusinessName = prefs.getString('user_business_name');

      if (token != null && userRole != null && userId != null) {
        _token = token;
        _user = User(
          id: userId,
          name: userName ?? '',
          email: userEmail ?? '',
          role: userRole,
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
      debugPrint('🔍 AuthProvider received response: $response');
      debugPrint('🔍 Looking for success field: ${response['success']}');
      debugPrint('🔍 Response keys: ${response.keys.toList()}');
      
      if (response['success'] == true) {
        _token = response['token'];
        _user = User.fromJson(response['user']);

        debugPrint('🔥 AUTH DEBUG: Login successful');
        debugPrint('🔥 User ID: ${_user!.id}');
        debugPrint('🔥 User name: ${_user!.name}');
        debugPrint('🔥 User email: ${_user!.email}');
        debugPrint('🔥 User role: ${_user!.role}');

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_role', _user!.role);
        await prefs.setString('user_id', _user!.id);
        await prefs.setString('user_name', _user!.name);
        await prefs.setString('user_email', _user!.email);
        if (_user!.businessName != null) {
          await prefs.setString('user_business_name', _user!.businessName!);
        }

        debugPrint('🔥 AUTH DEBUG: User data saved to SharedPreferences');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('💥 Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.register(userData);
      debugPrint('🔍 AuthProvider received registration response: $response');
      debugPrint('🔍 Looking for success field: ${response['success']}');
      debugPrint('🔍 Registration response keys: ${response.keys.toList()}');
      
      // Check for different possible response formats
      if (response['success'] == true || response.containsKey('token')) {
        _token = response['token'];
        
        // Handle different user data formats
        Map<String, dynamic> userDataFromResponse;
        if (response['user'] != null) {
          userDataFromResponse = response['user'];
        } else {
          // If no 'user' field, use the response directly
          userDataFromResponse = response;
        }
        debugPrint('🔍 Registration user data to parse: $userDataFromResponse');
        
        _user = User.fromJson(userDataFromResponse);

        // Save to SharedPreferences - this auto-logs them in
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_role', _user!.role);
        await prefs.setString('user_id', _user!.id);
        await prefs.setString('user_name', _user!.name);
        await prefs.setString('user_email', _user!.email);
        if (_user!.businessName != null) {
          await prefs.setString('user_business_name', _user!.businessName!);
        }

        debugPrint('✅ Registration successful! User auto-logged in: ${_user!.name}');
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ Registration failed - no success flag or token found');
      }
    } catch (e) {
      debugPrint('💥 Registration error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_business_name');
    
    notifyListeners();
  }

  // Force clear all authentication data - for debugging/testing
  Future<void> forceLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear specific auth keys
      await prefs.remove('auth_token');
      await prefs.remove('user_role');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_business_name');
      // Clear everything else too
      await prefs.clear();
      debugPrint('🧹 All authentication data cleared');
    } catch (e) {
      debugPrint('Force logout error: $e');
    }

    _user = null;
    _token = null;
    notifyListeners();
  }

  // Add method to check if we have stored credentials
  Future<bool> hasStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      return token != null && userId != null;
    } catch (e) {
      debugPrint('Error checking stored credentials: $e');
      return false;
    }
  }

  // Method to verify if the stored session is still valid
  Future<bool> validateStoredSession() async {
    try {
      if (!await hasStoredCredentials()) {
        return false;
      }
      
      // If we have credentials but no current user, try to restore
      if (_user == null) {
        await checkAuthStatus();
      }
      
      return _user != null && _token != null;
    } catch (e) {
      debugPrint('Error validating session: $e');
      return false;
    }
  }

  bool isOwner() => _user?.role == 'owner';
  bool isCustomer() => _user?.role == 'customer';

  Future<void> clearUserData() async {
    _user = null;
    _token = null;
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_business_name');
    
    notifyListeners();
  }
} 