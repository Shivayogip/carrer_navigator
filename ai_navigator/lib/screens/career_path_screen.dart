import 'package:flutter/material.dart';
import '../services/resume_service.dart';
import '../data/career_data.dart';

class CareerPathScreen extends StatefulWidget {
  const CareerPathScreen({super.key});

  @override
  State<CareerPathScreen> createState() => _CareerPathScreenState();
}

class _CareerPathScreenState extends State<CareerPathScreen> {
  @override
  Widget build(BuildContext context) {
    List<String> userSkills = ResumeService().extractedSkills;

    List<Career> matchedCareers = careers.where((career) {
      int matchCount = career.skills
          .where((skill) => userSkills.contains(skill))
          .length;

      return matchCount >= 1;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Career Prediction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: userSkills.isEmpty
            ? const Center(
                child: Text("⚠️ Upload resume first"),
              )
            : ListView.builder(
                itemCount: matchedCareers.length,
                itemBuilder: (context, index) {
                  final career = matchedCareers[index];

                  // 🔥 USE GLOBAL VALUE
                  bool isSelected =
                      ResumeService().selectedRole == career.title;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            career.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text("Difficulty: ${career.difficulty}"),
                          Text("Salary: ${career.salary}"),
                          Text(
                              "Companies: ${career.companies.join(", ")}"),

                          const SizedBox(height: 10),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isSelected ? Colors.green : null,
                            ),
                            onPressed: () {
                              setState(() {
                                // ✅ STORE GLOBALLY
                                ResumeService()
                                    .setTargetRole(career.title);
                              });
                            },
                            child: Text(
                              isSelected
                                  ? "Target Role Set ✅"
                                  : "Select Role",
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}