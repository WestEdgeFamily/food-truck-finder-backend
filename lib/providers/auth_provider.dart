import 'package:flutter/foundation.dart';

class AuthProvider {
  User? _user;

  Future<void> login(Map<String, dynamic> response) async {
    _user = User.fromJson(response['user']);
    debugPrint('Logged in user ID: \\${_user!.id}');
  }
} 