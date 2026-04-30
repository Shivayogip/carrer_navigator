import 'package:flutter/material.dart';
import '../widgets/hero_section.dart';
import '../widgets/stats_section.dart';
import '../widgets/journey_section.dart';
import '../widgets/how_it_works.dart';
import '../widgets/navbar.dart';
import '../screens/ai_assistant_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: const [
                SizedBox(height: 80),

                // 🔥 UPDATED HERO SECTION
                HeroSection(),

                StatsSection(),
                JourneySection(),
                HowItWorks(),
              ],
            ),
          ),

          const Positioned(top: 0, left: 0, right: 0, child: Navbar()),
        ],
      ),

      // ✅ Floating AI Button (unchanged)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiAssistantScreen()),
          );
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text(
          "AI Assistant",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color.fromARGB(255, 194, 75, 215),
      ),
    );
  }
}
