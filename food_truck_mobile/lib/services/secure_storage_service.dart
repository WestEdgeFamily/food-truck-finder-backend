import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  
  // Storage keys
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _socialTokensKey = 'social_tokens';
  
  // Auth token management
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }
  
  static Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }
  
  static Future<void> deleteAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }
  
  // Refresh token management
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }
  
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  static Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }
  
  // User data management
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _storage.write(key: _userDataKey, value: jsonString);
  }
  
  static Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _storage.read(key: _userDataKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }
  
  static Future<void> deleteUserData() async {
    await _storage.delete(key: _userDataKey);
  }
  
  // Social media tokens management
  static Future<void> saveSocialTokens(Map<String, dynamic> tokens) async {
    final jsonString = jsonEncode(tokens);
    await _storage.write(key: _socialTokensKey, value: jsonString);
  }
  
  static Future<Map<String, dynamic>?> getSocialTokens() async {
    final jsonString = await _storage.read(key: _socialTokensKey);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }
  
  static Future<void> deleteSocialTokens() async {
    await _storage.delete(key: _socialTokensKey);
  }
  
  // Clear all secure storage
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  
  // Check if user is logged in
  static Future<bool> hasAuthToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
  
  // Save tokens together
  static Future<void> saveTokens({
    required String authToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAuthToken(authToken),
      saveRefreshToken(refreshToken),
    ]);
  }
  
  // Delete all auth-related data
  static Future<void> clearAuthData() async {
    await Future.wait([
      deleteAuthToken(),
      deleteRefreshToken(),
      deleteUserData(),
      deleteSocialTokens(),
    ]);
  }
}