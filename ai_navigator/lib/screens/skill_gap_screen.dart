import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/resume_service.dart';
import '../widgets/navbar.dart';
import 'progress_tracker_screen.dart';
import '../services/api_config.dart';

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
    
    final prompt = "I currently have the following technical skills: ${skills.isEmpty ? 'None' : skills.join(', ')}. I want to apply for the position of '$targetContext'. Identify the critical missing hard skills from my repertoire. Return ONLY a comma-separated string of missing technical skills or tools that I need to learn (e.g. Docker, TypeScript, GraphQL). Limit it to a maximum of 10 highly relevant skills. Do not include bullet points, paragraphs, or extra text.";

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
        }
      } else {
        if (mounted) setState(() => _errorMessage = "Error fetching skill gap assessment.");
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResumeService();
    
    return Scaffold(
      appBar: const Navbar(),
      body: rs.selectedRole == null
          ? const Center(child: Text("⚠️ Select a Target Role in Career Prediction to calculate your skill gap.", style: TextStyle(fontSize: 16)))
          : Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Skill Gap Analysis for ${rs.selectedRole} ${rs.selectedCompany != null ? 'at ${rs.selectedCompany}' : ''}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                  const SizedBox(height: 8),
                  const Text("AI has analyzed your current resume and identified the critical missing skills required for this specific constraint.", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 32),
                  
                  // User skills
                  const Text("You already have:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rs.extractedSkills.isNotEmpty
                        ? rs.extractedSkills.map((s) => Chip(label: Text(s), backgroundColor: Colors.green[100])).toList()
                        : [const Text("No skills detected.")],
                  ),
                  
                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),

                  // Missing skills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("You need to learn:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                      if (!_isLoading)
                        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchDynamicSkillGap, tooltip: "Recalculate with AI"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_isLoading)
                     const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
                  else if (_errorMessage != null)
                     Text(_errorMessage!, style: const TextStyle(color: Colors.red))
                  else
                     Wrap(
                       spacing: 8,
                       runSpacing: 8,
                       children: rs.dynamicMissingSkills.map((s) => Chip(label: Text(s), backgroundColor: Colors.red[100])).toList(),
                     ),
                     
                  const Spacer(),
                  if (!_isLoading && rs.dynamicMissingSkills.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const ProgressTrackerScreen()));
                        },
                        icon: const Icon(Icons.track_changes),
                        label: const Text("Export to Progress Tracker", style: TextStyle(fontSize: 16)),
                      ),
                    )
                ],
              ),
            ),
    );
  }
}