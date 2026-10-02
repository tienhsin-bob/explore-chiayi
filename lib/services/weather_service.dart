import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 建立一個簡單的資料模型來裝天氣資訊
class WeatherInfo {
  final String condition; // 天氣狀態 (例如：晴時多雲)
  final String minTemp;   // 最低溫
  final String maxTemp;   // 最高溫

  WeatherInfo({
    required this.condition,
    required this.minTemp,
    required this.maxTemp,
  });
}

class WeatherService {
  // 氣象署 F-C0032-001 (一般天氣預報-今明 36 小時天氣預報)
  final String _baseUrl = 'https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-C0032-001';

  Future<WeatherInfo?> fetchChiayiWeather() async {
    final apiKey = dotenv.env['CWA_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('找不到 CWA_API_KEY');
      return null;
    }

    // 指定只抓「嘉義市」的資料，節省流量與解析時間
    final url = '$_baseUrl?Authorization=$apiKey&locationName=嘉義市';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // 氣象署回傳的 JSON 結構解析 (剝洋蔥過程)
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final location = data['records']['location'][0];
        final weatherElements = location['weatherElement'] as List;

        // 尋找對應的天氣元素
        String wx = '';
        String minT = '';
        String maxT = '';

        for (var element in weatherElements) {
          final elementName = element['elementName'];
          // 取第一筆時間區間 (最近的 12 小時)
          final parameterName = element['time'][0]['parameter']['parameterName'];

          if (elementName == 'Wx') wx = parameterName;
          if (elementName == 'MinT') minT = parameterName;
          if (elementName == 'MaxT') maxT = parameterName;
        }

        return WeatherInfo(
          condition: wx,
          minTemp: minT,
          maxTemp: maxT,
        );
      } else {
        debugPrint('氣象署 API 錯誤: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('抓取天氣發生例外狀況: $e');
      return null;
    }
  }
}