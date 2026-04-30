import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_config.dart';
import 'resume_service.dart';

String get _baseUrl => ApiConfig.baseUrl;

class User {
  final String uid;
  final String email;
  final String? displayName;
  final String? mobile;
  final String? course;
  final String? branch;
  final String? year;
  final String? interestField;
  final int currentStreak;
  final List<String> badges;

  User({
    required this.uid,
    required this.email,
    this.displayName,
    this.mobile,
    this.course,
    this.branch,
    this.year,
    this.interestField,
    this.currentStreak = 0,
    this.badges = const [],
  });
}

class AuthService with ChangeNotifier {
  User? _user;
  User? get user => _user;
  String? _token;
  String? get token => _token;
  String? _authError;
  String? get authError => _authError;

  AuthService() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final email = prefs.getString('auth_email');
    final uid = prefs.getString('auth_uid');
    final name = prefs.getString('auth_name');
    final mobile = prefs.getString('auth_mobile');
    final course = prefs.getString('auth_course');
    final branch = prefs.getString('auth_branch');
    final year = prefs.getString('auth_year');
    final interest = prefs.getString('auth_interest');
    final streak = prefs.getInt('auth_streak') ?? 0;
    final badges = prefs.getStringList('auth_badges') ?? [];

    if (_token != null && uid != null && email != null) {
      _user = User(
        uid: uid,
        email: email,
        displayName: name,
        mobile: mobile,
        course: course,
        branch: branch,
        year: year,
        interestField: interest,
        currentStreak: streak,
        badges: badges,
      );
      notifyListeners();
    }
  }

  Future<void> _saveUser(Map<String, dynamic> data, String token) async {
    if (data['id'] == null || data['email'] == null) {
      throw Exception('Server returned invalid user data');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_email', data['email']);
    await prefs.setString('auth_uid', data['id']);
    await prefs.setString('auth_name', data['name'] ?? '');
    await prefs.setString('auth_mobile', data['mobile'] ?? '');
    await prefs.setString('auth_course', data['course'] ?? '');
    await prefs.setString('auth_branch', data['branch'] ?? '');
    await prefs.setString('auth_year', data['year'] ?? '');
    await prefs.setString('auth_interest', data['interest_field'] ?? '');
    await prefs.setInt('auth_streak', data['current_streak'] ?? 0);
    await prefs.setStringList(
      'auth_badges',
      List<String>.from(data['badges'] ?? []),
    );

    _token = token;
    _user = User(
      uid: data['id'],
      email: data['email'],
      displayName: data['name'],
      mobile: data['mobile'],
      course: data['course'],
      branch: data['branch'],
      year: data['year'],
      interestField: data['interest_field'],
      currentStreak: data['current_streak'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
    );
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '397856270364-fi8t8plifl90r06vq4kbrdipcmoeurp2.apps.googleusercontent.com'
            : null,
        scopes: ['email', 'profile', 'openid'],
        forceCodeForRefreshToken: true,
      );

      GoogleSignInAccount? googleUser;

      // Attempt silent sign in first on web
      if (kIsWeb) {
        googleUser = await googleSignIn.signInSilently();
      }

      googleUser ??= await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("Google Sign-In: User canceled.");
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": googleUser.email,
          "name": googleUser.displayName ?? googleUser.email.split('@')[0],
        }),
      );

      if (response.statusCode == 200) {
        // 🔥 WIPE ALL PREVIOUS SESSION DATA
        ResumeService().clearAll();
        final data = jsonDecode(response.body);
        await _saveUser(data['user'], data['token']);
        return true;
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    return false;
  }

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    _authError = null;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password, "name": name}),
      );

      if (response.statusCode == 200) {
        // 🔥 WIPE ALL PREVIOUS SESSION DATA
        ResumeService().clearAll();
        final data = jsonDecode(response.body);
        await _saveUser(data['user'], data['token']);
        return true;
      } else {
        try {
          final data = jsonDecode(response.body);
          _authError = data['error'];
        } catch (_) {
          _authError = "Registration failed";
        }
        debugPrint(response.body);
      }
    } catch (e) {
      _authError = "Connection error";
      debugPrint("Error: $e");
    }
    return false;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _authError = null;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        // 🔥 WIPE ALL PREVIOUS SESSION DATA
        ResumeService().clearAll();
        final data = jsonDecode(response.body);
        await _saveUser(data['user'], data['token']);
        return true;
      } else {
        try {
          final data = jsonDecode(response.body);
          _authError = data['error'];
        } catch (_) {
          _authError = "Login failed";
        }
      }
    } catch (e) {
      _authError = "Connection error";
      debugPrint("Error: $e");
    }
    return false;
  }

  Future<void> signOut() async {
    // 🔥 WIPE ALL RESUME DATA ON LOGOUT
    ResumeService().clearAll();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_email');
    await prefs.remove('auth_uid');
    await prefs.remove('auth_name');
    _token = null;
    _user = null;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        // Refresh local data
        await fetchUserData();
        return true;
      }
    } catch (e) {
      debugPrint("Update Profile Error: $e");
    }
    return false;
  }

  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_token == null) return "Not logged in";
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/user/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          "current_password": currentPassword,
          "new_password": newPassword,
        }),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return result['error'] ?? "Failed to update password";
      }
    } catch (e) {
      return "Connection error: $e";
    }
  }

  Future<void> fetchUserData() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/data'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Map backend field names if they differ slightly
        final userData = {
          "id": _user?.uid,
          "email": data['email'],
          "name": data['name'],
          "mobile": data['mobile'],
          "course": data['course'],
          "branch": data['branch'],
          "year": data['year'],
          "interest_field": data['interest_field'],
          "current_streak": data['current_streak'] ?? 0,
          "badges": data['badges'] ?? [],
        };
        await _saveUser(userData, _token!);
      }
    } catch (e) {
      debugPrint("Fetch User Data Error: $e");
    }
  }

  Future<bool> logDailyTask(String description) async {
    if (_token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/user/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({"task_desc": description}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user_data'] != null) {
          // Update user object with new streak
          final updatedData = data['user_data'];
          updatedData['id'] = _user?.uid;
          await _saveUser(updatedData, _token!);
        }
        return true;
      }
    } catch (e) {
      debugPrint("Log Daily Task Error: $e");
    }
    return false;
  }

  Future<List<dynamic>> fetchTodayTasks() async {
    if (_token == null) return [];
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/tasks'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Fetch Tasks Error: $e");
    }
    return [];
  }
}
