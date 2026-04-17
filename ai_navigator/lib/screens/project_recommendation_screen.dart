import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/resume_service.dart';
import '../services/api_config.dart';

class ProjectRecommendationScreen extends StatefulWidget {
  const ProjectRecommendationScreen({super.key});

  @override
  State<ProjectRecommendationScreen> createState() => _ProjectRecommendationScreenState();
}

class _ProjectRecommendationScreenState extends State<ProjectRecommendationScreen> {
  bool _isLoading = false;
  String? _projectsMarkdown;

  @override
  void initState() {
    super.initState();
    _generateProjects();
  }

  Future<void> _generateProjects() async {
    final skills = ResumeService().extractedSkills;
    final role = ResumeService().selectedRole;
    final company = ResumeService().selectedCompany;

    if (skills.isEmpty) {
      if (mounted) {
        setState(() {
          _projectsMarkdown = "⚠️ No skills detected!\n\nPlease upload a resume via **Resume Intelligence** so the AI knows what skills to base your projects on.";
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    
    final targetContext = company != null ? "${role ?? 'professional developer'} at $company" : "${role ?? 'professional developer'}";
    final prompt = "I have the following skills: ${skills.join(', ')}. I want to eventually become a $targetContext. Please recommend 3 to 5 impressive and creative portfolio projects I can build to showcase these skills. Outline the features, specific tech stack, and difficulty level for each project in Markdown formatting.";
    
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
        if (mounted) setState(() => _projectsMarkdown = data['response']);
      } else {
        if (mounted) setState(() => _projectsMarkdown = "Error fetching recommendations: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => _projectsMarkdown = "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Project Recommendation")),
      body: _isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("AI is brainstorming project ideas for your portfolio...")
                ],
              )
            )
          : _projectsMarkdown != null 
              ? Markdown(data: _projectsMarkdown!) 
              : const Center(child: Text("No recommendations generated.")),
    );
  }
}