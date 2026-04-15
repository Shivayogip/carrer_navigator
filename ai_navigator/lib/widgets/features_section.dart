import 'package:flutter/material.dart';
import 'feature_card.dart';

class FeaturesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Your Journey Starts Here",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

        SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FeatureCard(
              title: "Skills Assessment",
              description: "Evaluate your skills",
            ),
            FeatureCard(
              title: "Career Exploration",
              description: "Explore career paths",
            ),
            FeatureCard(
              title: "Personalized Roadmap",
              description: "Get learning plan",
            ),
          ],
        )
      ],
    );
  }
}