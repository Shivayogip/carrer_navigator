import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import '../services/api_config.dart';
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
import '../widgets/ai_chat_panel.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  bool _isChatOpen = false;
  bool _notificationsEnabled = false;
  bool _inactivityReminderEnabled = false;
  bool _promptShown = false;
  final TextEditingController _taskController = TextEditingController();
  List<dynamic> _todayTasks = [];
  bool _isTasksLoading = false;
  final FocusNode _taskFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserData();
    _loadNotificationPreference();
    _fetchTodayTasks();
    
    // Cancel potential inactivity reminders on load (Mobile only)
    if (!kIsWeb) {
      NotificationService().cancelInactivityReminder();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taskController.dispose();
    _taskFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        if (_inactivityReminderEnabled) {
          NotificationService().scheduleInactivityReminder();
        }
      } else if (state == AppLifecycleState.resumed) {
        NotificationService().cancelInactivityReminder();
      }
    }
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('daily_reminder_enabled') ?? false;
      _inactivityReminderEnabled = prefs.getBool('inactivity_reminder_enabled') ?? false;
    });
  }

  Future<void> _toggleInactivityReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await NotificationService().requestPermissions();
    } else {
      await NotificationService().cancelInactivityReminder();
    }
    
    await prefs.setBool('inactivity_reminder_enabled', value);
    setState(() {
      _inactivityReminderEnabled = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? "10h Inactivity reminder enabled" : "Inactivity reminders disabled")),
      );
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await NotificationService().requestPermissions();
      await NotificationService().scheduleDailyReminder();
    } else {
      await NotificationService().cancelAll();
    }

    await prefs.setBool('daily_reminder_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? "Daily reminders enabled for 10:00 AM"
                : "Reminders disabled",
          ),
        ),
      );
    }
  }

  Future<void> _fetchUserData({bool showResumePrompt = true}) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (auth.token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/data'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted && data != null) {
          setState(() {
            _userData = data;
            _isLoading = false;
          });

          // Check if resume is missing and we haven't shown the prompt this session
          if (showResumePrompt && !_promptShown &&
              (_userData != null && (_userData!['resume_text'] == null ||
                  _userData!['resume_text'].toString().isEmpty))) {
            _promptShown = true;
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) _showResumePrompt();
            });
          }
        }
      } else {
        debugPrint("Dashboard: Fetch data failed with status ${response.statusCode}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Dashboard: Error fetching data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTodayTasks() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    setState(() => _isTasksLoading = true);
    final tasks = await auth.fetchTodayTasks();
    if (mounted) {
      setState(() {
        _todayTasks = tasks;
        _isTasksLoading = false;
      });
    }
  }

  Future<void> _addNewTask() async {
    if (_taskController.text.trim().isEmpty) return;
    
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final success = await auth.logDailyTask(_taskController.text.trim());
      
      if (success && mounted) {
        _taskController.clear();
        _fetchTodayTasks();
        _fetchUserData(showResumePrompt: false); // Refresh streak without re-prompting
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Progress logged! 🔥")),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to log task. Please try again later."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showResumePrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.rocket_launch, color: Color(0xFF6366F1)),
            SizedBox(width: 12),
            Text("Ready to Start?"),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome to AI Career Navigator! To get personalized career paths, skill gap analysis, and interview prep, please upload your resume.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              "It only takes a minute to get your first scoring report.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, fadeRoute(const ResumeIntelligence()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Upload Now"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const Navbar(),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Welcome back, ${(user?.displayName != null && user!.displayName!.isNotEmpty) ? user.displayName : (user?.email ?? 'User')}!",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (user != null)
                            GestureDetector(
                              onTap: () => _taskFocusNode.requestFocus(),
                              child: Tooltip(
                                message: "Click to log today's progress",
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: user.currentStreak > 0 ? Colors.orange[50] : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: user.currentStreak > 0 ? Colors.orange[200]! : Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.local_fire_department,
                                          color: user.currentStreak > 0 ? Colors.orange : Colors.grey, size: 24),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.currentStreak > 0 
                                          ? "${user.currentStreak} Day Streak"
                                          : "Start a Streak!",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: user.currentStreak > 0 ? Colors.orange : Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Achievements Room
                      if (user != null && user.badges.isNotEmpty) ...[
                        const Text(
                          "My Achievements",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: user.badges.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final badge = user.badges[index];
                              return _buildBadgeItem(badge);
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Stats Card or Resume Banner
                      if (_userData != null &&
                          _userData!['score'] != null &&
                          _userData!['score'] > 0) ...[
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black12,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Current Resume Score",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          "${_userData!['score']}%",
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6366F1),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.trending_up,
                                      size: 64,
                                      color: Colors.green.withOpacity(0.2),
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),
                                if (_userData!['skills'] != null &&
                                    _userData!['skills']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const Text(
                                    "Detected Key Skills",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _buildSkillsList(
                                      _userData!['skills'].toString(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        _buildResumeBanner(),
                      ],
                      const SizedBox(height: 32),

                      // Daily Progress Checklist
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Daily Progress Logger",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text(
                                  "Log your achievements to maintain your streak!",
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 14)),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _taskController,
                                      focusNode: _taskFocusNode,
                                      decoration: InputDecoration(
                                        hintText: "What did you learn today?",
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide.none),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                      ),
                                      onSubmitted: (_) => _addNewTask(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton.filled(
                                    onPressed: _addNewTask,
                                    icon: const Icon(Icons.add),
                                    style: IconButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF6366F1),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                  )
                                ],
                              ),
                              if (_todayTasks.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const Text("Today's Accomplishments",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54)),
                                const SizedBox(height: 12),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _todayTasks.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final task = _todayTasks[index];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: Colors.green[50]
                                              ?.withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.green[100]!)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle,
                                              color: Colors.green, size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child: Text(
                                                  task['task_desc'] ?? '',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500))),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Notification Settings
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: Colors.white,
                        child: Column(
                          children: [
                            if (!kIsWeb) ...[
                              SwitchListTile(
                                title: const Text("Daily Skill Reminder",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                subtitle: const Text(
                                    "Notification at 10:00 AM to stay on track."),
                                secondary: Icon(Icons.notifications_active,
                                    color: _notificationsEnabled
                                        ? Colors.indigo
                                        : Colors.grey),
                                value: _notificationsEnabled,
                                onChanged: _toggleNotifications,
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                title: const Text("10h Inactivity Reminder",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                subtitle: const Text(
                                    "Get a ping if you skip the app for 10 hours."),
                                secondary: Icon(Icons.timer,
                                    color: _inactivityReminderEnabled
                                        ? Colors.indigo
                                        : Colors.grey),
                                value: _inactivityReminderEnabled,
                                onChanged: _toggleInactivityReminder,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Text(
                        "AI Toolkit",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
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
                          _buildActionCard(
                            context,
                            "Resume Analysis",
                            Icons.document_scanner,
                            Colors.blue,
                            const ResumeIntelligence(),
                          ),
                          _buildActionCard(
                            context,
                            "Career Path",
                            Icons.auto_graph,
                            Colors.green,
                            const CareerPathScreen(),
                          ),
                          _buildActionCard(
                            context,
                            "Skill Gap",
                            Icons.analytics,
                            Colors.orange,
                            const SkillGapScreen(),
                          ),
                          _buildActionCard(
                            context,
                            "Roadmap",
                            Icons.map,
                            Colors.indigo,
                            const RoadmapScreen(),
                          ),
                          _buildActionCard(
                            context,
                            "Projects",
                            Icons.lightbulb,
                            Colors.amber,
                            const ProjectRecommendationScreen(),
                          ),
                          _buildActionCard(
                            context,
                            "Report Card",
                            Icons.score,
                            Colors.teal,
                            const ResumeScoringScreen(),
                          ),
                          _buildActionCard(
                            context,
                            "Interview Prep",
                            Icons.mic,
                            Colors.red,
                            const InterviewPrepScreen(),
                          ),
                          _buildActionCard(
                            context,
                            "Progress",
                            Icons.track_changes,
                            Colors.cyan,
                            const ProgressTrackerScreen(),
                          ),
                          _buildActionCard(
                            context,
                            "GitHub Stats",
                            Icons.code,
                            Colors.black87,
                            const GithubAnalyzerScreen(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
          if (_isChatOpen)
            Positioned(
              right: 24,
              bottom: 100,
              child: AiChatPanel(
                onClose: () => setState(() => _isChatOpen = false),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _isChatOpen = !_isChatOpen),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 4,
        child: Icon(
          _isChatOpen ? Icons.close : Icons.chat_bubble,
          color: Colors.white,
        ),
      ),
    );
  }

  List<Widget> _buildSkillsList(String skillsStr) {
    if (skillsStr.length > 2 && skillsStr.startsWith('[')) {
      try {
        final List<dynamic> list = jsonDecode(skillsStr);
        return list
            .map(
              (s) => Chip(
                label: Text(s.toString(), style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.blue[50],
                side: BorderSide(color: Colors.blue[100]!),
              ),
            )
            .toList();
      } catch (_) {}
    }
    return skillsStr
        .split(',')
        .map(
          (s) => Chip(
            label: Text(s.trim(), style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.blue[50],
            side: BorderSide(color: Colors.blue[100]!),
          ),
        )
        .toList();
  }

  Widget _buildResumeBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Unlock Your AI Career Roadmap",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Upload your resume to get instant scoring, skill gap analysis, and personalized project recommendations.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    fadeRoute(const ResumeIntelligence()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Get Started Now",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (!kIsWeb)
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Icon(Icons.rocket_launch, size: 80, color: Colors.white24),
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(String type) {
    IconData icon;
    String label;
    Color color;

    switch (type) {
      case 'welcome':
        icon = Icons.stars;
        label = "Welcome";
        color = Colors.blue;
        break;
      case 'consistent':
        icon = Icons.verified;
        label = "Consistent";
        color = Colors.orange;
        break;
      case 'explorer':
        icon = Icons.explore;
        label = "Explorer";
        color = Colors.purple;
        break;
      case 'achiever':
        icon = Icons.emoji_events;
        label = "Achiever";
        color = Colors.amber;
        break;
      default:
        icon = Icons.military_tech;
        label = "Achievement";
        color = Colors.grey;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget screen,
  ) {
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

  const _AnimatedToolCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

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
          transform: Matrix4.translationValues(0, _isHovering ? -6 : 0, 0)
            ..scale(_isHovering ? 1.02 : 1.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (_isHovering)
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              else
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
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
                  child: Icon(
                    widget.icon,
                    size: _isHovering ? 36 : 32,
                    color: widget.color,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isHovering ? widget.color : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
