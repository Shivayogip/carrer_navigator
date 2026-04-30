import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
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
import '../screens/profile_screen.dart';

Route fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int hoverIndex = -1;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final theme = Theme.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 800;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LOGO
                  GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      fadeRoute(const DashboardScreen()),
                      (route) => false,
                    ),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        children: [
                          Icon(
                            Icons.terminal,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "NAVIGATOR.AI",
                            style: theme.textTheme.titleLarge?.copyWith(
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT CONTENTS
                  if (isMobile)
                    _buildMobileMenu(context, authService)
                  else
                    _buildDesktopMenu(context, authService),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopMenu(BuildContext context, AuthService authService) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        navItem("HOME", 0, () {
          Navigator.pushAndRemoveUntil(
            context,
            fadeRoute(const DashboardScreen()),
            (route) => false,
          );
        }),
        featuresDropdown(),
        navItem("SUPPORT", 2, () {
          Navigator.push(context, fadeRoute(const ContactUsScreen()));
        }),
        const SizedBox(width: 20),

        if (authService.user != null) ...[
          IconButton(
            onPressed: () =>
                Navigator.push(context, fadeRoute(const ProfileScreen())),
            icon: Icon(
              Icons.account_circle_outlined,
              color: theme.colorScheme.secondary,
              size: 28,
            ),
            tooltip: "Profile",
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await authService.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  fadeRoute(const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.power_settings_new, size: 18),
            label: const Text("EXIT"),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileMenu(BuildContext context, AuthService authService) {
    final theme = Theme.of(context);
    return PopupMenuButton<int>(
      icon: Icon(Icons.menu_open, color: theme.colorScheme.primary),
      offset: const Offset(0, 50),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor),
      ),
      onSelected: (value) async {
        switch (value) {
          case 0:
            Navigator.pushAndRemoveUntil(
              context,
              fadeRoute(const DashboardScreen()),
              (route) => false,
            );
            break;
          case 1:
            Navigator.push(context, fadeRoute(const ContactUsScreen()));
            break;
          case 2:
            Navigator.push(context, fadeRoute(const ProfileScreen()));
            break;
          case 3:
            await authService.signOut();
            if (mounted)
              Navigator.pushAndRemoveUntil(
                context,
                fadeRoute(const LoginScreen()),
                (route) => false,
              );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0,
          child: Text("HOME", style: theme.textTheme.labelLarge),
        ),
        PopupMenuItem(
          value: 1,
          child: Text("SUPPORT", style: theme.textTheme.labelLarge),
        ),
        if (authService.user != null)
          PopupMenuItem(
            value: 2,
            child: Text("PROFILE", style: theme.textTheme.labelLarge),
          ),
        if (authService.user != null)
          PopupMenuItem(
            value: 3,
            child: Text(
              "EXIT",
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget navItem(String text, int index, VoidCallback onTap) {
    bool isHover = hoverIndex == index;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => hoverIndex = index),
      onExit: (_) => setState(() => hoverIndex = -1),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isHover ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isHover
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget featuresDropdown() {
    bool isHover = hoverIndex == 4;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => hoverIndex = 4),
      onExit: (_) => setState(() => hoverIndex = -1),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 50),
        color: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.dividerColor),
        ),
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
            Navigator.push(context, fadeRoute(page));
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isHover ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                "MODULES",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isHover
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isHover
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodyMedium?.color,
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          _buildPopupItem(
            "RESUME_INTEL",
            Icons.psychology,
            "Resume Intelligence",
          ),
          _buildPopupItem(
            "CAREER_PATH",
            Icons.auto_graph,
            "Career Path Prediction",
          ),
          _buildPopupItem(
            "SKILL_GAP",
            Icons.analytics_outlined,
            "Skill Gap Analysis",
          ),
          _buildPopupItem(
            "ROADMAP_GEN",
            Icons.map_outlined,
            "AI Roadmap Generator",
          ),
          _buildPopupItem(
            "PROJ_REC",
            Icons.lightbulb_outline,
            "Project Recommendation",
          ),
          _buildPopupItem("GIT_STATS", Icons.code, "GitHub Analyzer"),
          _buildPopupItem(
            "SCORE_CARD",
            Icons.assessment_outlined,
            "Resume Scoring",
          ),
          _buildPopupItem("INT_PREP", Icons.mic_none, "Interview Prep"),
          _buildPopupItem(
            "PROG_TRACK",
            Icons.track_changes,
            "Progress Tracker",
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String code,
    IconData icon,
    String value,
  ) {
    final theme = Theme.of(context);
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Text(code, style: theme.textTheme.labelLarge?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
