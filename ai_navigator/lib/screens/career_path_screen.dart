import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/resume_service.dart';
import '../widgets/navbar.dart';
import '../services/api_config.dart';

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
    
    if (ResumeService().extractedSkills.isNotEmpty) {
      _generateRecommendations();
    }
  }

  Future<void> _generateRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    
    final skills = ResumeService().extractedSkills;
    final prompt = "I have the following skills parsed from my resume: ${skills.join(', ')}. Please recommend 3 optimal career titles for me. Explain why they fit my skills. Format this purely in beautifully structured Markdown.";

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"message": prompt, "history": []}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) setState(() => _recommendationsMarkdown = data['response']);
      } else {
        if (mounted) setState(() => _recommendationsMarkdown = "Error fetching recommendations.");
      }
    } catch (e) {
      if (mounted) setState(() => _recommendationsMarkdown = "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }

  void _saveTarget() {
    final role = _roleController.text.trim();
    final company = _companyController.text.trim();
    
    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Target Role cannot be empty.")));
      return;
    }

    ResumeService().setTarget(role, company: company.isNotEmpty ? company : null);
    
    setState(() {}); // refresh the UI checkmark
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Career Goal set to $role ${company.isNotEmpty ? 'at $company' : ''}!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: AI Recommendations
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text("AI Recommended Careers", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                       ElevatedButton.icon(
                         onPressed: _isLoadingRecommendations ? null : _generateRecommendations,
                         icon: const Icon(Icons.refresh, size: 18),
                         label: const Text("Regenerate"),
                       )
                     ]
                  ),
                  const SizedBox(height: 16),
                  if (ResumeService().extractedSkills.isEmpty)
                     const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Upload a resume first in Resume Intelligence to get AI career recommendations.")))
                  else if (_isLoadingRecommendations)
                     const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()))
                  else if (_recommendationsMarkdown != null)
                     Expanded(
                       child: Container(
                         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                         padding: const EdgeInsets.all(20),
                         child: Markdown(data: _recommendationsMarkdown!),
                       )
                     )
                ],
              ),
            ),
          ),
          
          // Right Side: Manual Override Form
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(32),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("Set Career Goal", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                   const SizedBox(height: 8),
                   const Text("Manually specify your exact target role and preferred company to calibrate the AI across the entire app.", style: TextStyle(color: Colors.black54)),
                   const SizedBox(height: 32),
                   
                   TextField(
                     controller: _roleController,
                     decoration: InputDecoration(
                        labelText: "Target Role (e.g. Software Engineer)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.work)
                     ),
                   ),
                   const SizedBox(height: 20),
                   TextField(
                     controller: _companyController,
                     decoration: InputDecoration(
                        labelText: "Target Company (Optional, e.g. Google)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.business)
                     ),
                   ),
                   const SizedBox(height: 32),
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF6366F1),
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        onPressed: _saveTarget,
                        child: const Text("Lock in Goal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     ),
                   ),
                   
                   const SizedBox(height: 32),
                   if (ResumeService().selectedRole != null)
                     Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                       child: Row(
                         children: [
                           const Icon(Icons.check_circle, color: Colors.green),
                           const SizedBox(width: 12),
                           Expanded(child: Text("Currently targeting: ${ResumeService().selectedRole} ${ResumeService().selectedCompany != null ? 'at ${ResumeService().selectedCompany}' : ''}")),
                         ],
                       )
                     )
                ],
              ),
            )
          )
        ],
      )
    );
  }
}