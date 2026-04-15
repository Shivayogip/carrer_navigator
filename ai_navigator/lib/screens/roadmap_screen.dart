import 'package:flutter/material.dart';

class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Roadmap")),
      body: const Center(
        child: Text("Skill Gap Analysis Coming Soon"),
      ),
    );
  }
}