import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🌟 縫合：引入 dotenv 套件，AI 助手才能讀取金鑰
import 'app/explore_chiayi_app.dart';
import 'firebase_options.dart';

void main() async {
  // 確保 Flutter 核心元件已初始化 (這行絕對要在最前面)
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化 Firebase (使用組員專案的設定)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. 🌟 縫合：載入最外層的 .env 檔案，這樣你的 AI 助手（鮑伯）才拿得到 API 金鑰！
  await dotenv.load(fileName: ".env");

  // 3. 執行完整的 App
  runApp(const ExploreChiayiApp());
}