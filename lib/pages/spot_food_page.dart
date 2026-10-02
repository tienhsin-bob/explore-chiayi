import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/firestore_database.dart';
import '../models/spot.dart';
import '../models/food.dart';
import '../widgets/info_card.dart';
import 'item_detail_page.dart';

class SpotFoodPage extends StatefulWidget {
  final String initialCategory;
  final void Function(dynamic item)? onItemMapSelected;
  final int targetDay; // 💡 新增：目標天數

  const SpotFoodPage({
    super.key,
    this.initialCategory = '全部',
    this.onItemMapSelected,
    this.targetDay = 1,
  });

  @override
  State<SpotFoodPage> createState() => _SpotFoodPageState();
}

class _SpotFoodPageState extends State<SpotFoodPage> {
  late String selectedCategory;
  String? selectedSubCategory;

  final FirestoreDatabase _db = FirestoreDatabase();

  final List<String> categories = [
    '全部',
    '景點',
    '美食',
    '住宿',
  ];

  final Map<String, List<String>> subCategoriesMap = {
    '景點': ['親子', '公園', '博物館', '美術館', '人氣'],
    '美食': ['夜市', '飲料店', '火雞肉飯', '台式', '美式', '韓式', '日式', '甜點'],
  };

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
  }

  @override
  void didUpdateWidget(covariant SpotFoodPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      setState(() {
        selectedCategory = widget.initialCategory;
        selectedSubCategory = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('探索'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textTitle,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜尋景點、美食、住宿...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (bool value) {
                      setState(() {
                        if (selectedCategory != category) {
                          selectedCategory = category;
                          selectedSubCategory = null;
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.20),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                    labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.textBody, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                );
              },
            ),
          ),
          if (subCategoriesMap.containsKey(selectedCategory)) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: subCategoriesMap[selectedCategory]!.length,
                itemBuilder: (context, index) {
                  final subCategory = subCategoriesMap[selectedCategory]![index];
                  final isSubSelected = selectedSubCategory == subCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(subCategory),
                      selected: isSubSelected,
                      showCheckmark: false,
                      onSelected: (bool value) {
                        setState(() {
                          selectedSubCategory = value ? subCategory : null;
                        });
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: isSubSelected ? AppColors.primary : Colors.grey.shade300),
                      labelStyle: TextStyle(color: isSubSelected ? Colors.white : AppColors.textBody, fontWeight: isSubSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Spot>>(
              stream: _db.getSpots(),
              builder: (context, spotSnapshot) {
                return StreamBuilder<List<Food>>(
                  stream: _db.getFoods(),
                  builder: (context, foodSnapshot) {
                    if (spotSnapshot.connectionState == ConnectionState.waiting || foodSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (spotSnapshot.hasError || foodSnapshot.hasError) return const Center(child: Text('資料載入發生錯誤'));

                    final firebaseSpots = spotSnapshot.data ?? [];
                    final firebaseFoods = foodSnapshot.data ?? [];
                    List<dynamic> allFilteredItems = [];

                    if (selectedCategory == '全部' || selectedCategory == '景點') {
                      var spots = firebaseSpots;
                      if (selectedSubCategory != null) spots = spots.where((spot) => spot.tags.contains(selectedSubCategory)).toList();
                      allFilteredItems.addAll(spots);
                    }
                    if (selectedCategory == '全部' || selectedCategory == '美食') {
                      var foods = firebaseFoods;
                      if (selectedSubCategory != null) foods = foods.where((food) => food.tags.contains(selectedSubCategory)).toList();
                      allFilteredItems.addAll(foods);
                    }

                    if (allFilteredItems.isEmpty) return _buildEmptyState();

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: allFilteredItems.length,
                      itemBuilder: (context, index) {
                        final item = allFilteredItems[index];
                        final isSpot = item is Spot;
                        final String imageUrl = item.images.isNotEmpty ? item.images[0] : 'https://via.placeholder.com/150';

                        return InfoCard(
                          title: item.name,
                          subtitle: '${isSpot ? item.category : item.type} | ${item.description}',
                          imageUrl: imageUrl,
                          trailing: '★ ${item.averageRating.toStringAsFixed(1)}',
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemDetailPage(
                                  item: item, 
                                  targetDay: widget.targetDay, // 💡 傳遞天數給詳細頁
                                ),
                              ),
                            );
                          },
                          onMapTap: () {
                            if (widget.onItemMapSelected != null) widget.onItemMapSelected!(item);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final emptyTarget = selectedSubCategory != null ? '$selectedCategory - $selectedSubCategory' : selectedCategory;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('目前沒有 $emptyTarget 資料', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textTitle)),
          ],
        ),
      ),
    );
  }
}
