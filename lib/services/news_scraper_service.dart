import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news.dart';

class NewsScraperService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String _targetUrl = 'https://www.chiayi.gov.tw/News.aspx?n=413&sms=8954';

  Future<void> scrapeAndUpload() async {
    try {
      print('【系統】開始清除舊版新聞資料...');
      var oldDocs = await _db.collection('news').get();
      for (var doc in oldDocs.docs) {
        await doc.reference.delete();
      }
      print('【系統】舊資料已全數清除完畢！');

      print('【爬蟲】開始抓取嘉義市政府網站...');
      final response = await http.get(Uri.parse(_targetUrl));

      if (response.statusCode == 200) {
        var document = parse(response.body);
        var allLinks = document.querySelectorAll('a');

        var newsLinks = allLinks.where((a) {
          final href = a.attributes['href'];
          return href != null && href.contains('News_Content.aspx');
        }).toList();

        Set<String> processedUrls = {};
        int successCount = 0;

        for (var aTag in newsLinks) {
          String link = aTag.attributes['href']!;
          String title = aTag.text.trim();

          if (title.isEmpty) continue;

          List<String> blacklist = ['品牌標誌', '嘉市體', 'RSS', '隱私權宣告', '資訊安全政策', '政府網站資料開放宣告'];
          if (blacklist.contains(title) || title.length <= 3) {
            continue;
          }

          if (!link.startsWith('http')) {
            link = link.startsWith('/') ? 'https://www.chiayi.gov.tw$link' : 'https://www.chiayi.gov.tw/$link';
          }

          if (processedUrls.contains(link)) continue;
          processedUrls.add(link);

          String parentText = aTag.parent?.parent?.text ?? '';
          RegExp dateRegExp = RegExp(r'\d{4}-\d{2}-\d{2}');
          var match = dateRegExp.firstMatch(parentText);

          if (match == null) continue;

          String dateStr = match.group(0)!;
          DateTime publishedDate = DateTime.tryParse(dateStr) ?? DateTime.now();

          String uniqueId = '';
          if (link.contains('s=')) {
            uniqueId = link.split('s=').last.split('&').first;
          } else {
            uniqueId = link.hashCode.toString();
          }

          News newsArticle = News(
            id: uniqueId,
            title: title,
            content: '', // 既然不顯示了，就留空
            category: '市政公告',
            source: link, // 🌟 殺手鐧：把最精準、毫無拼湊的真實網址存入 source 中！
            publishedAt: publishedDate,
            updatedAt: DateTime.now(),
          );

          await _db.collection('news').doc(newsArticle.id).set(newsArticle.toMap());
          successCount++;
        }
        print('🎉 爬蟲作業結束！共成功寫入 $successCount 則最新消息！');
      }
    } catch (e) {
      print('【爬蟲】發生嚴重錯誤：$e');
    }
  }
}