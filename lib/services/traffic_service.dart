import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 🌟 [腳踏車] 站點資料模型
class YouBikeStation {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final int availableBikes;
  final int emptySpaces;

  YouBikeStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.availableBikes = 0,
    this.emptySpaces = 0,
  });
}

// 🌟 [公車] 站點資料模型
class BusStation {
  final String id;
  final String name;
  final double lat;
  final double lon;

  BusStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
  });
}

// 🌟 [公車動態] 到站資訊模型 (新增)
class BusArrival {
  final String routeName;
  final int? estimateTime; // 預估到站秒數 (null 代表無資料或已收班)
  final int stopStatus;    // 狀態 (0:正常, 1:尚未發車, 2:交管, 3:末班車已過, 4:今日未營運)

  BusArrival({
    required this.routeName,
    this.estimateTime,
    required this.stopStatus,
  });

  // 轉換成好閱讀的文字
  String get statusText {
    if (stopStatus == 1) return '尚未發車';
    if (stopStatus == 2) return '交管不停靠';
    if (stopStatus == 3) return '末班車已過';
    if (stopStatus == 4) return '今日未營運';
    if (estimateTime == null) return '資料讀取中';

    final minutes = estimateTime! ~/ 60;
    if (minutes <= 1) return '即將進站';
    return '$minutes 分鐘';
  }
}

class TrafficService {
  // 🌟 1. 換取通行證
  Future<String?> _getAccessToken() async {
    final clientId = dotenv.env['TDX_CLIENT_ID']?.trim();
    final clientSecret = dotenv.env['TDX_CLIENT_SECRET']?.trim();

    if (clientId == null || clientId.isEmpty || clientSecret == null || clientSecret.isEmpty) {
      debugPrint('【TDX 雷達】找不到 .env 裡的金鑰！');
      return null;
    }

    final url = Uri.parse('https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      }
    } catch (e) {
      debugPrint('【TDX 雷達】換取通行證發生例外: $e');
    }
    return null;
  }

  // 🌟 2. 抓取嘉義市 YouBike
  Future<List<YouBikeStation>> getChiayiYouBikes() async {
    final token = await _getAccessToken();
    if (token == null) return [];

    final stationUrl = Uri.parse('https://tdx.transportdata.tw/api/basic/v2/Bike/Station/City/Chiayi?%24format=JSON');
    final availabilityUrl = Uri.parse('https://tdx.transportdata.tw/api/basic/v2/Bike/Availability/City/Chiayi?%24format=JSON');

    try {
      final responses = await Future.wait([
        http.get(stationUrl, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'}),
        http.get(availabilityUrl, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'}),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final List<dynamic> stationData = jsonDecode(responses[0].body);
        final List<dynamic> availData = jsonDecode(responses[1].body);

        Map<String, dynamic> availMap = {};
        for (var item in availData) availMap[item['StationUID']] = item;

        return stationData.map((item) {
          final uid = item['StationUID'];
          final availInfo = availMap[uid];

          return YouBikeStation(
            id: uid,
            name: item['StationName']['Zh_tw'] ?? '未知站點',
            lat: item['StationPosition']['PositionLat'],
            lon: item['StationPosition']['PositionLon'],
            availableBikes: availInfo?['AvailableRentBikes'] ?? 0,
            emptySpaces: availInfo?['AvailableReturnBikes'] ?? 0,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('【TDX 雷達】抓腳踏車例外: $e');
    }
    return [];
  }

  // 🌟 3. 抓取嘉義市公車站點
  Future<List<BusStation>> getChiayiBusStations() async {
    final token = await _getAccessToken();
    if (token == null) return [];

    final url = Uri.parse('https://tdx.transportdata.tw/api/basic/v2/Bus/Station/City/Chiayi?%24format=JSON');

    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          return BusStation(
            id: item['StationUID'],
            name: item['StationName']['Zh_tw'] ?? '未知站牌',
            lat: item['StationPosition']['PositionLat'],
            lon: item['StationPosition']['PositionLon'],
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('【TDX 雷達】抓公車例外: $e');
    }
    return [];
  }

  // 🌟 4. 抓取特定公車站的即時到站資訊 (新增)
  Future<List<BusArrival>> getBusArrivalTimes(String stationId) async {

    final token = await _getAccessToken();
    if (token == null) return [];

    // 利用 OData 的 $filter 語法，只抓取使用者點擊的這個站牌資料
    final url = Uri.parse('https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/Chiayi?%24filter=StationUID%20eq%20%27$stationId%27&%24format=JSON');

    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data.map((item) {
          return BusArrival(
            routeName: item['RouteName']['Zh_tw'] ?? '未知路線',
            estimateTime: item['EstimateTime'],
            stopStatus: item['StopStatus'] ?? 0,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('【TDX 雷達】抓公車動態例外: $e');
    }
    return [];
  }
}