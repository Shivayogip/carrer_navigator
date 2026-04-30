import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_config.dart';
import '../services/resume_service.dart';
import '../widgets/navbar.dart';
import '../theme/app_theme.dart';

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

    final targetRole = ResumeService().selectedRole ?? "Full Stack Developer";

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/github/analyze/$username?role=$targetRole',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _analysisMarkdown = data['response']);
      } else {
        if (mounted)
          setState(
            () => _analysisMarkdown =
                "ERROR_RECOVERY: Could not locate GitHub node or fetch telemetry.",
          );
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _analysisMarkdown =
              "CONNECTIVITY_FAILURE: Secure stream interrupted.",
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            const Navbar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GITHUB_ANALYZER.EXE",
                      style: theme.textTheme.labelLarge,
                    ).animate().fadeIn().slideX(),
                    Text(
                      "Source Code Impact Analysis",
                      style: theme.textTheme.displayMedium,
                    ).animate().fadeIn(delay: 200.ms).slideX(),
                    const SizedBox(height: 40),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.code_off_outlined,
                            size: 64,
                            color: AppTheme.primaryNeon,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Enter GitHub username to start professional diagnostics on activity streaks and technical value-add.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textDim,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          TextField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: "GITHUB_USERNAME",
                              prefixIcon: Icon(Icons.person_outline, size: 18),
                            ),
                            onSubmitted: (_) => _analyzeGithub(),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _analyzeGithub,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text("EXECUTE_DEEP_SCAN"),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                    if (_analysisMarkdown != null) ...[
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: MarkdownBody(
                          data: _analysisMarkdown!,
                          styleSheet: MarkdownStyleSheet(
                            p: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              color: AppTheme.textMain,
                            ),
                            h1: theme.textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryNeon,
                            ),
                            h2: theme.textTheme.titleLarge?.copyWith(
                              color: AppTheme.secondaryBlue,
                              fontSize: 18,
                            ),
                            h3: theme.textTheme.titleLarge?.copyWith(
                              color: AppTheme.accentPurple,
                              fontSize: 16,
                            ),
                            code: const TextStyle(
                              backgroundColor: AppTheme.darkBg,
                              color: AppTheme.secondaryBlue,
                              fontFamily: 'JetBrainsMono',
                            ),
                            listBullet: const TextStyle(
                              color: AppTheme.primaryNeon,
                            ),
                          ),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.05),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
