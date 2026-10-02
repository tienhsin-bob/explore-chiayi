class SpotFoodItem {
  final String name;
  final String type;
  final String description;
  final double rating;
  final String imageUrl;

  SpotFoodItem({
    required this.name,
    required this.type,
    required this.description,
    required this.rating,
    required this.imageUrl,
  });
}

class MockData {
  static List<SpotFoodItem> recommendedSpots = [
    SpotFoodItem(
      name: '檜意森活村',
      type: '景點',
      description: '全台最大日式建築群，充滿懷舊氣息。',
      rating: 4.5,
      imageUrl: 'https://via.placeholder.com/150',
    ),
    SpotFoodItem(
      name: '蘭潭風景區',
      type: '景點',
      description: '嘉義人的後花園，夜晚的水舞秀非常精彩。',
      rating: 4.3,
      imageUrl: 'https://via.placeholder.com/150',
    ),
    SpotFoodItem(
      name: '嘉義公園',
      type: '景點',
      description: '歷史悠久的公園，內有射日塔。',
      rating: 4.2,
      imageUrl: 'https://via.placeholder.com/150',
    ),
  ];

  static List<SpotFoodItem> recommendedFoods = [
    SpotFoodItem(
      name: '民主火雞肉飯',
      type: '美食',
      description: '嘉義排隊名店，火雞肉與醬汁的完美比例。',
      rating: 4.7,
      imageUrl: 'https://via.placeholder.com/150',
    ),
    SpotFoodItem(
      name: '文化路夜市',
      type: '美食',
      description: '嘉義夜晚最熱鬧的地方，各種在地小吃。',
      rating: 4.6,
      imageUrl: 'https://via.placeholder.com/150',
    ),
    SpotFoodItem(
      name: '林聰明砂鍋魚頭',
      type: '美食',
      description: '傳承三代的美味，湯頭濃郁豐富。',
      rating: 4.8,
      imageUrl: 'https://via.placeholder.com/150',
    ),
  ];

  static List<String> news = [
    '嘉義市週末觀光活動：管樂節熱鬧登場。',
    '文化路夜市周邊交通提醒：週六晚間實施管制。',
    '阿里山旅遊旺季提醒：請提前預約接駁車。',
  ];

  static List<Map<String, String>> chatMessages = [
    {'sender': 'user', 'message': '我想安排嘉義市一日遊，希望有美食、景點，也不要走太多路。'},
    {'sender': 'ai', 'message': '推薦行程包含嘉義公園（可搭乘電動公車）、檜意森活村，最後去文化路夜市品嚐火雞肉飯。'},
  ];
}
