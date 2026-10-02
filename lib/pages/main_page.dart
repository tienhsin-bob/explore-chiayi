import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/itinerary.dart';
import 'home_page.dart';
import 'spot_food_page.dart';
import 'map_page.dart';
import 'ai_assistant_page.dart';
import 'profile_page.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;
  final dynamic initialMapItem;
  final Itinerary? itineraryToDisplay; // 💡 新增：傳入要顯示的行程

  const MainPage({
    super.key, 
    this.initialIndex = 0,
    this.initialMapItem,
    this.itineraryToDisplay,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _currentIndex;
  String _exploreCategory = '全部';
  dynamic _mapItem;
  Itinerary? _itinerary;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _mapItem = widget.initialMapItem;
    _itinerary = widget.itineraryToDisplay;
  }

  void _goToExplore(String category) {
    setState(() {
      _exploreCategory = category;
      _currentIndex = 1;
    });
  }

  void _goToMap({dynamic item, Itinerary? itinerary}) {
    setState(() {
      _mapItem = item;
      _itinerary = itinerary;
      _currentIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        onExploreSelected: _goToExplore,
        onMapSelected: () => _goToMap(),
        onItemMapSelected: (item) => _goToMap(item: item),
      ),
      SpotFoodPage(
        key: ValueKey(_exploreCategory),
        initialCategory: _exploreCategory,
        onItemMapSelected: (item) => _goToMap(item: item),
      ),
      MapPage(
        initialItem: _mapItem,
        itinerary: _itinerary, // 💡 傳遞行程給地圖頁
      ),
      const AiAssistantPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index != 2) {
              _mapItem = null;
              _itinerary = null;
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '探索'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '地圖'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI助手'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '個人'),
        ],
      ),
    );
  }
}
