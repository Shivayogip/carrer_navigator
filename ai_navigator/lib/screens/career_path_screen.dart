import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/resume_service.dart';
import '../widgets/navbar.dart';
import '../services/api_config.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class CareerPathScreen extends StatefulWidget {
  const CareerPathScreen({super.key});

  @override
  State<CareerPathScreen> createState() => _CareerPathScreenState();
}

class _CareerPathScreenState extends State<CareerPathScreen> {
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();

  bool _isLoadingRecommendations = false;
  String? _recommendationsMarkdown;

  @override
  void initState() {
    super.initState();
    _roleController.text = ResumeService().selectedRole ?? "";
    _companyController.text = ResumeService().selectedCompany ?? "";

    if (ResumeService().careerPathMarkdown != null) {
      _recommendationsMarkdown = ResumeService().careerPathMarkdown;
    } else if (ResumeService().extractedSkills.isNotEmpty) {
      _generateRecommendations();
    }
  }

  Future<void> _generateRecommendations() async {
    setState(() => _isLoadingRecommendations = true);

    final skills = ResumeService().extractedSkills;
    final prompt =
        "I have the following skills parsed from my resume: ${skills.join(', ')}. Please recommend 3 optimal career titles for me. Explain why they fit my skills. IMPORTANT: Based on these skills and recommended roles, generate direct search links for actual job openings on platforms like LinkedIn, Internshala, Indeed, etc., and present them as 'Apply Here' buttons/links in the markdown. Format this purely in beautifully structured Markdown for a developer dashboard.";

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"message": prompt, "history": []}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() => _recommendationsMarkdown = data['response']);
          ResumeService().careerPathMarkdown = data['response'];
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['error'] ??
            "Error ${response.statusCode}";
        if (mounted)
          setState(
            () => _recommendationsMarkdown =
                "ERROR_RECOVERY: Could not fetch career logic. $errorMsg",
          );
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _recommendationsMarkdown =
              "CRITICAL_FAILURE: Network interruption. $e",
        );
    } finally {
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }

  Future<void> _downloadPdf() async {
    final rs = ResumeService();
    final content = rs.careerPathMarkdown;

    if (content != null && content.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("GENERATING_PREMIUM_PDF (via Backend)..."),
          backgroundColor: AppTheme.secondaryBlue,
        ),
      );

      final success = await rs.exportPdfDirect("Career Path Analysis", content);

      if (!success && mounted) {
        await rs.generateLocalPdf("Career Path Analysis", content);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("DATA_NULL: Generate recommendations first."),
        ),
      );
    }
  }

  void _saveTarget() {
    final role = _roleController.text.trim();
    final company = _companyController.text.trim();

    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Goal specification required.")),
      );
      return;
    }

    ResumeService().setTarget(
      role,
      company: company.isNotEmpty ? company : null,
    );

    final auth = Provider.of<AuthService>(context, listen: false);
    ResumeService().saveData(auth).then((success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? "CAREER_GOAL: $role locked in."
                  : "Local buffer updated. Cloud sync pending.",
            ),
            backgroundColor: success ? AppTheme.primaryNeon : Colors.orange,
          ),
        );
      }
    });

    setState(() {});
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
                      "CAREER_TRAJECTORY.LOG",
                      style: theme.textTheme.labelLarge,
                    ).animate().fadeIn().slideX(),
                    Text(
                      "Algorithmic Pathfinding",
                      style: theme.textTheme.displayMedium,
                    ).animate().fadeIn(delay: 200.ms).slideX(),
                    const SizedBox(height: 32),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 900;
                        return Column(
                          children: [
                            if (!isMobile)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _buildAiSection(theme),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 1,
                                    child: _buildFormSection(theme),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildFormSection(theme),
                                  const SizedBox(height: 24),
                                  _buildAiSection(theme),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _recommendationsMarkdown != null && !_isLoadingRecommendations
          ? FloatingActionButton.extended(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text(
                "EXPORT_PDF",
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAiSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.psychology_outlined,
                    color: AppTheme.primaryNeon,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text("AI_RECOMMENDATIONS", style: theme.textTheme.titleLarge),
                ],
              ),
              IconButton(
                onPressed: _isLoadingRecommendations
                    ? null
                    : _generateRecommendations,
                icon: const Icon(
                  Icons.refresh,
                  size: 18,
                  color: AppTheme.secondaryBlue,
                ),
                tooltip: "RECALIBRATE",
              ),
            ],
          ),
          const Divider(height: 48),
          if (ResumeService().extractedSkills.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text(
                  "DATA_MISSING: Upload resume to initialize neural recommendations.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textDim),
                ),
              ),
            )
          else if (_isLoadingRecommendations)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(80.0),
                child: CircularProgressIndicator(color: AppTheme.primaryNeon),
              ),
            )
          else if (_recommendationsMarkdown != null)
            MarkdownBody(
              data: _recommendationsMarkdown!,
              onTapLink: (text, href, title) async {
                if (href != null) {
                  final uri = Uri.parse(href);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
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
                listBullet: const TextStyle(color: AppTheme.primaryNeon),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildFormSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.track_changes,
                color: AppTheme.accentPurple,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text("LOCK_GOAL", style: theme.textTheme.titleLarge),
            ],
          ),
          const Divider(height: 48),
          const Text(
            "Manually specify target role to calibrate system diagnostics.",
            style: TextStyle(
              color: AppTheme.textDim,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _roleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "TARGET_ROLE",
              hintText: "e.g. SOFTWARE_ENGINEER",
              prefixIcon: Icon(Icons.work_outline, size: 18),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _companyController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "TARGET_COMPANY",
              hintText: "OPTIONAL_FIELD",
              prefixIcon: Icon(Icons.business_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _saveTarget,
              child: const Text("EXECUTE_LOCK"),
            ),
          ),

          if (ResumeService().selectedRole != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryNeon.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: AppTheme.primaryNeon.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.primaryNeon,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "ACTIVE_TARGET: ${ResumeService().selectedRole!.toUpperCase()}",
                      style: const TextStyle(
                        color: AppTheme.primaryNeon,
                        fontSize: 10,
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().scale(),
          ],
        ],
      ),
    );
  }
}
