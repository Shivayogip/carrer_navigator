import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, ChangeNotifier;
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;
import 'package:syncfusion_flutter_pdf/pdf.dart' as spdf;
import 'package:flutter/material.dart' show Rect, Offset;

class ResumeService extends ChangeNotifier {
  // 🔒 Singleton (one global instance)
  static final ResumeService _instance = ResumeService._internal();

  factory ResumeService() {
    return _instance;
  }

  ResumeService._internal();

  // 📄 STORED DATA
  String resumeText = "";
  List<String> extractedSkills = [];
  String? selectedRole;
  String? selectedCompany;
  List<String> dynamicMissingSkills = [];
  
  // 🤖 AI CONTENT
  String? careerPathMarkdown;
  String? roadmapMarkdown;
  String? projectsMarkdown;
  int? resumeScore;

  // 🔗 PDF URLs
  String? resumeAnalysisUrl;
  String? careerPathUrl;
  String? roadmapUrl;
  String? projectsUrl;
  String? resumeBuilderUrl;

  // 🔥 SET RESUME
  void setResume(String text) {
    resumeText = text;
    extractedSkills = extractSkills(text);
  }

  // 🔄 SYNC FROM BACKEND DATA
  void syncFromBackend(Map<String, dynamic> data) {
    debugPrint("ResumeService: Syncing from backend data Keys: ${data.keys.toList()}");
    
    // 1. Skills (Support both direct List and JSON string)
    if (data['skills'] != null) {
      try {
        if (data['skills'] is List) {
          extractedSkills = List<String>.from(data['skills']);
        } else if (data['skills'] is String && (data['skills'] as String).isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(data['skills']);
          extractedSkills = decoded.map((e) => e.toString()).toList();
        }
        debugPrint("ResumeService: Synced ${extractedSkills.length} skills");
      } catch (e) {
        debugPrint("ResumeService: Error syncing skills: $e");
        if (data['skills'] is String) {
          extractedSkills = (data['skills'] as String).split(',').map((s) => s.trim()).toList();
        }
      }
    }

    // 2. Resume Text
    if (data['resume_text'] != null && (data['resume_text'] as String).isNotEmpty) {
      resumeText = data['resume_text'];
      debugPrint("ResumeService: Synced resume text");
    }

    // 3. Score (Support 'score' from DB and 'resume_score' from AI)
    final dynamic score = data['score'] ?? data['resume_score'];
    if (score != null) {
      resumeScore = (score is int) ? score : int.tryParse(score.toString()) ?? 0;
      debugPrint("ResumeService: Synced score: $resumeScore");
    }

    // 4. Role & Company
    if (data['role'] != null && (data['role'] as String).isNotEmpty) {
      selectedRole = data['role'];
      debugPrint("ResumeService: Synced role: $selectedRole");
    }
    if (data['target_company'] != null && (data['target_company'] as String).isNotEmpty) {
      selectedCompany = data['target_company'];
    }

    // 5. Roadmaps (Support both Markdown string and List of Steps from AI)
    final dynamic roadmap = data['career_roadmap'] ?? data['roadmap'];
    if (roadmap != null) {
      if (roadmap is String && roadmap.isNotEmpty) {
        roadmapMarkdown = roadmap;
        debugPrint("ResumeService: Synced roadmap (String)");
      } else if (roadmap is List) {
        // Convert AI structured list to Markdown
        String md = "## AI Career Roadmap\n\n";
        for (var step in roadmap) {
          if (step is Map) {
            md += "### Step ${step['step'] ?? '?'}: ${step['goal'] ?? ''}\n";
            md += "- **Duration**: ${step['duration'] ?? 'Flexible'}\n\n";
          } else {
            md += "- $step\n";
          }
        }
        roadmapMarkdown = md;
        debugPrint("ResumeService: Converted List roadmap to Markdown");
      }
    }

    // 6. Missing Skills (Support 'missing_skills' from DB and 'missing_skills_for_roles' from AI)
    final dynamic missing = data['missing_skills'] ?? data['missing_skills_for_roles'];
    if (missing != null) {
      try {
        if (missing is List) {
          dynamicMissingSkills = List<String>.from(missing);
        } else if (missing is String && missing.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(missing);
          dynamicMissingSkills = decoded.map((e) => e.toString()).toList();
        }
        debugPrint("ResumeService: Synced ${dynamicMissingSkills.length} missing skills");
      } catch (e) {
        if (missing is String) {
          dynamicMissingSkills = missing.split(',').map((s) => s.trim()).toList();
        }
      }
    }

    // 7. Projects
    if (data['project_recommendations'] != null && (data['project_recommendations'] as String).isNotEmpty) {
      projectsMarkdown = data['project_recommendations'];
      debugPrint("ResumeService: Synced project recommendations");
    }
    
    if (data['career_path'] != null && (data['career_path'] as String).isNotEmpty) {
      careerPathMarkdown = data['career_path'];
    }

    // 9. PDF URLs
    resumeAnalysisUrl = data['resume_analysis_url'];
    careerPathUrl = data['career_path_url'];
    roadmapUrl = data['career_roadmap_url'] ?? data['roadmap_url'];
    projectsUrl = data['project_recommendations_url'] ?? data['projects_url'];
    resumeBuilderUrl = data['resume_builder_url'];
    
    print("ResumeService: URLs Synced - Analysis: $resumeAnalysisUrl, Roadmap: $roadmapUrl");
  }

  // 💾 SAVE TO BACKEND
  Future<bool> saveData(dynamic authService) async {
    if (authService.token == null) {
      debugPrint("ResumeService: Cannot save - no auth token");
      return false;
    }

    try {
      final Map<String, dynamic> payload = {};
      if (resumeText.isNotEmpty) payload['resume_text'] = resumeText;
      if (extractedSkills.isNotEmpty) payload['skills'] = jsonEncode(extractedSkills);
      if (selectedRole != null && selectedRole!.isNotEmpty) payload['role'] = selectedRole;
      if (resumeScore != null) payload['score'] = resumeScore;
      if (selectedCompany != null && selectedCompany!.isNotEmpty) payload['target_company'] = selectedCompany;
      if (careerPathMarkdown != null && careerPathMarkdown!.isNotEmpty) payload['career_path'] = careerPathMarkdown;
      if (roadmapMarkdown != null && roadmapMarkdown!.isNotEmpty) payload['career_roadmap'] = roadmapMarkdown;
      if (projectsMarkdown != null && projectsMarkdown!.isNotEmpty) payload['project_recommendations'] = projectsMarkdown;
      if (dynamicMissingSkills.isNotEmpty) payload['missing_skills'] = jsonEncode(dynamicMissingSkills);

      debugPrint("ResumeService: Saving payload keys: ${payload.keys.toList()}");

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/user/save_data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authService.token}',
        },
        body: jsonEncode(payload),
      );

      debugPrint("ResumeService: Save response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['urls'] != null) {
          final urls = data['urls'];
          resumeAnalysisUrl = urls['resume_analysis_url'] ?? resumeAnalysisUrl;
          careerPathUrl = urls['career_path_url'] ?? careerPathUrl;
          roadmapUrl = urls['career_roadmap_url'] ?? roadmapUrl;
          projectsUrl = urls['project_recommendations_url'] ?? projectsUrl;
          resumeBuilderUrl = urls['resume_builder_url'] ?? resumeBuilderUrl;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("ResumeService: Error saving data: $e");
      return false;
    }
  }

  // 📄 LOCAL PDF GENERATION (Frontend Only)
  Future<void> generateLocalPdf(String title, String markdownContent) async {
    final spdf.PdfDocument document = spdf.PdfDocument();
    final spdf.PdfPage page = document.pages.add();
    final spdf.PdfGraphics graphics = page.graphics;
    
    final spdf.PdfFont titleFont = spdf.PdfStandardFont(spdf.PdfFontFamily.helvetica, 22, style: spdf.PdfFontStyle.bold);
    final spdf.PdfFont h1Font = spdf.PdfStandardFont(spdf.PdfFontFamily.helvetica, 16, style: spdf.PdfFontStyle.bold);
    final spdf.PdfFont h2Font = spdf.PdfStandardFont(spdf.PdfFontFamily.helvetica, 14, style: spdf.PdfFontStyle.bold);
    final spdf.PdfFont bodyFont = spdf.PdfStandardFont(spdf.PdfFontFamily.helvetica, 10);
    
    double y = 0;

    // Header Title
    graphics.drawString(title.toUpperCase(), titleFont, bounds: const Rect.fromLTWH(0, 0, 500, 40));
    y += 45;
    graphics.drawLine(spdf.PdfPen(spdf.PdfColor(100, 100, 100)), Offset(0, y), Offset(515, y));
    y += 25;

    // Simple Markdown Parsing
    final List<String> lines = markdownContent.split('\n');
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        y += 10;
        continue;
      }

      spdf.PdfFont currentFont = bodyFont;
      double currentHeight = 15;
      String textToDraw = line;

      if (line.startsWith('# ')) {
        currentFont = h1Font;
        textToDraw = line.substring(2);
        currentHeight = 30;
        y += 10;
      } else if (line.startsWith('## ')) {
        currentFont = h2Font;
        textToDraw = line.substring(3);
        currentHeight = 25;
        y += 8;
      } else if (line.startsWith('### ')) {
        currentFont = h2Font;
        textToDraw = line.substring(4);
        currentHeight = 22;
        y += 5;
      } else if (line.startsWith('* ') || line.startsWith('- ')) {
        textToDraw = "• ${line.substring(2)}";
        currentHeight = 18;
      } else if (line[0:1].contains(RegExp(r'[0-9]')) && line.contains('.')) {
        textToDraw = line;
        currentHeight = 18;
      }

      // Consistent drawing using PdfTextElement for automatic wrapping and height calculation
      final spdf.PdfTextElement element = spdf.PdfTextElement(text: textToDraw, font: currentFont);
      final spdf.PdfLayoutResult result = element.draw(
        page: page,
        bounds: Rect.fromLTWH(line.startsWith('* ') || line.startsWith('- ') ? 15 : 0, y, 500, 0),
      )!;
      
      y = result.bounds.bottom + 10; // Ensure y always advances past the drawn block
      
      // Basic Page Break Logic
      if (y > 720) {
        // Simple page break - just reset to top for now
        // A better implementation would add a new page
        y = 50; 
      }
    }

    final List<int> bytes = await document.save();
    document.dispose();

    await _saveAndLaunch(bytes, "${title.replaceAll(' ', '_')}.pdf", "application/pdf");
  }

  Future<void> _saveAndLaunch(List<int> bytes, String fileName, String mimeType) async {
    if (kIsWeb) {
      final String base64data = base64Encode(bytes);
      final String dataUrl = 'data:$mimeType;base64,$base64data';
      html.AnchorElement(href: dataUrl)
        ..setAttribute("download", fileName)
        ..click();
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
      } catch (e) {
        debugPrint("Local save not supported: $e");
      }
    }
  }

  // 🎯 SET TARGET ROLE & COMPANY
  void setTarget(String role, {String? company}) {
    selectedRole = role;
    selectedCompany = company;
    dynamicMissingSkills = []; // reset missing skills upon target change
  }

  // 🧠 SKILL EXTRACTION LOGIC
  List<String> extractSkills(String text) {
    List<String> skillsDatabase = [
      "java",
      "python",
      "c++",
      "flutter",
      "react",
      "html",
      "css",
      "javascript",
      "node",
      "express",
      "mongodb",
      "sql",
      "dsa",
      "oop",
      "machine learning",
      "deep learning",
      "ai",
      "data science",
      "pandas",
      "numpy",
      "tensorflow",
      "docker",
      "kubernetes",
      "aws",
      "linux",
      "git",
      "github"
    ];

    text = text.toLowerCase();

    return skillsDatabase
        .where((skill) => text.contains(skill))
        .toSet() // remove duplicates
        .toList();
  }

  // 🧹 OPTIONAL: CLEAR DATA (for reset/logout)
  void clearAll() {
    resumeText = "";
    extractedSkills = [];
    selectedRole = null;
    selectedCompany = null;
    dynamicMissingSkills = [];
    careerPathMarkdown = null;
    roadmapMarkdown = null;
    projectsMarkdown = null;
    resumeScore = null;
  }

  // 📥 DIRECT EXPORT (Bypasses Storage)
  Future<bool> exportPdfDirect(String title, String content) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/pdf/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "title": title,
          "content": content,
        }),
      );

      if (response.statusCode == 200) {
        final List<int> bytes = response.bodyBytes;
        final String fileName = "${title.replaceAll(' ', '_')}.pdf";
        
        if (kIsWeb) {
          final String base64data = base64Encode(bytes);
          final String dataUrl = 'data:application/pdf;base64,$base64data';
          html.AnchorElement(href: dataUrl)
            ..setAttribute("download", fileName)
            ..click();
        } else {
          // Mobile Fallback
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(bytes);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("ResumeService: Direct Export Error: $e");
      return false;
    }
  }
}