import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/favorite.dart';
import '../models/spot.dart';
import '../models/food.dart';
import '../services/firestore_database.dart';
import '../widgets/info_card.dart';
import 'item_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final FirestoreDatabase _db = FirestoreDatabase();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('我的收藏')),
        body: const Center(child: Text('請先登入以查看收藏')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textTitle,
        elevation: 0,
      ),
      body: StreamBuilder<List<Favorite>>(
        stream: _db.getUserFavorites(_user.uid),
        builder: (context, favSnapshot) {
          if (favSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = favSnapshot.data ?? [];

          if (favorites.isEmpty) {
            return _buildEmptyState();
          }

          return StreamBuilder<List<Spot>>(
            stream: _db.getSpots(),
            builder: (context, spotSnapshot) {
              return StreamBuilder<List<Food>>(
                stream: _db.getFoods(),
                builder: (context, foodSnapshot) {
                  if (spotSnapshot.connectionState == ConnectionState.waiting ||
                      foodSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allSpots = spotSnapshot.data ?? [];
                  final allFoods = foodSnapshot.data ?? [];

                  // 根據收藏清單過濾出對應的物件
                  List<dynamic> favoriteItems = [];
                  for (var fav in favorites) {
                    if (fav.targetType == 'spot') {
                      final spot = allSpots.where((s) => s.id == fav.targetId).firstOrNull;
                      if (spot != null) favoriteItems.add(spot);
                    } else if (fav.targetType == 'food') {
                      final food = allFoods.where((f) => f.id == fav.targetId).firstOrNull;
                      if (food != null) favoriteItems.add(food);
                    }
                  }

                  if (favoriteItems.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: favoriteItems.length,
                    itemBuilder: (context, index) {
                      final item = favoriteItems[index];
                      final isSpot = item is Spot;
                      final String title = item.name;
                      final String typeLabel = isSpot ? item.category : item.type;
                      final String rating = item.averageRating.toStringAsFixed(1);
                      final String imageUrl = item.images.isNotEmpty
                          ? item.images[0]
                          : 'https://via.placeholder.com/150';

                      return InfoCard(
                        title: title,
                        subtitle: '$typeLabel | ${item.description}',
                        imageUrl: imageUrl,
                        trailing: '★ $rating',
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailPage(item: item),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/re_cry.png',
              width: 190,
              height: 190,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.favorite_border, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              '目前還沒有收藏',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textTitle,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '快去探索嘉義的景點與美食，\n把喜歡的地點加入收藏吧！',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textBody,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.travel_explore),
              label: const Text('開始探索'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
