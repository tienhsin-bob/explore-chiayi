import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/firestore_database.dart';
import '../models/spot.dart';
import '../models/food.dart';
import '../models/news.dart';
import '../widgets/section_title.dart';
import '../widgets/info_card.dart';
import 'item_detail_page.dart'; // 引入詳細資訊頁面
import '../services/weather_service.dart';

// 🌟 縫合：引入你做好的輪播元件與秘密爬蟲服務
import '../widgets/news_carousel.dart';
import '../services/news_scraper_service.dart';

class HomePage extends StatelessWidget {
  HomePage({
    super.key,
    required this.onExploreSelected,
    required this.onMapSelected,
    this.onItemMapSelected, // 💡 保留組員修改：選中特定項目跳轉地圖的參數
  });

  final void Function(String category) onExploreSelected;
  final VoidCallback onMapSelected;
  final void Function(dynamic item)? onItemMapSelected; // 💡 保留組員的地圖導航欄位

  final FirestoreDatabase _db = FirestoreDatabase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 70.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: const Text(
                '探索諸羅',
                style: TextStyle(
                  color: AppColors.textTitle,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(color: AppColors.background),
            ),
            // 🌟 縫合：把你的手動更新新聞按鈕與自訂提示字塞進組員的 AppBar 裡！
            actions: [
              IconButton(
                icon: const Icon(Icons.sync, color: AppColors.primary),
                tooltip: '更新市府新聞',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('開始取得市政府最新消息...')),
                  );
                  // 觸發你寫的無敵爬蟲服務
                  await NewsScraperService().scrapeAndUpload();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('最新消息更新完成！')),
                    );
                  }
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 首頁主視覺區
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore Chiayi',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTitle,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '今天想去哪裡玩呢？',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),

                // 即時天氣卡片
                FutureBuilder<WeatherInfo?>(
                  future: WeatherService().fetchChiayiWeather(), // 呼叫我們寫好的服務
                  builder: (context, snapshot) {
                    // 預設顯示的文字 (載入中或失敗時顯示)
                    String weatherText = '載入天氣中...';

                    // 如果成功拿到資料，就組合字串
                    if (snapshot.hasData && snapshot.data != null) {
                      final info = snapshot.data!;
                      weatherText = '${info.condition} · ${info.minTemp}~${info.maxTemp}°C';
                    } else if (snapshot.hasError) {
                      weatherText = '無法取得天氣';
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wb_cloudy_outlined,
                            size: 30,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '今日嘉義天氣',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textTitle,
                            ),
                          ),
                          const Spacer(),
                          // 🌟 這裡顯示即時更新的天氣資訊！
                          snapshot.connectionState == ConnectionState.waiting
                              ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Text(
                            weatherText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24), // 🌟 新增：讓天氣卡片和分類標題之間有呼吸空間

                // 快速分類
                const SectionTitle(title: '快速分類'),
                SizedBox(
                  height: 105, // 🌟 修改：從 120 縮減到 105，收斂多餘的上白留白
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCategoryItem(
                        Icons.place,
                        '景點',
                        onTap: () => onExploreSelected('景點'),
                      ),
                      _buildCategoryItem(
                        Icons.restaurant,
                        '美食',
                        onTap: () => onExploreSelected('美食'),
                      ),
                      _buildCategoryItem(
                        Icons.directions_bus,
                        '交通',
                        onTap: onMapSelected,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24), // 🌟 新增：解決「下面太擠」的關鍵，把最新消息往下推

                // 最新消息區塊
                const SectionTitle(title: '最新消息'),
                _buildGuideRow(
                  imagePath: 'assets/images/re_news.png',
                  title: '看看嘉義新消息',
                  subtitle: '掌握活動、交通與旅遊提醒，讓行程安排更順利。',
                ),

                const SizedBox(height: 12),

                // 🌟 縫合大亮點：用你的 NewsCarousel 膠囊輪播，完美取代組員原本寫得死板板的直向列表！
                const NewsCarousel(),

                const SizedBox(height: 24), // 🌟 微調間距

                // 人氣景點區塊
                const SectionTitle(title: '人氣景點'),
                _buildGuideRow(
                  imagePath: 'assets/images/re_hat.png',
                  title: '想去哪裡走走？',
                  subtitle: '從文化地標到自然風景，發現嘉義最值得停留的景點。',
                ),

                StreamBuilder<List<Spot>>(
                  stream: _db.getSpots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('資料載入錯誤: ${snapshot.error}'),
                      );
                    }

                    final allSpots = snapshot.data ?? [];
                    final popularSpots = allSpots
                        .where((spot) => spot.tags.contains('人氣'))
                        .toList();

                    if (popularSpots.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('目前沒有人氣景點'),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: popularSpots.length,
                        itemBuilder: (context, index) {
                          final spot = popularSpots[index];

                          return SizedBox(
                            width: 220,
                            child: InfoCard(
                              title: spot.name,
                              subtitle: spot.description,
                              imageUrl: spot.images.isNotEmpty
                                  ? spot.images[0]
                                  : 'https://via.placeholder.com/150',
                              trailing: '★ ${spot.averageRating.toStringAsFixed(1)}',
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ItemDetailPage(item: spot),
                                  ),
                                );
                              },
                              // 💡 保留組員修改：點擊小地圖按鈕跳轉地圖
                              onMapTap: () {
                                if (onItemMapSelected != null) {
                                  onItemMapSelected!(spot);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24), // 🌟 微調間距

                // 人氣美食區塊
                const SectionTitle(title: '人氣美食'),
                _buildGuideRow(
                  imagePath: 'assets/images/re_hungry.png',
                  title: '今天想吃什麼？',
                  subtitle: '肚子餓了嗎？一起找嘉義必吃美食吧！',
                ),

                StreamBuilder<List<Food>>(
                  stream: _db.getFoods(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('資料載入錯誤: ${snapshot.error}'),
                      );
                    }

                    final allFoods = snapshot.data ?? [];
                    final popularFoods = allFoods
                        .where((food) => food.tags.contains('人氣'))
                        .toList();

                    if (popularFoods.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('目前沒有人氣美食'),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: popularFoods.length,
                        itemBuilder: (context, index) {
                          final food = popularFoods[index];

                          return SizedBox(
                            width: 220,
                            child: InfoCard(
                              title: food.name,
                              subtitle: food.description,
                              imageUrl: food.images.isNotEmpty
                                  ? food.images[0]
                                  : 'https://via.placeholder.com/150',
                              trailing: '★ ${food.averageRating.toStringAsFixed(1)}',
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ItemDetailPage(item: food),
                                  ),
                                );
                              },
                              // 💡 保留組員修改：點擊小地圖按鈕跳轉地圖
                              onMapTap: () {
                                if (onItemMapSelected != null) {
                                  onItemMapSelected!(food);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow({
    required String imagePath,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
      child: SizedBox(
        height: 82,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 115,
              height: 82,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
      IconData icon,
      String label, {
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.primary,
              child: Icon(
                icon,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textBody,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}