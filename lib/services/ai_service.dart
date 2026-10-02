import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// 🌟 引入 Google 官方套件，徹底告別手動處理網址！
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  late final GenerativeModel _model;
  ChatSession? _chat;
  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('找不到 API Key，請確認 .env 檔案設定');
    }

    // 🌟 使用 Google 官方套件初始化模型！它會自動幫我們接上正確的伺服器。
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', // 直接指定最新最快的模型
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 8192, // 依然保持 8192 最高字數限制
      ),
    );

    // 🌟 官方套件會自動幫我們記住「對話紀錄」，不用我們自己寫陣列了！
    _chat = _model.startChat();
    _isInitialized = true;
  }

  Future<String> sendMessage(String message) async {
    if (!_isInitialized || _chat == null) return '鮑伯還沒準備好，請稍後再試。';

    String promptText = message;

    // 如果是第一句話，偷偷加上鮑伯的嚮導人設
    if (_chat!.history.isEmpty) {
      promptText = '你是一位專業的嘉義旅遊嚮導鮑伯，正在協助一款名為「嘉義火雞肉飯探險家」的 App。請用親切熱情、繁體中文的語氣回答問題，並多推薦嘉義在地美食與景點。請提供詳細完整、條理分明的建議，並使用 Markdown 格式排版（粗體、清單）。\n\n使用者問：$message';
    }

    try {
      // 🌟 透過官方套件發送訊息，它會自動處理等待、連線和資料解析！
      final response = await _chat!.sendMessage(Content.text(promptText));

      String reply = response.text ?? '鮑伯陷入了沉思，請再問一次。';

      // 自動修剪字尾多出來的空列表符號或換行
      reply = reply.trim();
      if (reply.endsWith('\n-') || reply.endsWith('\n*')) {
        reply = reply.substring(0, reply.length - 2).trim();
      }

      debugPrint('【Debug】鮑伯完整回覆：\n$reply', wrapWidth: 1024);
      return reply;

    } catch (e) {
      return '網路或伺服器發生例外狀況：$e';
    }
  }
}