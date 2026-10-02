import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/chat_bubble.dart';
// 記得引入你剛剛建好的 AiService
import '../services/ai_service.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService(); // 實例化 Service

  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 進入頁面時初始化 AI
    try {
      _aiService.init();
      // 可以讓鮑伯先打招呼
      _messages.add({
        'sender': 'ai',
        'message': '你好！我是嘉義旅遊小幫手鮑伯，今天想安排什麼樣的行程呢？'
      });
    } catch (e) {
      _messages.add({'sender': 'ai', 'message': e.toString()});
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'message': text.trim()});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // 呼叫 AiService 取得回覆
    final response = await _aiService.sendMessage(text.trim());

    setState(() {
      _messages.add({'sender': 'ai', 'message': response});
      _isLoading = false;
    });
    _scrollToBottom();
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 行程助手')),
      body: Column(
        children: [
          // 頂部導覽列說明
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            color: AppColors.primary.withOpacity(0.05),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/re_double.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '我是您的嘉義旅遊小幫手鮑伯',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textTitle),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '讓我幫您量身打造專屬行程 !',
                        style: TextStyle(fontSize: 12, color: AppColors.textBody),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 聊天訊息區塊
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final chat = _messages[index];
                return ChatBubble(
                  message: chat['message']!,
                  isUser: chat['sender'] == 'user',
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          // 底部輸入框
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _isLoading ? null : _handleSubmitted,
                    decoration: InputDecoration(
                      hintText: '輸入訊息...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : () => _handleSubmitted(_controller.text),
                  icon: const Icon(Icons.send),
                  color: _isLoading ? Colors.grey : AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}