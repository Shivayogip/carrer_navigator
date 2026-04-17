import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_config.dart';

class GithubAnalyzerScreen extends StatefulWidget {
  const GithubAnalyzerScreen({super.key});

  @override
  State<GithubAnalyzerScreen> createState() => _GithubAnalyzerScreenState();
}

class _GithubAnalyzerScreenState extends State<GithubAnalyzerScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _analysisMarkdown;

  Future<void> _analyzeGithub() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _isLoading = true;
      _analysisMarkdown = null;
    });
    
    final prompt = "I am a developer with the GitHub username: '$username'. Write a fun, creative, but professional 3-paragraph hypothetical assessment of what kind of open-source developer I am, what my code style says about me, and what top 3 repositories I likely have, purely based on analyzing the 'vibe' of my username. Format as Markdown.";
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "message": prompt,
          "history": []
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _analysisMarkdown = data['response']);
      } else {
        if (mounted) setState(() => _analysisMarkdown = "Error fetching analysis.");
      }
    } catch (e) {
      if (mounted) setState(() => _analysisMarkdown = "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GitHub Analyzer"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.code, size: 80, color: Colors.black87),
            const SizedBox(height: 16),
            const Text(
              "Discover your Open-Source Identity",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Enter your GitHub username and let our AI analyze your vibe and generate a hypothetical repository profile!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "GitHub Username",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _analyzeGithub(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _analyzeGithub,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Analyze Vibe"),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _analysisMarkdown != null 
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!)
                      ),
                      child: Markdown(data: _analysisMarkdown!)
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}