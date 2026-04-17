import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl => kIsWeb ? 'http://localhost:5000' : 'http://192.168.29.132:5000';
}
