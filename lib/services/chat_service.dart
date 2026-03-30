import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/amazon_service.dart';

class ChatScreen extends StatefulWidget {
  final Product product;
  const ChatScreen({super.key, required this.product});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _messages.add({
      "isUser": false,
      "text": "Hi! I'm your Smart Assistant for ${widget.product.name}. Ask me if you should buy now or wait!"
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"isUser": true, "text": text});
      _isLoading = true;
    });
    _messageController.clear();

    try {
      // We use amazonService here as the bridge to our FastAPI backend
      final reply = await amazonService.askAssistant(widget.product, text);
      setState(() => _messages.add({"isUser": false, "text": reply}));
    } catch (e) {
      setState(() => _messages.add({"isUser": false, "text": "Error: $e"}));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg["isUser"] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg["isUser"] ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg["text"], style: TextStyle(color: msg["isUser"] ? Colors.white : Colors.black)),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: "Ask something..."))),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}