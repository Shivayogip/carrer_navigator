import 'package:flutter/foundation.dart';

class ApiConfig {
  // 🚀 UPDATE THIS after deploying your backend (e.g. to Render.com)
  static const String _prodBaseUrl = 'https://career-navigator-api.onrender.com'; 

  static String get baseUrl {
    if (kReleaseMode) {
      return _prodBaseUrl;
    }
    return kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';
  }
}
