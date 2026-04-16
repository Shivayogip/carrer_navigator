import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/resume_service.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  bool _isLoading = false;
  String? _roadmapMarkdown;

  @override
  void initState() {
    super.initState();
    _generateRoadmap();
  }

  Future<void> _generateRoadmap() async {
    final role = ResumeService().selectedRole;
    final company = ResumeService().selectedCompany;
    if (role == null) {
      if (mounted) {
        setState(() {
          _roadmapMarkdown = "⚠️ No target role selected!\n\nPlease go to **Career Path Generation** and select a Target Role first before generating your roadmap.";
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    
    final roleContext = company != null ? "$role at $company" : role;
    final prompt = "Generate a structured, step-by-step career timeline and roadmap to become a $roleContext. Format the response entirely in cleanly readable Markdown. Use headings, bullet points, and bold text to make it engaging.";
    
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "message": prompt,
          "history": []
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _roadmapMarkdown = data['response']);
      } else {
        if (mounted) setState(() => _roadmapMarkdown = "Error fetching roadmap: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => _roadmapMarkdown = "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Roadmap Generator")),
      body: _isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("AI is generating your personalized roadmap...")
                ],
              )
            )
          : Container(
              padding: const EdgeInsets.all(20),
              child: AnimatedOpacity(
                opacity: _roadmapMarkdown != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeIn,
                child: _roadmapMarkdown != null 
                    ? Markdown(data: _roadmapMarkdown!) 
                    : const Center(child: Text("No roadmap generated.")),
              ),
            ),
    );
  }
}