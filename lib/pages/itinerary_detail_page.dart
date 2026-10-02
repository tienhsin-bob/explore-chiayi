// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import '../constants/app_colors.dart';
// import '../models/itinerary.dart';
// import '../services/firestore_database.dart';
// import 'item_detail_page.dart';
//
// class ItineraryDetailPage extends StatefulWidget {
//   final Itinerary itinerary;
//
//   const ItineraryDetailPage({super.key, required this.itinerary});
//
//   @override
//   State<ItineraryDetailPage> createState() => _ItineraryDetailPageState();
// }
//
// class _ItineraryDetailPageState extends State<ItineraryDetailPage> with SingleTickerProviderStateMixin {
//   final FirestoreDatabase _db = FirestoreDatabase();
//   final MapController _mapController = MapController();
//   late TabController _tabController;
//   late List<ItineraryItem> _items;
//
//   @override
//   void initState() {
//     super.initState();
//     _items = List.from(widget.itinerary.items);
//     int dayCount = _items.isEmpty ? 1 : _items.map((e) => e.day).reduce((a, b) => a > b ? a : b);
//     _tabController = TabController(length: dayCount + 1, vsync: this);
//   }
//
//   String _convertDriveUrl(String url) {
//     if (url.contains('id=')) {
//       final parts = url.split('id=');
//       if (parts.length > 1) {
//         final id = parts[1].split('&')[0];
//         return 'https://drive.google.com/uc?export=view&id=$id';
//       }
//     }
//     return url;
//   }
//
//   // 💡 修復：儲存行程時補上必填參數 dateRange
//   void _saveOrder() async {
//     final updatedItinerary = Itinerary(
//       id: widget.itinerary.id,
//       uid: widget.itinerary.uid,
//       title: widget.itinerary.title,
//       dateRange: widget.itinerary.dateRange,
//       items: _items,
//       createdAt: widget.itinerary.createdAt,
//     );
//     await _db.saveItinerary(updatedItinerary);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F8F8),
//       appBar: AppBar(
//         title: const Text('行程規劃', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Column(
//         children: [
//           // 上半部地圖
//           SizedBox(
//             height: 240,
//             child: Stack(
//               children: [
//                 FlutterMap(
//                   mapController: _mapController,
//                   options: MapOptions(
//                     initialCenter: _items.isNotEmpty
//                         ? LatLng(_items.first.geoPoint.latitude, _items.first.geoPoint.longitude)
//                         : const LatLng(23.4811, 120.4497),
//                     initialZoom: 13.5,
//                   ),
//                   children: [
//                     TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
//                     PolylineLayer(
//                       polylines: [
//                         Polyline(
//                           points: _items.map((e) => LatLng(e.geoPoint.latitude, e.geoPoint.longitude)).toList(),
//                           color: AppColors.primary.withOpacity(0.5),
//                           strokeWidth: 4,
//                         ),
//                       ],
//                     ),
//                     MarkerLayer(
//                       markers: _items.asMap().entries.map((entry) {
//                         return Marker(
//                           point: LatLng(entry.value.geoPoint.latitude, entry.value.geoPoint.longitude),
//                           width: 30, height: 30,
//                           child: CircleAvatar(
//                             backgroundColor: AppColors.primary,
//                             child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//
//           // 天數 Tab
//           Container(
//             color: Colors.white,
//             width: double.infinity,
//             child: TabBar(
//               controller: _tabController,
//               isScrollable: true,
//               labelColor: Colors.black,
//               unselectedLabelColor: Colors.grey,
//               indicatorColor: AppColors.primary,
//               indicatorSize: TabBarIndicatorSize.label,
//               tabs: [
//                 const Tab(text: '總覽'),
//                 ...List.generate(_tabController.length - 1, (index) => Tab(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text('5/${6 + index}', style: const TextStyle(fontSize: 10)),
//                       Text('第 ${index + 1} 天', style: const TextStyle(fontSize: 14)),
//                     ],
//                   ),
//                 )),
//               ],
//             ),
//           ),
//
//           // 時間軸列表
//           Expanded(
//             child: ListView(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text('第 1 天', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
//                     Text('出發時間：${_items.isNotEmpty ? (_items.first.startTime ?? "08:00") : "08:00"}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 ..._items.asMap().entries.map((entry) => _buildTimelineStep(entry.value, entry.key + 1, entry.key == _items.length - 1)),
//               ],
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {},
//         backgroundColor: AppColors.primary,
//         child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
//       ),
//     );
//   }
//
//   Widget _buildTimelineStep(ItineraryItem item, int step, bool isLast) {
//     return IntrinsicHeight(
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 50,
//             child: Column(
//               children: [
//                 Text(item.startTime ?? '08:00', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 6),
//                 Container(
//                   width: 22, height: 22,
//                   decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
//                   child: Center(child: Text('$step', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
//                 ),
//                 if (!isLast) Expanded(child: Container(width: 1.5, color: Colors.grey[300])),
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               children: [
//                 InkWell(
//                   onTap: () async {
//                     final full = item.type == 'spot' ? await _db.getSpot(item.id) : await _db.getFood(item.id);
//                     if (full != null) Navigator.push(context, MaterialPageRoute(builder: (c) => ItemDetailPage(item: full)));
//                   },
//                   child: Container(
//                     margin: const EdgeInsets.only(bottom: 16),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
//                     ),
//                     child: Row(
//                       children: [
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(10),
//                           child: Image.network(_convertDriveUrl(item.imageUrl), width: 65, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 65, height: 60, color: Colors.grey[200], child: const Icon(Icons.image_outlined))),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                             Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                             const SizedBox(height: 4),
//                             Text('停留 ${item.stayDuration ?? "1 小時"}', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
//                           ]),
//                         ),
//                         const Icon(Icons.more_horiz, color: Colors.grey),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
