import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_config.dart';
import '../widgets/navbar.dart';
import '../theme/app_theme.dart';

class ResumeScoringScreen extends StatefulWidget {
  const ResumeScoringScreen({super.key});

  @override
  State<ResumeScoringScreen> createState() => _ResumeScoringScreenState();
}

class _ResumeScoringScreenState extends State<ResumeScoringScreen> {
  bool _isLoading = true;
  double _score = 0;

  @override
  void initState() {
    super.initState();
    _fetchScore();
  }

  Future<void> _fetchScore() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/data'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _score = (data['score'] ?? 0).toDouble();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Column(
        children: [
          const Navbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SYSTEM_RATING.REPORT",
                    style: theme.textTheme.labelLarge,
                  ).animate().fadeIn().slideX(),
                  Text(
                    "ATS Compatibility Score",
                    style: theme.textTheme.displayMedium,
                  ).animate().fadeIn(delay: 200.ms).slideX(),
                  const SizedBox(height: 60),
                  
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(80.0), child: CircularProgressIndicator(color: AppTheme.primaryNeon)))
                  else
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 300,
                                height: 300,
                                child: CircularProgressIndicator(
                                  value: _score / 100,
                                  strokeWidth: 24,
                                  backgroundColor: AppTheme.darkSurface,
                                  color: _getScoreColor(_score),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${_score.toInt()}%", 
                                    style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: _getScoreColor(_score), fontFamily: 'JetBrainsMono')
                                  ),
                                  const Text("INTEGRITY_INDEX", style: TextStyle(color: AppTheme.textDim, fontFamily: 'JetBrainsMono', fontSize: 12)),
                                ],
                              )
                            ],
                          ).animate().scale(duration: 600.ms),
                          const SizedBox(height: 60),
                          
                          if (_score == 0)
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: const Text("SIGNAL_LOST: No resume telemetry detected. Upload file in Resume Intelligence to start scan.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textDim, height: 1.5)),
                            ).animate().fadeIn(delay: 400.ms)
                          else
                            Container(
                              padding: const EdgeInsets.all(40),
                              width: 600,
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _getScoreColor(_score).withOpacity(0.5)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "DIAGNOSTIC_FEEDBACK",
                                    style: TextStyle(color: _getScoreColor(_score), fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono', fontSize: 14),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _getScoreFeedback(_score),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.6),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.primaryNeon;
    if (score >= 50) return Colors.orange;
    if (score > 0) return const Color(0xFFF85149); // Error red
    return AppTheme.borderSubtle;
  }

  String _getScoreFeedback(double score) {
    if (score >= 80) return "Excellent! Your resume telemetry is highly compatible with current ATS protocols. Expect high engagement from recruitment nodes.";
    if (score >= 50) return "Acceptable, but optimization required. Consider injecting industry-specific keywords to improve searchability index.";
    return "Critical Review Needed. System recommends restructuring high-level bullet points for better impact factor.";
  }
}