import 'package:flutter/material.dart';
import '../../data/models/chat_message_model.dart';
import 'chat_bubble.dart';

class ChatTab extends StatefulWidget {
  final List<ChatMessageModel> messages;
  final bool isSending;
  final Function(String) onSendMessage;

  const ChatTab({
    super.key,
    required this.messages,
    required this.isSending,
    required this.onSendMessage,
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    widget.onSendMessage(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.messages.isEmpty
              ? Center(
                  child: Text(
                    'Start a conversation about this note',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    return ChatBubble(message: widget.messages[index]);
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _handleSend(),
                  enabled: !widget.isSending,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: widget.isSending ? null : _handleSend,
                icon: widget.isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
