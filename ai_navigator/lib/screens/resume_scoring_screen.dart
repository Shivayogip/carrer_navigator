import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_config.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text("Resume Report Card")),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Overall System Rating", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 40),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: _score / 100,
                          strokeWidth: 20,
                          backgroundColor: Colors.grey[200],
                          color: _getScoreColor(_score),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${_score.toInt()}%", style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: _getScoreColor(_score))),
                          const Text("ATS Compatibility", style: TextStyle(color: Colors.black54)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 60),
                  if (_score == 0)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text("You haven't analyzed a resume yet! Head to Resume Intelligence to upload your PDF.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Card(
                        color: _getScoreColor(_score).withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            _getScoreFeedback(_score),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: _getScoreColor(_score), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )
                ],
              ),
          ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    if (score > 0) return Colors.red;
    return Colors.grey;
  }

  String _getScoreFeedback(double score) {
    if (score >= 80) return "Excellent! Your resume is highly likely to pass ATS filtering and impress recruiters.";
    if (score >= 50) return "Good, but there's room for improvement. Consider adopting more industry buzzwords.";
    return "Needs Review. We recommend using the AI Assistant to restructure your bullet points for higher impact.";
  }
}