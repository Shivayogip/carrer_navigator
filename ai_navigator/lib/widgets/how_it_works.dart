import 'package:flutter/material.dart';

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),

          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),

            child: Column(
              children: [
                const Text(
                  "How It Works",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // 🔥 Horizontal line
                        Positioned(
                          top: 25,
                          left: 40,
                          right: 40,
                          child: Container(
                            height: 2,
                            color: Colors.purple.withOpacity(0.3),
                          ),
                        ),

                        // 🔥 Steps
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            StepItem(number: "1", text: "Take Assessment"),
                            StepItem(number: "2", text: "Explore Paths"),
                            StepItem(number: "3", text: "Get Roadmap"),
                            StepItem(number: "4", text: "Start Learning"),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StepItem extends StatelessWidget {
  final String number;
  final String text;

  const StepItem({super.key, required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔥 Gradient Circle
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),

        const SizedBox(height: 15),

        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}