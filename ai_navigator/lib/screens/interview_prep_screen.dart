import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/resume_service.dart';

class InterviewPrepScreen extends StatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

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
        _messages.add({"role": "model", "text": "⚠️ No target role selected. Please choose a target role in Career Path Prediction first!"});
      });
      return;
    }

    final targetContext = company != null ? "$role at $company" : role;
    final prompt = "You are a strict but helpful technical interviewer. I am applying for the role of '$targetContext' and have the following skills: ${skills.join(', ')}. Please start the interview by asking me an opening technical question tailored to this role and company expectations. Do not provide the answer. Wait for my response.";
    
    await _sendMessageToAI(prompt, isSystemPrompt: true);
  }

  Future<void> _sendMessageToAI(String text, {bool isSystemPrompt = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/ai/chat'),
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
      } else {
        setState(() {
          _messages.add({"role": "model", "text": "Interviewer is offline. Please try again."});
        });
      }
    } catch (e) {
       setState(() {
          _messages.add({"role": "model", "text": "Error connecting to interviewer."});
       });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    
    final text = _controller.text;
    setState(() {
      _messages.add({"role": "user", "text": text});
      _controller.clear();
    });
    
    _sendMessageToAI(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Interview Simulator"), backgroundColor: Colors.redAccent, foregroundColor: Colors.white,),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: MarkdownBody(data: _messages[index]["text"]!),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type your answer...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _isLoading ? null : _handleSend,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}