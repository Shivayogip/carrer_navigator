import 'package:flutter/material.dart';
import '../widgets/navbar.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Navbar(),
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.mail_outline, size: 80, color: Color(0xFF6366F1)),
                const SizedBox(height: 24),
                const Text("Connect With the Developers", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 16),
                const Text("Have feedback or need assistance? We'd love to hear from you!", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 40),
                
                TextField(
                  decoration: InputDecoration(
                    labelText: "Your Email",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Your Message",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Message Sent Successfully! We will get back to you soon.")));
                    },
                    child: const Text("Send Message", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        )
      )
    );
  }
}
