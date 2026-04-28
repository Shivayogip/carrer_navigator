import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl => kIsWeb ? 'http://localhost:5000' : 'http://10.137.89.1:5000';
}
