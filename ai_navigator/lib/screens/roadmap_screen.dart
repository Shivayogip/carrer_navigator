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
    if (ResumeService().roadmapMarkdown != null &&
        ResumeService().roadmapMarkdown!.isNotEmpty) {
      _roadmapMarkdown = ResumeService().roadmapMarkdown;
    } else {
      _generateRoadmap();
    }
  }

  Future<void> _generateRoadmap() async {
    final rs = ResumeService();
    final role = rs.selectedRole;
    final company = rs.selectedCompany;

    if (role == null) {
      if (mounted) {
        setState(() {
          _roadmapMarkdown =
              "### SYSTEM_HALT: TARGET_ROLE_NULL\n\nInitialize target objectives in **Career Trajectory** module before roadmap generation.";
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    final roleContext = company != null ? "$role at $company" : role;
    final prompt =
        "Generate a comprehensive, expert-level step-by-step career roadmap to become a $roleContext. Include specific technologies, project milestones, and interview focus nodes. Format the response entirely in beautifully structured Markdown for a developer dashboard.";

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"message": prompt, "history": []}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['response'] as String;
        if (mounted) {
          setState(() => _roadmapMarkdown = content);
          rs.roadmapMarkdown = content;
          final auth = Provider.of<AuthService>(context, listen: false);
          rs.saveData(auth);
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['error'] ??
            "Error ${response.statusCode}";
        if (mounted)
          setState(
            () => _roadmapMarkdown =
                "ERROR_PROTOCOL_FAILURE: Remote host error $errorMsg",
          );
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _roadmapMarkdown =
              "CONNECTION_LOST: Diagnostic stream interrupted. $e",
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadPdf() async {
    final rs = ResumeService();
    final content = rs.roadmapMarkdown;

    if (content != null && content.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("GENERATING_PREMIUM_PDF (via Backend)..."),
          backgroundColor: AppTheme.secondaryBlue,
        ),
      );

      final success = await rs.exportPdfDirect("Career Roadmap", content);

      if (!success && mounted) {
        // Fallback to local if backend fails
        await rs.generateLocalPdf("Career Roadmap", content);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("DATA_NULL: Generate roadmap first.")),
      );
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
                      "CAREER_ROADMAP.INF",
                      style: theme.textTheme.labelLarge,
                    ).animate().fadeIn().slideX(),
                    Text(
                      "Algorithmic Evolution Path",
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
                                    CircularProgressIndicator(
                                      color: AppTheme.primaryNeon,
                                    ),
                                    SizedBox(height: 24),
                                    Text(
                                      "ARCHITECTING_FUTURE_NODES...",
                                      style: TextStyle(
                                        color: AppTheme.textDim,
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _roadmapMarkdown != null
                          ? MarkdownBody(
                              data: _roadmapMarkdown!,
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
                                  height: 2,
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
                            )
                          : const Center(
                              child: Text(
                                "Awaiting initialization signal.",
                                style: TextStyle(color: AppTheme.textDim),
                              ),
                            ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _roadmapMarkdown != null && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                ResumeService().roadmapUrl != null
                    ? "DOWNLOAD_PDF"
                    : "EXPORT_PDF",
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          const Icon(Icons.hub_outlined, color: AppTheme.primaryNeon, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TARGET_SYSTEM",
                  style: TextStyle(
                    color: AppTheme.textDim,
                    fontSize: 10,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                Text(
                  ResumeService().selectedRole?.toUpperCase() ?? "NULL",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _generateRoadmap,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text("REGENERATE"),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.borderSubtle),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
