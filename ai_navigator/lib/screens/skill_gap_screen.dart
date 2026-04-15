import 'package:flutter/material.dart';
import '../services/resume_service.dart';
import '../data/career_data.dart';

class SkillGapScreen extends StatelessWidget {
  const SkillGapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String? role = ResumeService().selectedRole;
    List<String> userSkills = ResumeService().extractedSkills;

    if (role == null) {
      return const Scaffold(
        body: Center(child: Text("⚠️ Select a target role first")),
      );
    }

    final career =
        careers.firstWhere((c) => c.title == role);

    List<String> missingSkills = career.skills
        .where((skill) => !userSkills.contains(skill))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Skill Gap Analysis")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Target Role: $role",
                style:
                    const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            Wrap(
              spacing: 6,
              children: career.skills.map((skill) {
                bool hasSkill = userSkills.contains(skill);

                return Chip(
                  label: Text(skill),
                  backgroundColor:
                      hasSkill ? Colors.green[200] : Colors.red[200],
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            Text(
              "Missing Skills: ${missingSkills.join(", ")}",
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}