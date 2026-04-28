import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/resume_service.dart';
import '../services/api_config.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/navbar.dart';
import '../theme/app_theme.dart';

class InterviewPrepScreen extends StatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _speechStatus = "";
  double _level = 0.0;

  @override
  void initState() {
    super.initState();
    _startInterview();
  }

  Future<void> _startInterview() async {
    final role = ResumeService().selectedRole;
    final skills = ResumeService().extractedSkills;
    final company = ResumeService().selectedCompany;
    
    if (role == null) {
      setState(() {
        _messages.add({"role": "model", "text": "### SYSTEM_HALT: TARGET_ROLE_NULL\n\nPlease initialize target objectives in the Career Path module first."});
      });
      return;
    }

    final targetContext = company != null ? "$role at $company" : role;
    final prompt = "You are a strict but helpful technical interviewer. I am applying for the role of '$targetContext' and have the following skills: ${skills.join(', ')}. Please start the interview by asking me an opening technical question tailored to this role and company expectations. Do not provide the answer. Wait for my response.";
    
    await _sendMessageToAI(prompt, isSystemPrompt: true);
  }

  Future<void> _sendMessageToAI(String text, {bool isSystemPrompt = false}) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "message": text,
          "history": _messages.map((m) {
             return {
               "role": m["role"] == "user" ? "user" : "model",
               "parts": [m["text"]]
             };
          }).toList()
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({"role": "model", "text": data['response']});
        });
        _scrollToBottom();
      } else {
        setState(() {
          _messages.add({"role": "model", "text": "ERROR_PROTOCOL_FAILURE: Interviewer node offline."});
        });
      }
    } catch (e) {
       setState(() {
          _messages.add({"role": "model", "text": "CONNECTION_LOST: Diagnostic stream interrupted."});
       });
    } finally {
      setState(() => _isLoading = false);
    }
  }

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

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    
    final text = _controller.text;
    setState(() {
      _messages.add({"role": "user", "text": text});
      _controller.clear();
    });
    _scrollToBottom();
    _sendMessageToAI(text);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          setState(() {
            _speechStatus = val;
            if (val == 'done' || val == 'notListening') _isListening = false;
          });
        },
        onError: (val) {
          setState(() {
            _isListening = false;
            _speechStatus = "ERROR: ${val.errorMsg}";
          });
        },
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          _speechStatus = "LISTENING...";
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
              _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
            });
          },
          onSoundLevelChange: (level) => setState(() => _level = level),
          listenMode: stt.ListenMode.confirmation,
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speechStatus = "STOPPED";
      });
      _speech.stop();
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("INTERVIEW_PREP.EXE", style: theme.textTheme.labelLarge).animate().fadeIn().slideX(),
                Text("Technical Performance Simulator", style: theme.textTheme.displayMedium).animate().fadeIn(delay: 200.ms).slideX(),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(20),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primaryNeon.withOpacity(0.05) : AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isUser ? AppTheme.primaryNeon.withOpacity(0.3) : AppTheme.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser ? "USER_INPUT" : "INTERVIEWER_NODE",
                          style: TextStyle(
                            color: isUser ? AppTheme.primaryNeon : AppTheme.secondaryBlue,
                            fontFamily: 'JetBrainsMono',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        MarkdownBody(
                          data: _messages[index]["text"]!,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: isUser ? Colors.white : AppTheme.textMain, height: 1.5, fontSize: 14),
                            code: const TextStyle(backgroundColor: AppTheme.darkBg, color: AppTheme.secondaryBlue, fontFamily: 'JetBrainsMono'),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.05),
                );
              },
            ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        children: [
          if (_isListening) 
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                   Text(_speechStatus, style: const TextStyle(color: AppTheme.primaryNeon, fontSize: 10, fontFamily: 'JetBrainsMono', fontWeight: FontWeight.bold)),
                   const SizedBox(width: 16),
                   Expanded(
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(2),
                       child: LinearProgressIndicator(
                         value: (_level + 2) / 10,
                         backgroundColor: AppTheme.darkBg,
                         color: AppTheme.primaryNeon,
                         minHeight: 2,
                       ),
                     ),
                   ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "TRANSMIT RESPONSE...",
                    hintStyle: TextStyle(color: AppTheme.textDim, fontSize: 12),
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? AppTheme.primaryNeon : AppTheme.textDim),
                onPressed: _isLoading ? null : _listen,
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSend,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 20),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}