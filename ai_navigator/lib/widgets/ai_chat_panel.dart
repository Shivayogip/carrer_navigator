import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';

class AiChatPanel extends StatefulWidget {
  final VoidCallback onClose;
  const AiChatPanel({super.key, required this.onClose});

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [
    {"role": "ai", "text": "SESSION_INITIALIZED: I am Mark, your career diagnostic node. How can I assist with your trajectory today?"}
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
          .where((m) => !m["text"]!.startsWith("SESSION_INITIALIZED"))
          .map((m) => {
            "role": m["role"] == "user" ? "user" : "model",
            "parts": [{"text": m["text"]}]
          }).toList();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "message": text,
          "history": historyList
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            messages.add({"role": "ai", "text": data["response"]});
          });
        }
      } else {
        if (mounted) {
          setState(() {
            messages.add({"role": "ai", "text": "ERROR: PROTOCOL_INTERRUPTED. Please re-transmit."});
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.add({"role": "ai", "text": "ERROR: CONNECTION_FAILURE. Verify backend status."});
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 500,
      decoration: BoxDecoration(
        color: AppTheme.darkBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: AppTheme.primaryNeon, size: 20),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("MARK_AI.EXE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'JetBrainsMono')),
                    Text("STATUS: ONLINE", style: TextStyle(color: AppTheme.primaryNeon, fontSize: 10, fontFamily: 'JetBrainsMono')),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textDim, size: 20),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: SizedBox(width: 20, height: 2, child: LinearProgressIndicator(color: AppTheme.primaryNeon, backgroundColor: AppTheme.darkSurface))),
                  );
                }
                
                final msg = messages[index];
                final isAi = msg["role"] == "ai";
                
                return Align(
                  alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isAi ? AppTheme.darkSurface : AppTheme.primaryNeon.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isAi ? AppTheme.borderSubtle : AppTheme.primaryNeon.withOpacity(0.3)),
                    ),
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAi ? "AI_NODE" : "USER_INPUT",
                          style: TextStyle(color: isAi ? AppTheme.secondaryBlue : AppTheme.primaryNeon, fontSize: 10, fontFamily: 'JetBrainsMono', fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          msg["text"]!,
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),
                );
              },
            ),
          ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: "TRANSMIT MESSAGE...",
                      hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 11),
                      filled: true,
                      fillColor: AppTheme.darkBg,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: ElevatedButton(
                    onPressed: sendMessage,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Icon(Icons.send_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

