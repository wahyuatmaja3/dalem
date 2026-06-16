import 'package:flutter/material.dart';
import '../../data/models/chat_message_model.dart';
import '../../../../core/constants/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.senderType == SenderType.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser
                ? const Radius.circular(18)
                : const Radius.circular(6),
            bottomRight: isUser
                ? const Radius.circular(6)
                : const Radius.circular(18),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.divider, width: 1),
        ),
        child: Text(
          message.message,
          style: TextStyle(
            fontSize: 15,
            color: isUser ? AppColors.textPrimary : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
