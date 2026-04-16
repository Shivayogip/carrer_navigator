import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ResumeIntelligence extends StatefulWidget {
  const ResumeIntelligence({super.key});

  @override
  State<ResumeIntelligence> createState() => _ResumeIntelligenceState();
}

class _ResumeIntelligenceState extends State<ResumeIntelligence> {
  PlatformFile? selectedFile;
  Map<String, dynamic>? analysisResult;
  bool isLoading = false;

  Future<void> pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true,
    );

    if (res != null) {
      setState(() {
        selectedFile = res.files.single;
        analysisResult = null;
      });
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:5000/api/resume/upload'),
      );

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'resume',
          selectedFile!.bytes!,
          filename: selectedFile!.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'resume',
          selectedFile!.path!,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          analysisResult = data;
        });

        // Save data to User Dashboard
        if (mounted) {
          final auth = Provider.of<AuthService>(context, listen: false);
          if (auth.token != null) {
            try {
              await http.post(
                Uri.parse('http://localhost:5000/api/user/save_data'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${auth.token}',
                },
                body: jsonEncode({
                  'resume_text': '',
                  'score': data['resume_score'] ?? 0,
                  'skills': data['skills'] != null ? jsonEncode(data['skills']) : '',
                }),
              );
            } catch (e) {
              debugPrint("Failed to save data: $e");
            }
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildSection(String title, dynamic items, {Color? color}) {
    if (items == null) return const SizedBox.shrink();
    List<dynamic> itemList = items is List ? items : [items];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: color ?? const Color(0xFF6366F1),
              ),
            ),
            const Divider(height: 24),
            ...itemList.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(e.toString())),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Resume Intelligence", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 64, color: Color(0xFF6366F1)),
                      const SizedBox(height: 16),
                      const Text(
                        "Upload your resume (PDF/DOCX)",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: pickFile,
                            icon: const Icon(Icons.file_present),
                            label: const Text("Select File"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: selectedFile == null || isLoading ? null : uploadFile,
                            icon: isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.analytics_outlined),
                            label: const Text("Analyze Resume"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (selectedFile != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          "Selected: ${selectedFile!.name}",
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (analysisResult != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _ScoreCard(
                        score: analysisResult!['resume_score'] ?? 0,
                        label: "Resume Score",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                buildSection("Top Skills", analysisResult!['skills']),
                buildSection("Missing Skills for Target Roles", analysisResult!['missing_skills_for_roles'], color: Colors.orange),
                buildSection("Key Projects", analysisResult!['projects']),
                buildSection("Suggestions for Improvement", analysisResult!['suggestions'], color: Colors.green),
                if (analysisResult!['career_roadmap'] != null)
                  buildSection(
                    "AI Career Roadmap", 
                    (analysisResult!['career_roadmap'] as List).map((r) => "${r['goal']} (${r['duration']})").toList(),
                    color: Colors.purple,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final int score;
  final String label;

  const _ScoreCard({required this.score, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF6366F1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "$score%",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
