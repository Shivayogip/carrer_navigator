import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import '../widgets/navbar.dart';

// Tool Screens
import 'ai_assistant_screen.dart';
import 'resume_intelligence.dart';
import 'career_path_screen.dart';
import 'skill_gap_screen.dart';
import 'roadmap_screen.dart';
import 'project_recommendation_screen.dart';
import 'github_analyzer_screen.dart';
import 'resume_scoring_screen.dart';
import 'interview_prep_screen.dart';
import 'progress_tracker_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/user/data'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
        },
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _userData = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const Navbar(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Welcome back, ${user?.displayName ?? user?.email ?? 'User'}!", 
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 32),
                
                // Stats Card
                if (_userData != null && _userData!['score'] != null && _userData!['score'] > 0) ...[
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: Colors.black12,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Current Resume Score", style: TextStyle(fontSize: 16, color: Colors.black54)),
                                  Text("${_userData!['score']}%", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                                ],
                              ),
                              Icon(Icons.trending_up, size: 64, color: Colors.green.withOpacity(0.2)),
                            ],
                          ),
                          const Divider(height: 32),
                          if (_userData!['skills'] != null && _userData!['skills'].toString().isNotEmpty) ...[
                             const Text("Detected Key Skills", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                             const SizedBox(height: 12),
                             Wrap(
                               spacing: 8,
                               runSpacing: 8,
                               children: _buildSkillsList(_userData!['skills'].toString()),
                             )
                          ]
                        ],
                      )
                    )
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                   Card(
                    elevation: 0,
                    color: Colors.blue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const ListTile(
                      leading: Icon(Icons.info, color: Colors.blue),
                      title: Text("Get Started"),
                      subtitle: Text("Upload your resume using Resume Intelligence to unlock personalized metrics."),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                const Text("AI Toolkit", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 16),
                
                // Toolbox Grid
                GridView.extent(
                  maxCrossAxisExtent: 220,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildActionCard(context, "Resume Analysis", Icons.document_scanner, Colors.blue, const ResumeIntelligence()),
                    _buildActionCard(context, "Career Path", Icons.auto_graph, Colors.green, const CareerPathScreen()),
                    _buildActionCard(context, "Skill Gap", Icons.analytics, Colors.orange, const SkillGapScreen()),
                    _buildActionCard(context, "Roadmap", Icons.map, Colors.indigo, const RoadmapScreen()),
                    _buildActionCard(context, "Projects", Icons.lightbulb, Colors.amber, const ProjectRecommendationScreen()),
                    _buildActionCard(context, "Report Card", Icons.score, Colors.teal, const ResumeScoringScreen()),
                    _buildActionCard(context, "Interview Prep", Icons.mic, Colors.red, const InterviewPrepScreen()),
                    _buildActionCard(context, "Progress", Icons.track_changes, Colors.cyan, const ProgressTrackerScreen()),
                    _buildActionCard(context, "GitHub Stats", Icons.code, Colors.black87, const GithubAnalyzerScreen()),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, fadeRoute(const AiAssistantScreen())),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 4,
        child: const Icon(Icons.chat_bubble, color: Colors.white),
      ),
    );
  }

  List<Widget> _buildSkillsList(String skillsStr) {
    if (skillsStr.length > 2 && skillsStr.startsWith('[')) {
      try {
        final List<dynamic> list = jsonDecode(skillsStr);
        return list.map((s) => Chip(
          label: Text(s.toString(), style: const TextStyle(fontSize: 12)),
          backgroundColor: Colors.blue[50],
          side: BorderSide(color: Colors.blue[100]!),
        )).toList();
      } catch (_) {}
    }
    return skillsStr.split(',').map((s) => Chip(
      label: Text(s.trim(), style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.blue[50], 
      side: BorderSide(color: Colors.blue[100]!)
    )).toList();
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, Widget screen) {
    return _AnimatedToolCard(
      title: title, 
      icon: icon, 
      color: color, 
      onTap: () => Navigator.push(context, fadeRoute(screen)),
    );
  }
}

class _AnimatedToolCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedToolCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  State<_AnimatedToolCard> createState() => _AnimatedToolCardState();
}

class _AnimatedToolCardState extends State<_AnimatedToolCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovering ? -6 : 0, 0)..scale(_isHovering ? 1.02 : 1.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (_isHovering)
                BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
              else
                const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_isHovering ? 16 : 12),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: _isHovering ? 36 : 32, color: widget.color),
                ),
                const Spacer(),
                Text(
                  widget.title, 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isHovering ? widget.color : const Color(0xFF374151))
                ),
              ],
            )
          )
        ),
      ),
    );
  }
}
