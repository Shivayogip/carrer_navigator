import 'package:flutter/material.dart';

class JourneySection extends StatelessWidget {
  const JourneySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),

          child: Column(
            children: [
              const Text(
                "Your Journey Starts Here",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: const [
                  JourneyCard(
                    icon: Icons.track_changes,
                    title: "Skills Assessment",
                    description:
                        "Evaluate your current skills and identify areas for growth",
                    color: Colors.blue,
                  ),
                  JourneyCard(
                    icon: Icons.explore,
                    title: "Career Exploration",
                    description:
                        "Discover AI career paths that match your interests and skills",
                    color: Colors.purple,
                  ),
                  JourneyCard(
                    icon: Icons.map,
                    title: "Personalized Roadmap",
                    description:
                        "Get a tailored learning path to reach your career goals",
                    color: Colors.deepOrange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JourneyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const JourneyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 Icon box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(height: 20),

          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            description,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "Get Started →",
            style: TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}