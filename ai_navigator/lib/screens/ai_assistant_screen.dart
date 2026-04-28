import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/navbar.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [
    {"role": "ai", "text": "I am Mark, your AI Career Guide. System initialization complete. How can I assist your career optimization today?"}
  ];
  bool _isLoading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    String text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      _isLoading = true;
    });
    controller.clear();
    _scrollToBottom();

    try {
      final historyList = messages
          .sublist(0, messages.length - 1)
          .where((m) => !m["text"]!.contains("I am Mark"))
          .map((m) => {
                "role": m["role"] == "user" ? "user" : "model",
                "parts": [
                  {"text": m["text"]}
                ]
              })
          .toList();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"message": text, "history": historyList}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages.add({"role": "ai", "text": data["response"]});
        });
      } else {
        String errorMsg = "ERROR: Connection to AI protocol failed.";
        try {
          final data = jsonDecode(response.body);
          if (data["error"] != null) errorMsg = "ERROR: ${data["error"]}";
        } catch (_) {}
        setState(() {
          messages.add({"role": "ai", "text": errorMsg});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"role": "ai", "text": "CRITICAL_ERROR: Network connection failed. Check backend status."});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI_ASSISTANT.SH",
                        style: theme.textTheme.labelLarge,
                      ).animate().fadeIn().slideX(),
                      Text(
                        "Interactive Career Logic",
                        style: theme.textTheme.displayMedium,
                      ).animate().fadeIn(delay: 200.ms).slideX(),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryNeon),
                          ),
                        ).animate().fadeIn();
                      }

                      final msg = messages[index];
                      bool isUser = msg["role"] == "user";

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(20),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUser ? AppTheme.secondaryBlue.withOpacity(0.05) : AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isUser ? AppTheme.secondaryBlue.withOpacity(0.3) : AppTheme.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUser ? Icons.person_outline : Icons.psychology_outlined,
                                    size: 14,
                                    color: isUser ? AppTheme.secondaryBlue : AppTheme.primaryNeon,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isUser ? "USER_LOG" : "MARK_AI_PROMPT",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontSize: 10,
                                      color: isUser ? AppTheme.secondaryBlue : AppTheme.primaryNeon,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                msg["text"]!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.6,
                                  color: isUser ? Colors.white : AppTheme.textMain,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface.withOpacity(0.8),
                    border: const Border(top: BorderSide(color: AppTheme.borderSubtle)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: "Enter query or command...",
                              hintStyle: TextStyle(color: AppTheme.textDim.withOpacity(0.3)),
                              filled: true,
                              fillColor: AppTheme.darkBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(color: AppTheme.borderSubtle),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            onSubmitted: (_) => sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNeon.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.5)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: AppTheme.primaryNeon, size: 24),
                            onPressed: sendMessage,
                          ),
                        ).animate().scale(),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}