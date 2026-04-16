import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String uid;
  final String email;
  final String? displayName;

  User({required this.uid, required this.email, this.displayName});
}

class AuthService with ChangeNotifier {
  User? _user;
  User? get user => _user;
  String? _token;
  String? get token => _token;

  AuthService() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final email = prefs.getString('auth_email');
    final uid = prefs.getString('auth_uid');
    final name = prefs.getString('auth_name');

    if (_token != null && uid != null && email != null) {
      _user = User(uid: uid, email: email, displayName: name);
      notifyListeners();
    }
  }

  Future<void> _saveUser(Map<String, dynamic> data, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_email', data['email'] ?? '');
    await prefs.setString('auth_uid', data['id'] ?? '');
    await prefs.setString('auth_name', data['name'] ?? '');
    
    _token = token;
    _user = User(uid: data['id'], email: data['email'], displayName: data['name']);
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    // Mock google sign-in communicating with local DB to map the demo user identity
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": "demo.google@example.com",
          "name": "Demo Google User"
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUser(data['user'], data['token']);
        return true;
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    return false;
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
          "name": email.split('@')[0]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUser(data['user'], data['token']);
        return true;
      } else {
        debugPrint(response.body);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    return false;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password
        }),
      );

      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         await _saveUser(data['user'], data['token']);
         return true;
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    return false;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_email');
    await prefs.remove('auth_uid');
    await prefs.remove('auth_name');
    _token = null;
    _user = null;
    notifyListeners();
  }
}
