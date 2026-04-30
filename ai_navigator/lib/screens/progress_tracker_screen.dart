import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/resume_service.dart';
import '../widgets/navbar.dart';
import '../theme/app_theme.dart';

class ProgressTrackerScreen extends StatefulWidget {
  const ProgressTrackerScreen({super.key});

  @override
  State<ProgressTrackerScreen> createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  late List<String> _missingSkills;
  final Map<String, bool> _skillProgress = {};

  @override
  void initState() {
    super.initState();
    _missingSkills = ResumeService().dynamicMissingSkills;
    for (var skill in _missingSkills) {
      _skillProgress[skill] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            const Navbar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TRAINING_TRACKER.EXE",
                      style: theme.textTheme.labelLarge,
                    ).animate().fadeIn().slideX(),
                    Text(
                      "Skill Acquisition Log",
                      style: theme.textTheme.displayMedium,
                    ).animate().fadeIn(delay: 200.ms).slideX(),
                    const SizedBox(height: 32),

                    if (_missingSkills.isEmpty)
                      _buildEmptyState()
                    else
                      _buildTrackerView(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 100),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: const Column(
          children: [
            Icon(Icons.terminal_outlined, size: 48, color: AppTheme.textDim),
            const SizedBox(height: 24),
            Text(
              "SIGNAL_LOST: ZERO_DELTA_DETECTED\n\nPlease visit Skill Gap Analysis to identify technical nodes for acquisition.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textDim,
                fontFamily: 'JetBrainsMono',
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale();
  }

  Widget _buildTrackerView(ThemeData theme) {
    int completed = _skillProgress.values.where((v) => v).length;
    double progressPercent = completed / _missingSkills.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
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
                  const Icon(Icons.bolt, color: AppTheme.primaryNeon, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "CURRENT_TARGET: ${ResumeService().selectedRole?.toUpperCase()}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 8,
                  backgroundColor: AppTheme.darkBg,
                  color: AppTheme.primaryNeon,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PROGRESS: ${(progressPercent * 100).toInt()}%",
                    style: const TextStyle(
                      color: AppTheme.textDim,
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "$completed/${_missingSkills.length} NODES_SYCHRONIZED",
                    style: const TextStyle(
                      color: AppTheme.primaryNeon,
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 32),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _missingSkills.length,
          itemBuilder: (context, index) {
            final skill = _missingSkills[index];
            final isChecked = _skillProgress[skill] ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isChecked
                    ? AppTheme.primaryNeon.withOpacity(0.05)
                    : AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isChecked
                      ? AppTheme.primaryNeon.withOpacity(0.3)
                      : AppTheme.borderSubtle,
                ),
              ),
              child: CheckboxListTile(
                title: Text(
                  skill.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                    color: isChecked ? AppTheme.primaryNeon : Colors.white,
                  ),
                ),
                subtitle: Text(
                  isChecked ? "NODE_ACQUIRED" : "AWAITING_MASTERY",
                  style: TextStyle(
                    color: isChecked
                        ? AppTheme.primaryNeon.withOpacity(0.5)
                        : AppTheme.textDim,
                    fontSize: 10,
                  ),
                ),
                value: isChecked,
                activeColor: AppTheme.primaryNeon,
                checkColor: Colors.black,
                onChanged: (bool? val) {
                  setState(() {
                    _skillProgress[skill] = val ?? false;
                  });
                },
              ),
            ).animate().fadeIn(delay: (500 + (index * 50)).ms).slideX();
          },
        ),
      ],
    );
  }
}
