import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../chatbot/voice_recorder.dart';
import '../chatbot/agent_service.dart';
import '../../models/chat_message.dart';
import '../models/agent_response.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {

  final VoiceRecorder _recorder = VoiceRecorder();
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _controller = TextEditingController();

  bool isRecording = false;
  String? audioPath;

  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();

    messages.add(ChatMessage(
      role: "ai",
      type: "text",
      text: "Hello! I'm your AutoMind AI assistant 🚗",
    ));
  }

  // ---------------- VOICE RECORD ----------------
  Future<void> _toggleRecord() async {

    if (!isRecording) {
      await _recorder.start();
      setState(() => isRecording = true);

    } else {

      final stopFuture = _recorder.stop();
      setState(() => isRecording = false);

      _addUserAudio("processing");

      audioPath = await stopFuture;

      if (audioPath != null) {
        _processAgent();
      }
    }
  }

  void _addUserAudio(String path) {
    setState(() {
      messages.add(ChatMessage(role: "user", type: "audio", audio: path));
      messages.add(ChatMessage(role: "status", type: "text", text: "🔍 Diagnosing vehicle condition..."));
    });
  }

  // ---------------- AGENT PROCESS ----------------
  Future<void> _processAgent() async {

    try {

      if (audioPath != null) {
        await AgentService.sendAudio(audioPath!);
        audioPath = null;
      }

      final AgentResponse result = await AgentService.getResult();

      if (!mounted) return;

      setState(() => messages.removeLast());

      setState(() {
        messages.add(ChatMessage(
          role: "ai",
          type: "text",
          text: result.aiResponseText,
        ));
      });

      if (result.audioUrl != null) {
        final url = AgentService.buildAudioUrl(result.audioUrl!);
        final localPath = await _downloadAudio(url);

        setState(() {
          messages.add(ChatMessage(role: "ai", type: "audio", audio: localPath));
        });

        await _player.play(DeviceFileSource(localPath));
      }

    } catch (_) {

      if (!mounted) return;

      setState(() {
        messages.removeLast();
        messages.add(ChatMessage(
          role: "ai",
          type: "text",
          text: "⚠️ Assistant timeout. Please try again.",
        ));
      });
    }
  }

  // ---------------- DOWNLOAD AUDIO ----------------
  Future<String> _downloadAudio(String url) async {
    final dir = await Directory.systemTemp.createTemp();
    final filePath = "${dir.path}/ai_voice.wav";

    final response = await http.get(Uri.parse(url));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }

  // ---------------- CHAT BUBBLE ----------------
  Widget bubble(ChatMessage msg) {

    bool isUser = msg.role == "user";

    Color bubbleColor = msg.role == "status"
        ? Colors.orange.shade100
        : isUser
        ? const Color(0xFF2563EB)
        : Colors.white;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),

        child: msg.type == "audio"
            ? GestureDetector(
          onTap: () async {
            if (msg.audio != null) {
              await _player.play(DeviceFileSource(msg.audio!));
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.play_circle_fill, size: 28),
              SizedBox(width: 8),
              Text("Voice Message"),
            ],
          ),
        )
            : Text(
          msg.text ?? "",
          style: TextStyle(
            fontSize: 15,
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ---------------- INPUT AREA ----------------
  Widget inputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),
      child: Row(
        children: [

          GestureDetector(
            onTap: _toggleRecord,
            child: Container(
              decoration: BoxDecoration(
                color: isRecording ? Colors.red : const Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Ask about your vehicle...",
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        elevation: 0,
        title: const Text("AutoMind AI Assistant"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white,
              ],
            ),
          ),
        ),
      ),

      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) => bubble(messages[index]),
            ),
          ),

          inputArea(),
        ],
      ),
    );
  }
}