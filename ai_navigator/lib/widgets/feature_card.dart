import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String description;

  const FeatureCard({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.grey.shade300)],
      ),
      child: Column(
        children: [
          Icon(Icons.star, size: 40, color: Colors.purple),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(description),
        ],
      ),
    );
  }
}