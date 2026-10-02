import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news.dart';

class NewsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🌟 將原本的 Future 改成 Stream，並使用 snapshots() 來監聽資料庫變化
  Stream<List<News>> streamNews() {
    return _db
        .collection('news')
        .orderBy('publishedAt', descending: true) // 最新的在前面
        .limit(5) // 只抓最新的 5 則
        .snapshots() // 關鍵：這是持續監聽資料庫的指令！
        .map((snapshot) =>
        snapshot.docs.map((doc) => News.fromFirestore(doc)).toList());
  }
}