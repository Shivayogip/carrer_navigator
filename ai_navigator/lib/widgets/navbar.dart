import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/contact_us_screen.dart';

import '../screens/resume_intelligence.dart';
import '../screens/career_path_screen.dart';
import '../screens/skill_gap_screen.dart';
import '../screens/roadmap_screen.dart';
import '../screens/project_recommendation_screen.dart';
import '../screens/github_analyzer_screen.dart';
import '../screens/resume_scoring_screen.dart';
import '../screens/interview_prep_screen.dart';
import '../screens/progress_tracker_screen.dart';

Route fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

class Navbar extends StatefulWidget implements PreferredSizeWidget {
  const Navbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int hoverIndex = -1;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Material(
      elevation: 4,
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 800;

          return Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LOGO
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 28),
                    SizedBox(width: 8),
                    Text(
                      "AI Career Navigator",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),

                // RIGHT CONTENTS
                if (isMobile)
                  _buildMobileMenu(context, authService)
                else
                  _buildDesktopMenu(context, authService),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildDesktopMenu(BuildContext context, AuthService authService) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        navItem("Home", 0, () {
          Navigator.pushAndRemoveUntil(context, fadeRoute(const DashboardScreen()), (route) => false);
        }),
        featuresDropdown(),
        navItem("Contact Us", 2, () {
          Navigator.push(context, fadeRoute(const ContactUsScreen()));
        }),
        const SizedBox(width: 20),
        
        if (authService.user != null)
          ElevatedButton.icon(
            onPressed: () async {
              await authService.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, fadeRoute(const LoginScreen()), (route) => false);
              }
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileMenu(BuildContext context, AuthService authService) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.menu, color: Color(0xFF1F2937)),
      offset: const Offset(0, 50),
      onSelected: (value) async {
        switch (value) {
          case 0: Navigator.pushAndRemoveUntil(context, fadeRoute(const DashboardScreen()), (route) => false); break;
          case 1: Navigator.push(context, fadeRoute(const ContactUsScreen())); break;
          case 2: 
            await authService.signOut();
            if (mounted) Navigator.pushAndRemoveUntil(context, fadeRoute(const LoginScreen()), (route) => false);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0, child: Text("Home")),
        const PopupMenuItem(value: 1, child: Text("Contact Us")),
        if (authService.user != null) const PopupMenuItem(value: 2, child: Text("Logout", style: TextStyle(color: Colors.red))),
      ],
    );
  }

  Widget navItem(String text, int index, VoidCallback onTap) {
    bool isHover = hoverIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => hoverIndex = index),
      onExit: (_) => setState(() => hoverIndex = -1),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isHover ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isHover ? const Color(0xFF6366F1) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget featuresDropdown() {
    bool isHover = hoverIndex == 4;

    return MouseRegion(
      onEnter: (_) => setState(() => hoverIndex = 4),
      onExit: (_) => setState(() => hoverIndex = -1),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 50),
        onSelected: (value) {
          Widget? page;
          switch (value) {
            case "Resume Intelligence": page = const ResumeIntelligence(); break;
            case "Career Path Prediction": page = const CareerPathScreen(); break;
            case "Skill Gap Analysis": page = const SkillGapScreen(); break;
            case "AI Roadmap Generator": page = const RoadmapScreen(); break;
            case "Project Recommendation": page = const ProjectRecommendationScreen(); break;
            case "GitHub Analyzer": page = const GithubAnalyzerScreen(); break;
            case "Resume Scoring": page = const ResumeScoringScreen(); break;
            case "Interview Prep": page = const InterviewPrepScreen(); break;
            case "Progress Tracker": page = const ProgressTrackerScreen(); break;
          }

          if (page != null) {
            Navigator.push(context, fadeRoute(page));
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isHover ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text("Features", style: TextStyle(fontWeight: FontWeight.w600, color: isHover ? const Color(0xFF6366F1) : Colors.black87)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: isHover ? const Color(0xFF6366F1) : Colors.black87),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(value: "Resume Intelligence", child: featureMenuItem(Icons.description, "Resume Intelligence")),
          PopupMenuItem(value: "Career Path Prediction", child: featureMenuItem(Icons.auto_graph, "Career Path Prediction")),
          PopupMenuItem(value: "Skill Gap Analysis", child: featureMenuItem(Icons.analytics, "Skill Gap Analysis")),
          PopupMenuItem(value: "AI Roadmap Generator", child: featureMenuItem(Icons.map, "AI Roadmap Generator")),
          PopupMenuItem(value: "Project Recommendation", child: featureMenuItem(Icons.lightbulb, "Project Recommendation")),
          PopupMenuItem(value: "GitHub Analyzer", child: featureMenuItem(Icons.code, "GitHub Analyzer")),
          PopupMenuItem(value: "Resume Scoring", child: featureMenuItem(Icons.score, "Resume Scoring")),
          PopupMenuItem(value: "Interview Prep", child: featureMenuItem(Icons.record_voice_over, "Interview Prep")),
          PopupMenuItem(value: "Progress Tracker", child: featureMenuItem(Icons.track_changes, "Progress Tracker")),
        ],
      ),
    );
  }

  Widget featureMenuItem(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(width: 12),
        Text(title),
      ],
    );
  }
}