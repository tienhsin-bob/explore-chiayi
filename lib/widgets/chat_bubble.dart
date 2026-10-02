import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../constants/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    // 根據是否為使用者設定文字顏色
    final Color textColor = isUser ? Colors.white : AppColors.textBody;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(12.0),
        // 限制泡泡最大寬度，避免在寬螢幕上拉得太長
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: MarkdownBody(
          data: message,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            // 設定一般段落樣式
            p: TextStyle(
              color: textColor,
              fontSize: 16,
              height: 1.5,
            ),
            // 設定清單項目樣式
            listBullet: TextStyle(color: textColor, fontSize: 16),
            // 設定粗體樣式
            strong: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            // 如果有標題文字，也一併設定顏色
            h1: TextStyle(color: textColor),
            h2: TextStyle(color: textColor),
            h3: TextStyle(color: textColor),
          ),
        ),
      ),
    );
  }
}
