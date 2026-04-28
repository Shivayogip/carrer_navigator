import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/resume_service.dart';
import '../services/api_config.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/navbar.dart';
import '../theme/app_theme.dart';

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
    _checkAndFetch();
  }

  Future<void> _checkAndFetch() async {
    final rs = ResumeService();
    if (rs.projectsMarkdown != null && rs.projectsMarkdown!.isNotEmpty) {
      setState(() => _projectsMarkdown = rs.projectsMarkdown);
    } else {
      if (rs.extractedSkills.isEmpty) {
        await _refreshProfileData();
      }
      
      if (rs.extractedSkills.isNotEmpty) {
        _generateProjects();
      } else {
        setState(() {
          _projectsMarkdown = "### SYSTEM_HALT: ZERO_DATA_STREAM\n\nUpload resume in **Resume Intelligence** module first to extract technical features for project generation.";
        });
      }
    }
  }

  Future<void> _refreshProfileData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/data'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ResumeService().syncFromBackend(data);
      }
    } catch (e) {
      debugPrint("ProjectRecommendationScreen: Refresh error: $e");
    }
  }

  Future<void> _generateProjects() async {
    final rs = ResumeService();
    final skills = rs.extractedSkills;
    final role = rs.selectedRole;
    final company = rs.selectedCompany;

    if (skills.isEmpty) return;

    setState(() => _isLoading = true);
    
    final targetContext = company != null ? "${role ?? 'developer'} at $company" : "${role ?? 'developer'}";
    final prompt = "I have the following skills: ${skills.join(', ')}. I want to eventually become a $targetContext. Recommend 4 impressive portfolio projects I can build to showcase these specific skills. For each project, include: 1) Project Name, 2) Core Features, 3) Tech Stack, and 4) Relevance. Format the entire response in beautifully structured Markdown for a developer dashboard.";
    
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
        final content = data['response'] as String;
        if (mounted) {
          setState(() => _projectsMarkdown = content);
          rs.projectsMarkdown = content;
          final auth = Provider.of<AuthService>(context, listen: false);
          rs.saveData(auth);
        }
      } else {
        if (mounted) setState(() => _projectsMarkdown = "ERROR_PROTOCOL_FAILURE: Remote node error ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => _projectsMarkdown = "CONNECTION_LOST: Diagnostic stream interrupted. $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadPdf() async {
    final rs = ResumeService();
    final content = rs.projectsMarkdown;
    
    if (content != null && content.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("GENERATING_PREMIUM_PDF (via Backend)..."), backgroundColor: AppTheme.secondaryBlue),
      );
      
      final success = await rs.exportPdfDirect("Project Recommendations", content);
      
      if (!success && mounted) {
        await rs.generateLocalPdf("Project Recommendations", content);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("DATA_NULL: Generate recommendations first."))
      );
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
                    "PROJECT_RECOMMENDATIONS.LOG",
                    style: theme.textTheme.labelLarge,
                  ).animate().fadeIn().slideX(),
                  Text(
                    "Battle-Tested Portfolio Ideas",
                    style: theme.textTheme.displayMedium,
                  ).animate().fadeIn(delay: 200.ms).slideX(),
                  const SizedBox(height: 32),

                  _buildControls(theme).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: _isLoading 
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(80.0),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(color: AppTheme.primaryNeon),
                                  SizedBox(height: 24),
                                  Text("CALCULATING_OPTIMAL_PROJECTS...", style: TextStyle(color: AppTheme.textDim, fontFamily: 'JetBrainsMono', fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        : _projectsMarkdown != null 
                            ? MarkdownBody(
                                data: _projectsMarkdown!,
                                styleSheet: MarkdownStyleSheet(
                                  p: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: AppTheme.textMain),
                                  h1: theme.textTheme.titleLarge?.copyWith(color: AppTheme.primaryNeon),
                                  h2: theme.textTheme.titleLarge?.copyWith(color: AppTheme.secondaryBlue, fontSize: 18, height: 2),
                                  h3: theme.textTheme.titleLarge?.copyWith(color: AppTheme.accentPurple, fontSize: 16),
                                  code: const TextStyle(backgroundColor: AppTheme.darkBg, color: AppTheme.secondaryBlue, fontFamily: 'JetBrainsMono'),
                                  listBullet: const TextStyle(color: AppTheme.primaryNeon),
                                ),
                              ) 
                            : const Center(child: Text("Awaiting initialization signal.", style: TextStyle(color: AppTheme.textDim))),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _projectsMarkdown != null && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(ResumeService().projectsUrl != null ? "DOWNLOAD_PDF" : "EXPORT_PDF", 
                          style: const TextStyle(fontFamily: 'JetBrainsMono', fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.architecture_outlined, color: AppTheme.primaryNeon, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("FEATURE_EXTRACTION", style: TextStyle(color: AppTheme.textDim, fontSize: 10, fontFamily: 'JetBrainsMono')),
                Text(
                  "${ResumeService().extractedSkills.length} SKILLS_DETECTED",
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono'),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _generateProjects,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text("REGENERATE"),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              IconButton(
                onPressed: _checkAndFetch,
                icon: const Icon(Icons.sync, size: 18, color: AppTheme.textDim),
                tooltip: "SYNC",
              ),
            ],
          ),
        ],
      ),
    );
  }
}