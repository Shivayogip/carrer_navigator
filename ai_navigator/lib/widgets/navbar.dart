import 'package:ai_navigator/screens/github_analyzer_screen.dart';
import 'package:ai_navigator/screens/interview_prep_screen.dart';
import 'package:ai_navigator/screens/project_recommendation_screen.dart';
import 'package:ai_navigator/screens/resume_scoring_screen.dart';
import 'package:flutter/material.dart';

// EXISTING SCREENS
import 'package:ai_navigator/screens/resume_intelligence.dart';
import 'package:ai_navigator/screens/career_path_screen.dart';

// NEW (DUMMY) SCREENS — create these files
import 'package:ai_navigator/screens/skill_gap_screen.dart';
import 'package:ai_navigator/screens/roadmap_screen.dart';
import 'package:ai_navigator/screens/progress_tracker_screen.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int hoverIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // LOGO
            Row(
              children: const [
                Icon(Icons.auto_awesome, color: Colors.blue),
                SizedBox(width: 10),
                Text(
                  "AI Career Navigator",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            // MENU
            Row(
              children: [
                navItem("Home", 0),
                navItem("Assessment", 1),
                navItem("Explore", 2),
                navItem("Roadmap", 3),
                featuresDropdown(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // NAV ITEM (no navigation added as you didn’t ask)
  Widget navItem(String text, int index) {
    bool isHover = hoverIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => hoverIndex = index),
      onExit: (_) => setState(() => hoverIndex = -1),
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isHover
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Text(
          text,
          style: TextStyle(
            color: isHover ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // FEATURES DROPDOWN
  Widget featuresDropdown() {
    bool isHover = hoverIndex == 4;

    return MouseRegion(
      onEnter: (_) => setState(() => hoverIndex = 4),
      onExit: (_) => setState(() => hoverIndex = -1),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 50),

        // ✅ ALL OPTIONS HANDLED HERE
        onSelected: (value) {
          Widget? page;

          switch (value) {
            case "Resume Intelligence":
              page = const ResumeIntelligence();
              break;

            case "Career Path Prediction":
              page = const CareerPathScreen();
              break;

            case "Skill Gap Analysis":
              page = const SkillGapScreen();
              break;

            case "AI Roadmap Generator":
              page = const RoadmapScreen();
              break;

            case "Project Recommendation":
              page = const ProjectRecommendationScreen();
              break;

            case "GitHub Analyzer":
              page = const GithubAnalyzerScreen();
              break;

            case "Resume Scoring":
              page = const ResumeScoringScreen();
              break;

            case "Interview Prep":
              page = const InterviewPrepScreen();
              break;

            case "Progress Tracker":
              page = const ProgressTrackerScreen();
              break;
          }

          if (page != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page!),
            );
          }
        },

        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isHover
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Text(
            "Features",
            style: TextStyle(
              color: isHover ? Colors.white : Colors.black87,
            ),
          ),
        ),

        itemBuilder: (context) => [
          PopupMenuItem(
            value: "Resume Intelligence",
            child: featureMenuItem(Icons.description, "Resume Intelligence"),
          ),
          PopupMenuItem(
            value: "Career Path Prediction",
            child: featureMenuItem(Icons.auto_graph, "Career Path Prediction"),
          ),
          PopupMenuItem(
            value: "Skill Gap Analysis",
            child: featureMenuItem(Icons.analytics, "Skill Gap Analysis"),
          ),
          PopupMenuItem(
            value: "AI Roadmap Generator",
            child: featureMenuItem(Icons.map, "AI Roadmap Generator"),
          ),
          PopupMenuItem(
            value: "Project Recommendation",
            child: featureMenuItem(Icons.lightbulb, "Project Recommendation"),
          ),
          PopupMenuItem(
            value: "GitHub Analyzer",
            child: featureMenuItem(Icons.code, "GitHub Analyzer"),
          ),
          PopupMenuItem(
            value: "Resume Scoring",
            child: featureMenuItem(Icons.score, "Resume Scoring"),
          ),
          PopupMenuItem(
            value: "Interview Prep",
            child: featureMenuItem(Icons.record_voice_over, "Interview Prep"),
          ),
          PopupMenuItem(
            value: "Progress Tracker",
            child: featureMenuItem(Icons.track_changes, "Progress Tracker"),
          ),
        ],
      ),
    );
  }

  // MENU ITEM UI
  Widget featureMenuItem(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.blue),
        ),
        const SizedBox(width: 12),
        Text(title),
      ],
    );
  }
}