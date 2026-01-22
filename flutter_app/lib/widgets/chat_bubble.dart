import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/models.dart';

// can we mkae it like this check answer and get probability like this answer is 70 percet right so you will get 70 percent in you taks 1 and in your dashboard the avg score it calculated on 5 task so you can calcuate that too in the end how does this sounds?

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.sender == MessageSender.assistant;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isAssistant ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAssistant)
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              child: CircleAvatar(
                backgroundColor: Colors.grey[800],
                radius: 14,
                child: const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 16),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isAssistant ? Colors.grey[900] : Colors.indigoAccent,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isAssistant ? 4 : 20),
                  bottomRight: Radius.circular(isAssistant ? 20 : 4),
                ),
                border: isAssistant ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
              ),
              child: MarkdownBody(
                data: message.message,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  h1: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  h2: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  listBullet: const TextStyle(color: Colors.white),
                  tableBody: const TextStyle(color: Colors.white),
                  tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  tableBorder: TableBorder.all(color: Colors.white24, width: 1),
                  tableCellsPadding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ),
          if (!isAssistant)
            const SizedBox(width: 32), // Padding for user messages
          if (isAssistant)
            const SizedBox(width: 32), // Padding for assistant messages
        ],
      ),
    );
  }
}

