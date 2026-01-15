import 'package:flutter/material.dart';
import '../models/models.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.sender == MessageSender.assistant;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssistant)
            const CircleAvatar(
              backgroundColor: Colors.indigo,
              radius: 16,
              child: Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAssistant ? Colors.grey[200] : Colors.indigo,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAssistant ? 0 : 16),
                  bottomRight: Radius.circular(isAssistant ? 16 : 0),
                ),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: isAssistant ? Colors.black87 : Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!isAssistant)
            const CircleAvatar(
              backgroundColor: Colors.blueGrey,
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }
}
