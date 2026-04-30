import 'package:flutter/material.dart';
import '../services/file_upload_service.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  bool isUploaded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text(
            "Navigate Your AI Career",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          const Text(
            "Discover your perfect career path with AI guidance",
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔥 BUTTON WITH CONDITIONAL STYLE
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // 👉 SAME DEFAULT COLOR BEFORE UPLOAD
                  backgroundColor: isUploaded ? Colors.green : null,
                ),
                onPressed: () async {
                  await FileUploadService.pickAndStoreResume(context);

                  // 👉 CHANGE ONLY AFTER SUCCESS
                  setState(() {
                    isUploaded = true;
                  });
                },
                child: Text(isUploaded ? "Resume Uploaded ✅" : "Upload Resume"),
              ),

              const SizedBox(width: 10),

              OutlinedButton(
                onPressed: () {},
                child: const Text("Explore Careers"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
