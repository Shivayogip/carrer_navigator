import 'package:flutter/material.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),

          child: Wrap(
            // ✅ responsive (important)
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              statCard(Icons.trending_up, "50+", "Career Paths"),
              statCard(Icons.workspace_premium, "200+", "Skills Tracked"),
              statCard(Icons.people, "10K+", "Users Guided"),
            ],
          ),
        ),
      ),
    );
  }

  Widget statCard(IconData icon, String number, String label) {
    return Container(
      width: 300, // ✅ bigger like design
      padding: const EdgeInsets.symmetric(vertical: 30),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.purple, size: 30), // ✅ icon added

          const SizedBox(height: 15),

          Text(
            number,
            style: const TextStyle(
              fontSize: 26, // 🔥 bigger number
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
