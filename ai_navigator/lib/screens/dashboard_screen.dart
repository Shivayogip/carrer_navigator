import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
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
import '../services/resume_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
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
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive) {
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
      _inactivityReminderEnabled =
          prefs.getBool('inactivity_reminder_enabled') ?? false;
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
        SnackBar(
          content: Text(
            value ? "Monitoring inactive state..." : "Monitoring disabled",
          ),
        ),
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
                ? "Daily sync protocols active."
                : "Sync protocols deactivated.",
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

          ResumeService().syncFromBackend(data);

          if (showResumePrompt &&
              !_promptShown &&
              (_userData != null &&
                  (_userData!['resume_text'] == null ||
                      _userData!['resume_text'].toString().isEmpty))) {
            _promptShown = true;
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) _showResumePrompt();
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
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
        _fetchUserData(showResumePrompt: false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Entry logged to database.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showResumePrompt() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor),
        ),
        title: Row(
          children: [
            Icon(Icons.terminal, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text("INITIALIZE_SYSTEM"),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "System requires resume data for profiling. Current status: DATA_MISSING.",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("SKIP"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, fadeRoute(const ResumeIntelligence()));
            },
            child: const Text("UPLOAD_DATA"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.user;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Navbar(),
            Expanded(
              child: Stack(
                children: [
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "SYSTEM.STATUS: ONLINE",
                                          style: theme.textTheme.labelLarge,
                                        ).animate().fadeIn().slideX(),
                                        Text(
                                          "Welcome, ${(user?.displayName != null && user!.displayName!.isNotEmpty) ? user.displayName : (user?.email ?? 'User')}",
                                          style: theme.textTheme.displayMedium,
                                        ).animate().fadeIn(delay: 200.ms).slideX(),
                                      ],
                                    ),
                                  ),
                                  if (user != null)
                                    _buildStreakChip(
                                      user,
                                      theme,
                                    ).animate().scale(delay: 400.ms),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // Achievements
                              if (user != null && user.badges.isNotEmpty) ...[
                                Text(
                                  "ACHIEVEMENTS.LOG",
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 90,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: user.badges.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 16),
                                    itemBuilder: (context, index) {
                                      return _buildBadgeItem(
                                        user.badges[index],
                                      );
                                    },
                                  ),
                                ).animate().fadeIn(delay: 500.ms),
                                const SizedBox(height: 32),
                              ],

                              // Score / Banner
                              if (_userData != null &&
                                  _userData!['score'] != null &&
                                  _userData!['score'] > 0)
                                _buildScoreCard(theme)
                                    .animate()
                                    .fadeIn(delay: 600.ms)
                                    .slideY(begin: 0.1)
                              else
                                _buildResumeBanner(
                                  theme,
                                ).animate().fadeIn(delay: 600.ms),

                              const SizedBox(height: 32),

                              // Terminal Logger
                              _buildTerminalLogger(
                                theme,
                              ).animate().fadeIn(delay: 700.ms),

                              const SizedBox(height: 32),

                              Text(
                                "MODULES.INIT",
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 16),

                              // Grid
                              GridView.extent(
                                maxCrossAxisExtent: 170,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.0,
                                children: [
                                  _buildActionCard(
                                    context,
                                    "RESUME_ANALYSIS",
                                    Icons.document_scanner,
                                    theme.colorScheme.secondary,
                                    const ResumeIntelligence(),
                                  ),
                                  _buildActionCard(
                                    context,
                                    "CAREER_PATH",
                                    Icons.auto_graph,
                                    Colors.cyan,
                                    const CareerPathScreen(),
                                  ),
                                  _buildActionCard(
                                    context,
                                    "SKILL_GAP",
                                    Icons.analytics_outlined,
                                    Colors.orange,
                                    const SkillGapScreen(),
                                  ),
                                  _buildActionCard(
                                    context,
                                    "ROADMAP_GEN",
                                    Icons.map_outlined,
                                    Colors.purple,
                                    const RoadmapScreen(),
                                  ),
                                  _buildActionCard(
                                    context,
                                    "PROJ_IDEAS",
                                    Icons.lightbulb_outline,
                                    Colors.amber,
                                    const ProjectRecommendationScreen(),
                                  ),
                                  _buildActionCard(
                                    context,
                                    "REPORT_CARD",
                                    Icons.assessment_outlined,
                                    Colors.teal,
                                    const ResumeScoringScreen(),
                                  ),
                                  _buildActionCard(
                                    context,
                                    "INT_PREP",
                                    Icons.mic_none,
                                    Colors.redAccent,
                                    const InterviewPrepScreen(),
                                  ),
                                  _buildActionCard(
                                    context,
                                    "PROGRESS",
                                    Icons.track_changes,
                                    Colors.indigo,
                                    const ProgressTrackerScreen(),
                                  ),
                                  _buildActionCard(
                                    context,
                                    "GIT_STATS",
                                    Icons.code,
                                    theme.colorScheme.primary,
                                    const GithubAnalyzerScreen(),
                                  ),
                                ].animate(interval: 50.ms).fadeIn().scale(),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                  if (_isChatOpen)
                    Positioned(
                      right: MediaQuery.of(context).size.width < 400 ? 16 : 24,
                      bottom: 100,
                      child: AiChatPanel(
                        onClose: () => setState(() => _isChatOpen = false),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _isChatOpen = !_isChatOpen),
        child: Icon(_isChatOpen ? Icons.close : Icons.psychology),
      ).animate().scale(delay: 1.seconds),
    );
  }

  Widget _buildStreakChip(dynamic user, ThemeData theme) {
    bool hasStreak = user.currentStreak > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: hasStreak ? Colors.orange.withOpacity(0.1) : theme.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasStreak ? Colors.orange : theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt,
            color: hasStreak ? Colors.orange : theme.disabledColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            "STREAK: ${user.currentStreak}",
            style: theme.textTheme.labelLarge?.copyWith(
              color: hasStreak ? Colors.orange : theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("RESUME_STRENGTH", style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(
                    "${_userData!['score']}%",
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontSize: 48,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 8,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalLogger(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                _dot(Colors.red),
                _dot(Colors.amber),
                _dot(Colors.green),
                const SizedBox(width: 12),
                Text(
                  "PROGRESS_LOGGER.SH",
                  style: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._todayTasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      "> ${task['task_desc']}",
                      style: GoogleFonts.jetBrainsMono(
                        color: theme.colorScheme.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "\$ ",
                      style: GoogleFonts.jetBrainsMono(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        focusNode: _taskFocusNode,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText: "log entry...",
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _addNewTask(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    margin: const EdgeInsets.only(right: 6),
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _buildResumeBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SYSTEM_INITIALIZATION_REQUIRED",
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            "Please upload resume data to unlock AI diagnostic tools.",
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                Navigator.push(context, fadeRoute(const ResumeIntelligence())),
            child: const Text("EXEC_UPLOAD"),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(String type) {
    final theme = Theme.of(context);
    IconData icon = Icons.terminal;
    Color color = theme.colorScheme.primary;

    if (type.contains('welcome')) icon = Icons.power;
    if (type.contains('consistent')) {
      icon = Icons.repeat;
      color = Colors.orange;
    }
    if (type.contains('explorer')) {
      icon = Icons.search;
      color = Colors.cyan;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          type.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 8,
            color: color,
          ),
        ),
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
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          decoration: BoxDecoration(
            color: _isHovering
                ? theme.colorScheme.surface
                : theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovering ? widget.color : theme.dividerColor,
            ),
            boxShadow: [
              if (_isHovering)
                BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 32,
                color: _isHovering ? widget.color : theme.disabledColor,
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 10,
                  color: _isHovering ? widget.color : theme.disabledColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
