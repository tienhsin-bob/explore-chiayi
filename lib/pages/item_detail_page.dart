import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/spot.dart';
import '../models/food.dart';
import '../models/favorite.dart';
import '../models/itinerary.dart';
import '../services/firestore_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_page.dart';

class ItemDetailPage extends StatefulWidget {
  final dynamic item;
  final int targetDay; // 💡 新增：目標天數

  const ItemDetailPage({super.key, required this.item, this.targetDay = 1});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  int _currentImageIndex = 0;
  final FirestoreDatabase _db = FirestoreDatabase();
  final User? _user = FirebaseAuth.instance.currentUser;

  String _convertDriveUrl(String url) {
    if (url.contains('drive.google.com')) {
      if (url.contains('/file/d/')) {
        final parts = url.split('/file/d/');
        if (parts.length > 1) {
          final id = parts[1].split('/')[0];
          return 'https://drive.google.com/uc?export=view&id=$id';
        }
      } else if (url.contains('id=')) {
        final parts = url.split('id=');
        if (parts.length > 1) {
          final id = parts[1].split('&')[0];
          return 'https://drive.google.com/uc?export=view&id=$id';
        }
      }
    }
    return url;
  }

  void _jumpToMap({Itinerary? itinerary}) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainPage(
          initialIndex: 2,
          initialMapItem: widget.item,
          itineraryToDisplay: itinerary, // 💡 傳入行程以便地圖頁自動選中
        ),
      ),
      (route) => false,
    );
  }

  void _showItinerarySelectionDialog() {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請先登入後再使用行程功能')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('加入到我的行程', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Flexible(
                child: StreamBuilder<List<Itinerary>>(
                  stream: _db.getUserItineraries(_user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final itineraries = snapshot.data ?? [];

                    return ListView(
                      shrinkWrap: true,
                      children: [
                        if (itineraries.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text('目前還沒有行程列表，請點擊下方按鈕建立。', style: TextStyle(color: Colors.grey)),
                          ),
                        ...itineraries.map((itinerary) => ListTile(
                          leading: const Icon(Icons.playlist_add, color: AppColors.primary),
                          title: Text(itinerary.title),
                          subtitle: Text('${itinerary.items.length} 個地點'),
                          onTap: () => _handleAddToExisting(itinerary),
                        )),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                          title: const Text('建立新行程並加入'),
                          onTap: () {
                            Navigator.pop(context);
                            _showCreateNewItineraryDialog();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _handleAddToExisting(Itinerary itinerary) async {
    Navigator.pop(context);
    final String imageUrl = (widget.item.images != null && widget.item.images.isNotEmpty) ? widget.item.images[0] : '';
    final newItem = ItineraryItem(
      id: widget.item.id, 
      name: widget.item.name, 
      type: widget.item is Spot ? 'spot' : 'food',
      geoPoint: widget.item.geoPoint, 
      imageUrl: imageUrl,
      day: widget.targetDay, // 💡 使用傳入的 targetDay
    );

    try {
      await _db.addItemToItinerary(_user!.uid, newItem, itineraryId: itinerary.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('新增成功 (第 ${widget.targetDay} 天)'),
            action: SnackBarAction(
              label: '行程查看',
              onPressed: () => _jumpToMap(itinerary: itinerary), // 💡 跳轉回地圖行程區
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加入失敗: $e')));
    }
  }

  void _showCreateNewItineraryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('建立新行程'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '行程名稱')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final String imageUrl = (widget.item.images != null && widget.item.images.isNotEmpty) ? widget.item.images[0] : '';
                final newItem = ItineraryItem(
                  id: widget.item.id, 
                  name: widget.item.name, 
                  type: widget.item is Spot ? 'spot' : 'food',
                  geoPoint: widget.item.geoPoint, 
                  imageUrl: imageUrl,
                  day: widget.targetDay, // 💡 使用傳入的 targetDay
                );
                final newItinerary = Itinerary(
                  id: '', 
                  uid: _user!.uid, 
                  title: controller.text, 
                  dateRange: '未定日期',
                  items: [newItem], 
                  createdAt: DateTime.now(),
                );
                final docId = await _db.saveItinerary(newItinerary);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('新增成功'),
                      action: SnackBarAction(
                        label: '行程查看',
                        onPressed: () {
                          final createdItin = Itinerary(
                            id: docId, uid: newItinerary.uid, title: newItinerary.title,
                            dateRange: newItinerary.dateRange, items: newItinerary.items, createdAt: newItinerary.createdAt,
                          );
                          _jumpToMap(itinerary: createdItin);
                        },
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('建立'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.item.name ?? '未命名';
    final String id = widget.item.id ?? '';
    final String type = widget.item is Spot ? 'spot' : 'food';

    final List<dynamic> rawImages = widget.item.images ?? [];
    final List<String> images = rawImages.map((img) => _convertDriveUrl(img.toString())).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(icon: const Icon(Icons.add_location_alt_outlined), onPressed: _showItinerarySelectionDialog, tooltip: '加入行程'),
          IconButton(icon: const Icon(Icons.map_outlined), onPressed: () => _jumpToMap(), tooltip: '在地圖中查看'),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    height: 250, width: double.infinity,
                    child: PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) => setState(() => _currentImageIndex = index),
                      itemBuilder: (context, index) => Image.network(images[index], fit: BoxFit.cover),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textTitle))),
                      if (_user != null)
                        StreamBuilder<List<Favorite>>(
                          stream: _db.getUserFavorites(_user.uid),
                          builder: (context, snapshot) {
                            final isFav = snapshot.hasData && snapshot.data!.any((f) => f.targetId == id);
                            return IconButton(
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                              onPressed: () => _db.toggleFavorite(_user.uid, type, id),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(widget.item.description ?? '', style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textBody)),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () => _jumpToMap(),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.item.address ?? '', style: const TextStyle(fontSize: 15))),
                        const Icon(Icons.map, color: AppColors.primary, size: 20),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
