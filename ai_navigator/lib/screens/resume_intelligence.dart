import 'dart:io';

import 'package:file_picker/file_picker.dart';
  import 'package:flutter/material.dart';
  import '../services/resume_service.dart';

class ResumeIntelligence extends StatefulWidget {
const ResumeIntelligence({super.key});

@override
State<ResumeIntelligence> createState() => _ResumeIntelligenceState();
}

class _ResumeIntelligenceState extends State<ResumeIntelligence> {
PlatformFile? selectedFile;
Map<String, dynamic>? result;
bool isLoading = false;

// PICK FILE
Future<void> pickFile() async {
final res = await FilePicker.platform.pickFiles(
withData: true, // 🔥 IMPORTANT FOR WEB
);


if (res != null) {
  setState(() {
    selectedFile = res.files.single;
  });
}


}

// UPLOAD FILE
Future<void> uploadFile() async {
print("Analyze clicked");


if (selectedFile == null) {
  print("No file selected");
  return;
}

setState(() {
  isLoading = true;
});

try {
  ResumeService().setResume(selectedFile!.toString());
  // Note: You need to update the result state based on how setResume handles the response
} catch (e) {
  print("ERROR: $e");
}

setState(() {
  isLoading = false;
});


}

Widget buildList(String title, List items) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title,
style: const TextStyle(
fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 5),
...items.map((e) => Text("• $e")).toList(),
const SizedBox(height: 15),
],
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text("Resume Intelligence")),
body: Padding(
padding: const EdgeInsets.all(16),
child: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
ElevatedButton(
onPressed: pickFile,
child: const Text("Select Resume"),
),

          const SizedBox(height: 10),

          if (selectedFile != null)
            Text(
              "✅ Resume Selected: ${selectedFile!.name}",
              style: const TextStyle(color: Colors.green),
            ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: uploadFile,
            child: const Text("Analyze Resume"),
          ),

          const SizedBox(height: 20),

          if (isLoading) const CircularProgressIndicator(),

          const SizedBox(height: 20),

          if (result != null) ...[
            buildList("Skills", result!["skills"]),
            buildList("Projects", result!["projects"]),
            buildList("Experience", result!["experience"]),
            buildList("Education", result!["education"]),
            buildList("Tools", result!["tools"]),
            buildList(
                "Missing Skills",
                result!["missing_skills_for_roles"]),
            buildList("Suggestions", result!["suggestions"]),
          ]
        ],
      ),
    ),
  ),
);


}
}
