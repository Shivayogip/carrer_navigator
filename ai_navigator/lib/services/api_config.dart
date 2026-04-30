import 'package:flutter/foundation.dart';

class ApiConfig {
  // 🚀 UPDATED: Points to your live Render backend
  static const String _prodBaseUrl =
      'https://carrer-navigator-api.onrender.com';

  static String get baseUrl {
    if (kReleaseMode) {
      return _prodBaseUrl;
    }
    return kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';
  }
}
