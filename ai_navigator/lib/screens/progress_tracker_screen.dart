import 'package:flutter/material.dart';
import '../services/resume_service.dart';
import '../widgets/navbar.dart';

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
    if (_missingSkills.isEmpty) {
      return Scaffold(
        appBar: const Navbar(),
        body: const Center(child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text("⚠️ You have no missing skills recorded. Please visit Skill Gap Analysis to generate your dynamic checklist.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
        )),
      );
    }

    int completed = _skillProgress.values.where((v) => v).length;
    double progressPercent = completed / _missingSkills.length;

    return Scaffold(
      appBar: const Navbar(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("Mastering Your Skill Gap", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text("Goal: ${ResumeService().selectedRole} ${ResumeService().selectedCompany != null ? 'at ${ResumeService().selectedCompany}' : ''}", style: const TextStyle(fontSize: 18, color: Colors.indigo)),
            const SizedBox(height: 32),
            LinearProgressIndicator(
              value: progressPercent,
              minHeight: 20,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            Text("${(progressPercent * 100).toInt()}% towards your goal", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: _missingSkills.length,
                itemBuilder: (context, index) {
                  final skill = _missingSkills[index];
                  final isChecked = _skillProgress[skill] ?? false;
                  return Card(
                    color: isChecked ? Colors.green[50] : Colors.white,
                    child: CheckboxListTile(
                      title: Text(skill, style: TextStyle(
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? Colors.grey : Colors.black
                      )),
                      value: isChecked,
                      onChanged: (bool? val) {
                        setState(() {
                          _skillProgress[skill] = val ?? false;
                        });
                      },
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}