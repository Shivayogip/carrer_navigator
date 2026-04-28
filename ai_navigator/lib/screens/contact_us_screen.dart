import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/navbar.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.user != null) {
        _emailController.text = auth.user!.email;
      }
    });
  }

  Future<void> _sendMessage() async {
    final email = _emailController.text.trim();
    final message = _messageController.text.trim();

    if (email.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/contact'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transmission successful. We will respond via the secure channel.")),
          );
          _messageController.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transmission failure. Check terminal logs.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Network error. Secure connection could not be established.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Column(
        children: [
          const Navbar(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header matching dashboard style
                      Text(
                        "CONTACT_CHANNEL.INF",
                        style: theme.textTheme.labelLarge,
                      ).animate().fadeIn().slideX(),
                      Text(
                        "Technical Feedback & Support",
                        style: theme.textTheme.displayMedium,
                      ).animate().fadeIn(delay: 200.ms).slideX(),
                      
                      const SizedBox(height: 40),

                      Container(
                        width: 550,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderSubtle, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.terminal, size: 80, color: AppTheme.primaryNeon),
                            const SizedBox(height: 32),
                            Text(
                              "INITIATE_COMMUNICATION",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Submit technical feedback or request system assistance.",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 40),
                            
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: "SENDER_EMAIL",
                                prefixIcon: Icon(Icons.alternate_email, size: 18),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _messageController,
                              maxLines: 5,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: "ENCRYPTED_MESSAGE",
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _sendMessage,
                                child: _isLoading 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text("EXECUTE_SEND", style: TextStyle(letterSpacing: 2)),
                              ),
                            )
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


