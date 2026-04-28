import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/resume_service.dart';
import '../widgets/navbar.dart';
import 'progress_tracker_screen.dart';
import '../services/api_config.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import '../theme/app_theme.dart';

class SkillGapScreen extends StatefulWidget {
  const SkillGapScreen({super.key});

  @override
  State<SkillGapScreen> createState() => _SkillGapScreenState();
}

class _SkillGapScreenState extends State<SkillGapScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (ResumeService().selectedRole != null && ResumeService().dynamicMissingSkills.isEmpty) {
      _fetchDynamicSkillGap();
    }
  }

  Future<void> _fetchDynamicSkillGap() async {
    setState(() => _isLoading = true);

    final role = ResumeService().selectedRole!;
    final company = ResumeService().selectedCompany;
    final skills = ResumeService().extractedSkills;

    final targetContext = company != null ? "$role at $company" : role;
    
    final prompt = "I currently have the following technical skills: ${skills.isEmpty ? 'None' : skills.join(', ')}. I want to apply for the position of '$targetContext'. Identify the critical missing hard skills. Return ONLY a comma-separated string of missing technical skills. Limit to 10.";

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"message": prompt, "history": []}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawResponse = data['response'] as String;
        
        final parsedSkills = rawResponse
            .replaceAll('*', '')
            .replaceAll('\n', ',')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s.toLowerCase() != 'none')
            .toList();

        if (mounted) {
          setState(() {
            ResumeService().dynamicMissingSkills = parsedSkills;
          });
          final auth = Provider.of<AuthService>(context, listen: false);
          ResumeService().saveData(auth);
        }
      } else {
        if (mounted) setState(() => _errorMessage = "ANALYSIS_PROTOCOL_FAILED: Remote host refused request.");
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "CONNECTIVITY_FAILURE: Diagnostic stream interrupted.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshProfileData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/data'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ResumeService().syncFromBackend(data);
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("SkillGap: Sync error");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResumeService();
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Column(
        children: [
          const Navbar(),
          Expanded(
            child: rs.selectedRole == null
                ? _buildEmptyState(theme)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SKILL_GAP_ANALYSIS.EXE",
                          style: theme.textTheme.labelLarge,
                        ).animate().fadeIn().slideX(),
                        Text(
                          "Differential Diagnostic Mapping",
                          style: theme.textTheme.displayMedium,
                        ).animate().fadeIn(delay: 200.ms).slideX(),
                        const SizedBox(height: 32),
                        
                        _buildTargetHeader(rs, theme).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 32),

                        _buildSkillGroup(
                          "PROTOCOLS_DETECTED", 
                          rs.extractedSkills, 
                          AppTheme.primaryNeon,
                        ).animate().fadeIn(delay: 600.ms),
                        
                        const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Divider()),

                        _buildMissingSkillGroup(
                          "SYSTEM_DELTA (MISSING)", 
                          rs.dynamicMissingSkills, 
                          AppTheme.accentPurple,
                        ).animate().fadeIn(delay: 800.ms),
                           
                        const SizedBox(height: 48),
                        if (!_isLoading && rs.dynamicMissingSkills.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressTrackerScreen())),
                              icon: const Icon(Icons.rocket_launch_outlined),
                              label: const Text("INITIALIZE_TRAINING_TRACKER"),
                            ),
                          ).animate().fadeIn(delay: 1000.ms),
                        
                        const SizedBox(height: 16),
                        if (ResumeService().careerPathUrl != null)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                 final url = ResumeService().careerPathUrl!;
                                 if (kIsWeb) html.window.open(url, "_blank");
                                 else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("URL: $url")));
                              },
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: const Text("EXPORT_DIAGNOSTIC_REPORT (PDF)"),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.borderSubtle),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ).animate().fadeIn(delay: 1100.ms),
                      ],
                    ),
                   ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetHeader(ResumeService rs, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.gps_fixed, color: AppTheme.secondaryBlue, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("CURRENT_TARGET", style: theme.textTheme.labelLarge?.copyWith(fontSize: 10, color: AppTheme.textDim)),
                const SizedBox(height: 4),
                Text(
                  rs.selectedRole?.toUpperCase() ?? "UNDEFINED",
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontFamily: 'JetBrainsMono'),
                ),
                if (rs.selectedCompany != null)
                  Text("DOMAIN: ${rs.selectedCompany}", style: const TextStyle(color: AppTheme.secondaryBlue, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: _fetchDynamicSkillGap,
                icon: const Icon(Icons.refresh, size: 18, color: AppTheme.primaryNeon),
                tooltip: "RESCAN",
              ),
              IconButton(
                onPressed: _refreshProfileData,
                icon: const Icon(Icons.sync, size: 18, color: AppTheme.textDim),
                tooltip: "SYNC",
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 64, color: AppTheme.accentPurple),
          const SizedBox(height: 24),
          const Text("SYSTEM_ERROR: TARGET_SPEC_NULL", style: TextStyle(color: Colors.white, fontFamily: 'JetBrainsMono', fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text("Initialize target career trajectory before starting analysis.", style: TextStyle(color: AppTheme.textDim)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("RETURN_TO_BASE"),
          )
        ],
      ),
    );
  }

  Widget _buildSkillGroup(String title, List<String> skills, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono')),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: skills.isNotEmpty
              ? skills.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(s.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, fontFamily: 'JetBrainsMono')),
                )).toList()
              : [const Text("ZERO_DATA: No skills parsed.", style: TextStyle(color: AppTheme.textDim, fontSize: 12))],
        ),
      ],
    );
  }

  Widget _buildMissingSkillGroup(String title, List<String> skills, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono')),
        const SizedBox(height: 20),
        if (_isLoading)
           const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: AppTheme.primaryNeon)))
        else if (_errorMessage != null)
           Text(_errorMessage!, style: TextStyle(color: color, fontSize: 12))
        else if (skills.isEmpty)
           const Text("STATUS: OPTIMIZED. Delta within acceptable margins.", style: TextStyle(color: AppTheme.primaryNeon, fontSize: 12, fontStyle: FontStyle.italic))
        else
           Wrap(
             spacing: 12,
             runSpacing: 12,
             children: skills.map((s) => Container(
               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
               decoration: BoxDecoration(
                 color: color.withOpacity(0.05),
                 borderRadius: BorderRadius.circular(4),
                 border: Border.all(color: color.withOpacity(0.3)),
               ),
               child: Text(s.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, fontFamily: 'JetBrainsMono')),
             )).toList().animate(interval: 50.ms).fadeIn().scale(),
           ),
      ],
    );
  }
}