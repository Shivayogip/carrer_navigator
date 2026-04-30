import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart' as spdf;
import 'package:docx_creator/docx_creator.dart' as sdocx;
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';

import '../services/auth_service.dart';
import '../services/api_config.dart';
import '../services/resume_service.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';

class ResumeIntelligence extends StatefulWidget {
  const ResumeIntelligence({super.key});

  @override
  State<ResumeIntelligence> createState() => _ResumeIntelligenceState();
}

class _ResumeIntelligenceState extends State<ResumeIntelligence> {
  // Analyzer State
  PlatformFile? selectedFile;
  Map<String, dynamic>? analysisResult;
  bool isLoading = false;

  // Builder State
  bool _isAnalyzerMode = true;
  int _currentStep = 1; // 1 to 4
  int _selectedOption = 0; // 1: Scratch, 2: Upload/Enhance

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  // Work Experience (Static as requested in user snippet)
  final TextEditingController _job1Title = TextEditingController();
  final TextEditingController _job1Company = TextEditingController();
  final TextEditingController _job1Desc = TextEditingController();
  final TextEditingController _job2Title = TextEditingController();
  final TextEditingController _job2Company = TextEditingController();
  final TextEditingController _job2Desc = TextEditingController();

  // Education (Static as requested in user snippet)
  final TextEditingController _edu1School = TextEditingController();
  final TextEditingController _edu1Degree = TextEditingController();
  final TextEditingController _edu1Year = TextEditingController();

  int _selectedTemplateIndex = 0;

  @override
  void initState() {
    super.initState();
    // Pre-fill from auth if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.user != null) {
        _nameController.text = auth.user!.displayName ?? "";
        _emailController.text = auth.user!.email ?? "";
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    _job1Title.dispose();
    _job1Company.dispose();
    _job1Desc.dispose();
    _job2Title.dispose();
    _job2Company.dispose();
    _job2Desc.dispose();
    _edu1School.dispose();
    _edu1Degree.dispose();
    _edu1Year.dispose();
    super.dispose();
  }

  // --- LOGIC METHODS ---

  Future<void> pickFile() async {
    final res = await FilePicker.pickFiles(
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
      final auth = Provider.of<AuthService>(context, listen: false);
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/resume/upload'),
      );

      if (auth.token != null) {
        request.headers['Authorization'] = 'Bearer ${auth.token}';
      }

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'resume',
            selectedFile!.bytes!,
            filename: selectedFile!.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('resume', selectedFile!.path!),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          analysisResult = data;
        });

        // Sync to global service
        ResumeService().syncFromBackend(data);

        if (mounted) {
          final auth = Provider.of<AuthService>(context, listen: false);
          ResumeService().resumeScore = data['resume_score'] ?? 0;
          ResumeService().saveData(auth);
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _exportToServerAndDownload() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) return;

    setState(() => isLoading = true);

    try {
      final resumeData = {
        "name": _nameController.text,
        "email": _emailController.text,
        "summary": _summaryController.text,
        "skills": _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .toList(),
        "experience": [
          {
            "title": _job1Title.text,
            "company": _job1Company.text,
            "description": _job1Desc.text,
          },
          {
            "title": _job2Title.text,
            "company": _job2Company.text,
            "description": _job2Desc.text,
          },
        ],
        "education": [
          {
            "school": _edu1School.text,
            "degree": _edu1Degree.text,
            "year": _edu1Year.text,
          },
        ],
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/resume/generate_pdf'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: jsonEncode(resumeData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['url'];
        if (kIsWeb && url != null) {
          html.window.open(url, "_blank");
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("PDF Generated: $url")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _generatePDF() async {
    final spdf.PdfDocument document = spdf.PdfDocument();
    final spdf.PdfPage page = document.pages.add();
    final spdf.PdfGraphics graphics = page.graphics;
    final spdf.PdfFont titleFont = spdf.PdfStandardFont(
      spdf.PdfFontFamily.helvetica,
      24,
      style: spdf.PdfFontStyle.bold,
    );
    final spdf.PdfFont headerFont = spdf.PdfStandardFont(
      spdf.PdfFontFamily.helvetica,
      14,
      style: spdf.PdfFontStyle.bold,
    );
    final spdf.PdfFont bodyFont = spdf.PdfStandardFont(
      spdf.PdfFontFamily.helvetica,
      10,
    );
    final spdf.PdfFont italicFont = spdf.PdfStandardFont(
      spdf.PdfFontFamily.helvetica,
      10,
      style: spdf.PdfFontStyle.italic,
    );

    double y = 0;

    // Header
    graphics.drawString(
      _nameController.text.isEmpty
          ? "YOUR NAME"
          : _nameController.text.toUpperCase(),
      titleFont,
      bounds: const Rect.fromLTWH(0, 0, 500, 30),
    );
    y += 30;
    graphics.drawString(
      _emailController.text.isEmpty
          ? "email@example.com"
          : _emailController.text,
      bodyFont,
      bounds: Rect.fromLTWH(0, y, 500, 20),
    );
    y += 30;
    graphics.drawLine(
      spdf.PdfPen(spdf.PdfColor(200, 200, 200)),
      Offset(0, y),
      Offset(500, y),
    );
    y += 20;

    // Summary
    graphics.drawString(
      "PROFESSIONAL SUMMARY",
      headerFont,
      bounds: Rect.fromLTWH(0, y, 500, 20),
    );
    y += 20;
    graphics.drawString(
      _summaryController.text.isEmpty
          ? "No summary provided."
          : _summaryController.text,
      bodyFont,
      bounds: Rect.fromLTWH(0, y, 500, 80),
    );
    y += 80;

    // Experience
    if (_job1Title.text.isNotEmpty || _job2Title.text.isNotEmpty) {
      graphics.drawString(
        "PROFESSIONAL EXPERIENCE",
        headerFont,
        bounds: Rect.fromLTWH(0, y, 500, 20),
      );
      y += 25;
      if (_job1Title.text.isNotEmpty) {
        graphics.drawString(
          _job1Title.text,
          headerFont,
          bounds: Rect.fromLTWH(0, y, 500, 15),
        );
        y += 15;
        graphics.drawString(
          _job1Company.text,
          bodyFont,
          bounds: Rect.fromLTWH(0, y, 500, 15),
        );
        y += 15;
        graphics.drawString(
          _job1Desc.text,
          bodyFont,
          bounds: Rect.fromLTWH(0, y, 500, 40),
        );
        y += 50;
      }
    }

    // Education
    if (_edu1School.text.isNotEmpty) {
      graphics.drawString(
        "EDUCATION",
        headerFont,
        bounds: Rect.fromLTWH(0, y, 500, 20),
      );
      y += 25;
      graphics.drawString(
        _edu1School.text,
        headerFont,
        bounds: Rect.fromLTWH(0, y, 500, 15),
      );
      y += 15;
      graphics.drawString(
        "${_edu1Degree.text} | ${_edu1Year.text}",
        italicFont,
        bounds: Rect.fromLTWH(0, y, 500, 15),
      );
      y += 30;
    }

    // Skills
    graphics.drawString(
      "SKILLS",
      headerFont,
      bounds: Rect.fromLTWH(0, y, 500, 20),
    );
    y += 20;
    graphics.drawString(
      _skillsController.text.isEmpty
          ? "No skills added."
          : _skillsController.text,
      bodyFont,
      bounds: Rect.fromLTWH(0, y, 500, 40),
    );

    try {
      final List<int> bytes = await document.save();
      document.dispose();

      await _saveAndLaunch(
        bytes,
        'Resume_${_nameController.text.replaceAll(' ', '_')}.pdf',
        'application/pdf',
      );
    } catch (e) {
      debugPrint("PDF Generation Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to generate PDF: $e")));
      }
    }
  }

  Future<void> _generateDOCX() async {
    final doc = sdocx.docx();

    // Header
    doc.h1(
      _nameController.text.isEmpty
          ? "YOUR NAME"
          : _nameController.text.toUpperCase(),
    );
    doc.p(
      _emailController.text.isEmpty
          ? "email@example.com"
          : _emailController.text,
    );

    // Summary
    doc.h3("PROFESSIONAL SUMMARY");
    doc.p(
      _summaryController.text.isEmpty
          ? "No summary provided."
          : _summaryController.text,
    );

    // Experience
    if (_job1Title.text.isNotEmpty || _job2Title.text.isNotEmpty) {
      doc.h3("PROFESSIONAL EXPERIENCE");
      if (_job1Title.text.isNotEmpty) {
        doc.p("${_job1Title.text} - ${_job1Company.text}");
        doc.p(_job1Desc.text);
      }
      if (_job2Title.text.isNotEmpty) {
        doc.p("${_job2Title.text} - ${_job2Company.text}");
        doc.p(_job2Desc.text);
      }
    }

    // Education
    if (_edu1School.text.isNotEmpty) {
      doc.h3("EDUCATION");
      doc.p("${_edu1School.text} - ${_edu1Degree.text} (${_edu1Year.text})");
    }

    // Skills
    doc.h3("SKILLS");
    doc.p(
      _skillsController.text.isEmpty
          ? "No skills added."
          : _skillsController.text,
    );

    final docBuilt = doc.build();
    final List<int> bytes = await sdocx.DocxExporter().exportToBytes(docBuilt);
    await _saveAndLaunch(
      bytes,
      'Resume_${_nameController.text.replaceAll(' ', '_')}.docx',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  }

  Future<void> _saveAndLaunch(
    List<int> bytes,
    String fileName,
    String mimeType,
  ) async {
    if (kIsWeb) {
      try {
        final String base64data = base64Encode(bytes);
        final String dataUrl = 'data:$mimeType;base64,$base64data';
        final anchor = html.AnchorElement(href: dataUrl)
          ..setAttribute("download", fileName)
          ..click();
      } catch (e) {
        debugPrint("Download Error: $e");
      }
    } else {
      try {
        final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(bytes);
        
        // 🔥 Use OpenFilex to open on mobile
        await OpenFilex.open(path);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("OPEN_FILE: $fileName initialized."), backgroundColor: AppTheme.primaryNeon),
          );
        }
      } catch (e) {
        debugPrint("Local save not supported: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("SAVE_FAILURE: $e"), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  // --- UI BUILDING METHODS ---

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;
    
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            const Navbar(),
            _buildTopNavigation(isMobile),
            Expanded(
              child: AnimatedSwitcher(
                duration: 400.ms,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _isAnalyzerMode
                    ? _buildAnalyzerView(isMobile)
                    : _buildBuilderView(isMobile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: isMobile ? 12 : 24),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleButton(isMobile ? "ANALYZER" : "ANALYZER.EXE", _isAnalyzerMode, () {
            setState(() => _isAnalyzerMode = true);
          }),
          SizedBox(width: isMobile ? 8 : 16),
          _buildToggleButton(isMobile ? "BUILDER" : "BUILDER.SH", !_isAnalyzerMode, () {
            setState(() => _isAnalyzerMode = false);
          }),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryNeon.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? AppTheme.primaryNeon : AppTheme.borderSubtle,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryNeon.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            color: isActive ? AppTheme.primaryNeon : AppTheme.textDim,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- ANALYZER VIEW ---

  Widget _buildAnalyzerView(bool isMobile) {
    return SingleChildScrollView(
      key: const ValueKey('analyzer'),
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTerminalHeader("RESUME_DIAGNOSTICS", isMobile: isMobile),
          const SizedBox(height: 24),
          _buildAnalyzerCard(isMobile).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 32),
          if (analysisResult != null) ...[
            _ScoreCard(
              score: analysisResult!['resume_score'] ?? 0,
              label: "INTEGRITY_INDEX",
            ).animate().scale(delay: 200.ms),
            const SizedBox(height: 32),
            _buildCoderSection("CORE_SKILLS", analysisResult!['skills'], isMobile: isMobile),
            _buildCoderSection(
              "MISSING_DEPENDENCIES",
              analysisResult!['missing_skills_for_roles'],
              color: Colors.orangeAccent,
              isMobile: isMobile,
            ),
            _buildCoderSection("PROJECT_MODULES", analysisResult!['projects'], isMobile: isMobile),
            _buildCoderSection(
              "OPTIMIZATION_SUGGESTIONS",
              analysisResult!['suggestions'],
              color: AppTheme.secondaryBlue,
              isMobile: isMobile,
            ),
            if (analysisResult!['career_roadmap'] != null)
              _buildCoderSection(
                "AI_CAREER_ROADMAP",
                (analysisResult!['career_roadmap'] as List)
                    .map((r) => "[${r['duration']}] ${r['goal']}")
                    .toList(),
                color: AppTheme.accentPurple,
                isMobile: isMobile,
              ),
            const SizedBox(height: 24),
            if (ResumeService().resumeAnalysisUrl != null)
              _buildLargeNeonButton(
                label: "EXPORT_ANALYSIS_REPORT.PDF",
                icon: Icons.terminal,
                onPressed: () {
                  final url = ResumeService().resumeAnalysisUrl!;
                  if (kIsWeb)
                    html.window.open(url, "_blank");
                  else
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Link: $url")));
                },
                color: Colors.orangeAccent,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTerminalHeader(String title, {bool isMobile = false}) {
    return Row(
      children: [
        Icon(Icons.terminal, color: AppTheme.primaryNeon, size: isMobile ? 16 : 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            fontSize: isMobile ? 14 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(child: Divider(color: AppTheme.borderSubtle)),
      ],
    );
  }

  Widget _buildCoderSection(String title, dynamic items, {Color? color, bool isMobile = false}) {
    if (items == null) return const SizedBox.shrink();
    List<dynamic> itemList = items is List ? items : [items];

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 24),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
              Text(
                "// $title",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.bold,
                  color: color ?? AppTheme.secondaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...itemList.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "> ",
                    style: TextStyle(
                      color: AppTheme.primaryNeon,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.toString(),
                      style: const TextStyle(
                        color: AppTheme.textMain,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.05);
  }

  Widget _buildAnalyzerCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryNeon.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 64,
            color: AppTheme.primaryNeon,
          ),
          const SizedBox(height: 24),
          Text(
            "INPUT_STREAM_REQUIRED",
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Awaiting source file (PDF/DOCX) for neural analysis...",
            style: TextStyle(color: AppTheme.textDim, fontSize: 13),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOutlinedButton(
                label: "BROWSE",
                icon: Icons.file_present,
                onPressed: pickFile,
              ),
              const SizedBox(width: 20),
              _buildNeonButton(
                label: "INITIALIZE_SCAN",
                icon: Icons.analytics_outlined,
                onPressed: selectedFile == null || isLoading
                    ? null
                    : uploadFile,
                isLoading: isLoading,
              ),
            ],
          ),
          if (selectedFile != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: AppTheme.primaryNeon.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppTheme.primaryNeon,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    selectedFile!.name.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      color: AppTheme.primaryNeon,
                      fontSize: 12,
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

  // --- BUILDER VIEW ---

  Widget _buildBuilderView(bool isMobile) {
    return LayoutBuilder(
      key: const ValueKey('builder'),
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: isMobile ? 24 : 48,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTerminalHeader("RESUME_CONSTRUCTOR", isMobile: isMobile),
                  const SizedBox(height: 32),
                  _buildBuilderStepper(isMobile),
                  const SizedBox(height: 48),
                  AnimatedSwitcher(
                    duration: 300.ms,
                    child: _buildStepContent(isMobile),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 1)
                        _buildOutlinedButton(
                          label: "PREVIOUS_NODE",
                          icon: Icons.arrow_back,
                          onPressed: () => setState(() => _currentStep--),
                        )
                      else
                        const SizedBox.shrink(),
                      _buildNeonButton(
                        label: _currentStep == 4
                            ? "EXECUTE_GENERATE"
                            : "NEXT_NODE",
                        icon: _currentStep == 4
                            ? Icons.rocket_launch
                            : Icons.arrow_forward,
                        onPressed: () {
                          if (_currentStep < 4) {
                            setState(() => _currentStep++);
                          } else {
                            // Finish logic or handled in step 4
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBuilderStepper(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SYSTEM_SEQUENCE: STEP_0$_currentStep/04",
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.primaryNeon,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${(_currentStep / 4 * 100).toInt()}% COMPLETE",
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.textDim,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _currentStep / 4,
              backgroundColor: Colors.black,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryNeon),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator(
                1,
                "INIT",
                Icons.auto_awesome_motion,
                isMobile,
              ),
              _buildStepIndicator(
                2,
                "LAYOUT",
                Icons.grid_view_rounded,
                isMobile,
              ),
              _buildStepIndicator(
                3,
                "INPUT",
                Icons.edit_note_rounded,
                isMobile,
              ),
              _buildStepIndicator(
                4,
                "RENDER",
                Icons.visibility_rounded,
                isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    int step,
    String title,
    IconData icon,
    bool isMobile,
  ) {
    bool isDone = _currentStep > step;
    bool isActive = _currentStep == step;

    return Column(
      children: [
        AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive || isDone ? AppTheme.primaryNeon : Colors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive || isDone
                  ? AppTheme.primaryNeon
                  : AppTheme.borderSubtle,
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: isMobile ? 18 : 22,
            color: isActive || isDone ? Colors.black : AppTheme.textDim,
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.bold,
              color: isActive || isDone ? Colors.white : AppTheme.textDim,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepContent(bool isMobile) {
    switch (_currentStep) {
      case 1:
        return _buildStep1Option(isMobile);
      case 2:
        return _buildStep2Templates(isMobile);
      case 3:
        return _buildStep3Form(isMobile);
      case 4:
        return _buildStep4Preview(isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 1: OPTIONS ---

  Widget _buildStep1Option(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "// INITIALIZATION_MODE",
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.secondaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        if (isMobile) ...[
          _buildChoiceCard(
            title: "ZERO_STATE_BOOT",
            subtitle: "Initialize resume from scratch with neural assistance.",
            icon: Icons.edit_document,
            isSelected: _selectedOption == 1,
            onTap: () => setState(() => _selectedOption = 1),
            isMobile: isMobile,
          ),
          const SizedBox(height: 20),
          _buildChoiceCard(
            title: "LEGACY_IMPORT",
            subtitle: "Import existing profile data and optimize structure.",
            icon: Icons.cloud_upload_rounded,
            isSelected: _selectedOption == 2,
            onTap: () => setState(() => _selectedOption = 2),
            isMobile: isMobile,
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildChoiceCard(
                  title: "ZERO_STATE_BOOT",
                  subtitle:
                      "Initialize resume from scratch with neural assistance.",
                  icon: Icons.edit_document,
                  isSelected: _selectedOption == 1,
                  onTap: () => setState(() => _selectedOption = 1),
                  isMobile: isMobile,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildChoiceCard(
                  title: "LEGACY_IMPORT",
                  subtitle:
                      "Import existing profile data and optimize structure.",
                  icon: Icons.cloud_upload_rounded,
                  isSelected: _selectedOption == 2,
                  onTap: () => setState(() => _selectedOption = 2),
                  isMobile: isMobile,
                ),
              ),
            ],
          ),
        if (_selectedOption == 2) ...[
          const SizedBox(height: 32),
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.3)),
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 20,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SOURCE_FILE_LOADER",
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedFile != null
                          ? "READY: ${selectedFile!.name}"
                          : "Format support: [.pdf, .docx]",
                      style: TextStyle(
                        color: selectedFile != null
                            ? AppTheme.primaryNeon
                            : AppTheme.textDim,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                _buildOutlinedButton(
                  label: "LOAD_FILE",
                  icon: Icons.upload_file,
                  onPressed: pickFile,
                ),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ],
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isMobile = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryNeon.withOpacity(0.05)
              : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryNeon : AppTheme.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryNeon.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryNeon : Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.black : AppTheme.primaryNeon,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textDim,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (isSelected)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryNeon,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- STEP 2: TEMPLATES ---

  Widget _buildStep2Templates(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "// TEMPLATE_SELECTION_ALGORITHM",
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.secondaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 3,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: isMobile ? 1.4 : 0.85,
          ),
          itemCount: 3,
          itemBuilder: (context, index) {
            bool isSelected = index == _selectedTemplateIndex;
            return _buildTemplateCard(index, isSelected, isMobile);
          },
        ),
      ],
    );
  }

  Widget _buildTemplateCard(int index, bool isSelected, bool isMobile) {
    final titles = ["MINIMAL_MOD", "EXEC_CORE", "CREATIVE_SYNTAX"];
    final icons = [
      Icons.view_agenda_outlined,
      Icons.contact_page_outlined,
      Icons.dashboard_customize_outlined,
    ];

    return InkWell(
      onTap: () => setState(() => _selectedTemplateIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: 300.ms,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryNeon
                      : AppTheme.borderSubtle,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryNeon.withOpacity(0.15),
                          blurRadius: 15,
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      color: isSelected
                          ? AppTheme.primaryNeon
                          : AppTheme.borderSubtle,
                    ),
                    Expanded(
                      child: Center(
                        child: Icon(
                          icons[index],
                          size: isMobile ? 48 : 56,
                          color: isSelected
                              ? AppTheme.primaryNeon
                              : AppTheme.textDim,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: AppTheme.darkSurface,
                      child: Column(
                        children: List.generate(
                          3,
                          (i) => Container(
                            height: 3,
                            margin: const EdgeInsets.only(bottom: 6),
                            color: AppTheme.borderSubtle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            titles[index],
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.primaryNeon : AppTheme.textDim,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: FORM ---

  Widget _buildStep3Form(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "// DATA_ENTRY_SEQUENCE",
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.secondaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        _buildFormSection("USER_IDENTITY", [
          _buildCoderTextField(
            "ID.FULL_NAME",
            "Awaiting input...",
            controller: _nameController,
          ),
          _buildCoderTextField(
            "ID.EMAIL_ADDR",
            "user@example.sh",
            controller: _emailController,
          ),
        ]),
        const SizedBox(height: 40),
        _buildFormSection("PROFESSIONAL_SYNOPSIS", [
          _buildCoderTextField(
            "SYNOPSIS_BUFFER",
            "String summary = ...",
            maxLines: 4,
            controller: _summaryController,
          ),
        ]),
        const SizedBox(height: 40),
        _buildFormSection("EXPERIENCE_BLOCK_01", [
          _buildCoderTextField(
            "EXP1.TITLE",
            "Role title...",
            controller: _job1Title,
          ),
          _buildCoderTextField(
            "EXP1.COMPANY",
            "Organization...",
            controller: _job1Company,
          ),
          _buildCoderTextField(
            "EXP1.LOG",
            "Execution details...",
            maxLines: 3,
            controller: _job1Desc,
          ),
        ]),
        const SizedBox(height: 40),
        _buildFormSection("EXPERIENCE_BLOCK_02", [
          _buildCoderTextField(
            "EXP2.TITLE",
            "Role title...",
            controller: _job2Title,
          ),
          _buildCoderTextField(
            "EXP2.COMPANY",
            "Organization...",
            controller: _job2Company,
          ),
          _buildCoderTextField(
            "EXP2.LOG",
            "Execution details...",
            maxLines: 3,
            controller: _job2Desc,
          ),
        ]),
        const SizedBox(height: 40),
        _buildFormSection("EDUCATION_INDEX", [
          _buildCoderTextField(
            "EDU.INSTITUTION",
            "University...",
            controller: _edu1School,
          ),
          _buildCoderTextField(
            "EDU.DEGREE",
            "Degree type...",
            controller: _edu1Degree,
          ),
          _buildCoderTextField(
            "EDU.TIMESTAMP",
            "Year...",
            controller: _edu1Year,
          ),
        ]),
        const SizedBox(height: 40),
        _buildFormSection("SKILLS_ARRAY", [
          _buildCoderTextField(
            "SKILLS.CSV",
            "Flutter, Dart, Python...",
            controller: _skillsController,
          ),
        ]),
      ],
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.subdirectory_arrow_right,
              size: 14,
              color: AppTheme.primaryNeon,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildCoderTextField(
    String label,
    String hint, {
    int maxLines = 1,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppTheme.textDim,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: (v) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppTheme.textDim.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.primaryNeon),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 4: PREVIEW ---

  Widget _buildStep4Preview(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "// RENDER_OUTPUT_PREVIEW",
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.secondaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 24 : 48),
          decoration: BoxDecoration(
            color: Colors.white, // Classic paper look for preview
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryNeon.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Content
              Text(
                _nameController.text.isEmpty
                    ? "YOUR NAME"
                    : _nameController.text.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                _emailController.text.isEmpty
                    ? "email@example.com"
                    : _emailController.text,
                style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14),
              ),
              const Divider(height: 40, thickness: 1, color: Colors.black),

              _buildPreviewSection(
                "SUMMARY",
                _summaryController.text.isEmpty
                    ? "Enter summary..."
                    : _summaryController.text,
              ),

              if (_job1Title.text.isNotEmpty || _job2Title.text.isNotEmpty) ...[
                _buildPreviewSectionHeader("EXPERIENCE"),
                if (_job1Title.text.isNotEmpty)
                  _buildPreviewExperience(
                    _job1Title.text,
                    _job1Company.text,
                    _job1Desc.text,
                  ),
                if (_job2Title.text.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildPreviewExperience(
                    _job2Title.text,
                    _job2Company.text,
                    _job2Desc.text,
                  ),
                ],
              ],

              if (_edu1School.text.isNotEmpty) ...[
                _buildPreviewSectionHeader("EDUCATION"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _edu1School.text,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      _edu1Year.text,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Text(
                  _edu1Degree.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[800],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              _buildPreviewSection(
                "SKILLS",
                _skillsController.text.isEmpty
                    ? "Add skills..."
                    : _skillsController.text,
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        _buildTerminalHeader("EXPORT_MODULES"),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.start,
          children: [
            _buildExportButton(
              label: "PDF",
              icon: Icons.picture_as_pdf,
              color: Colors.redAccent,
              onPressed: () => _generatePDF(),
            ),
            _buildExportButton(
              label: "DOCX",
              icon: Icons.description_outlined,
              color: AppTheme.secondaryBlue,
              onPressed: () => _generateDOCX(),
            ),
            _buildExportButton(
              label: "CLOUD_GEN",
              icon: Icons.cloud_done,
              color: AppTheme.primaryNeon,
              onPressed: () => _exportToServerAndDownload(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildPreviewSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreviewSectionHeader(title),
        Text(
          content,
          style: const TextStyle(
            height: 1.5,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewExperience(String title, String company, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        Text(
          company,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // --- HELPER COMPONENTS ---

  Widget _buildNeonButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryNeon,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: AppTheme.borderSubtle),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLargeNeonButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text("EXPORT_$label"),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: color.withOpacity(0.05),
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
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.textDim,
                  fontSize: 12,
                ),
              ),
              const Icon(Icons.memory, color: AppTheme.primaryNeon, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$score",
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  "%",
                  style: TextStyle(
                    color: AppTheme.primaryNeon,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              _buildHealthIndicator(score),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: 1000.ms,
                curve: Curves.easeOutCubic,
                height: 8,
                width:
                    MediaQuery.of(context).size.width *
                    (score / 100) *
                    0.7, // Rough approx for demo
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryNeon.withOpacity(0.5),
                      AppTheme.primaryNeon,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(int score) {
    String status = score > 80
        ? "OPTIMIZED"
        : score > 50
        ? "FUNCTIONAL"
        : "CRITICAL";
    Color color = score > 80
        ? AppTheme.primaryNeon
        : score > 50
        ? Colors.orangeAccent
        : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        status,
        style: GoogleFonts.jetBrainsMono(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
