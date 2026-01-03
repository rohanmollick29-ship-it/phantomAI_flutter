import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PhantomApp());
}

// ================= APP ROOT =================

class PhantomApp extends StatelessWidget {
  const PhantomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PHANTOM AI Tutor",
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

// ================= MESSAGE MODEL =================

class Message {
  final String text;
  final bool isUser;
  final bool isTyping;

  Message({
    required this.text,
    required this.isUser,
    this.isTyping = false,
  });
}

// ================= CHAT SCREEN =================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<Message> messages = [];

  String subject = "Math";

  static const String geminiApiKey =
      "PASTE_GEMINI_API_KEY_HERE"; // 🔴 PUT YOUR KEY HERE

  final List<String> subjects = [
    "Math",
    "Physics",
    "Chemistry",
    "Computer Science",
    "English",
  ];

  Future<String> askGemini(String question) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$geminiApiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "You are a helpful tutor for $subject.\n\nUser question:\n$question"
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      return "Error: ${response.statusCode}";
    }
  }

  void sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final userText = controller.text.trim();
    controller.clear();

    setState(() {
      messages.add(Message(text: userText, isUser: true));
      messages.add(Message(text: "", isUser: false, isTyping: true));
    });

    scrollDown();

    final reply = await askGemini(userText);

    setState(() {
      messages.removeLast();
      messages.add(Message(text: reply, isUser: false));
    });

    scrollDown();
  }

  void scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget messageBubble(Message m) {
    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: m.isUser ? Colors.deepPurple : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: m.isTyping
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                m.text,
                style: TextStyle(
                  color: m.isUser ? Colors.white : Colors.black,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PHANTOM AI Tutor"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: DropdownButtonFormField<String>(
              value: subject,
              items: subjects
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => subject = v!),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (_, i) => messageBubble(messages[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Ask a question...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
