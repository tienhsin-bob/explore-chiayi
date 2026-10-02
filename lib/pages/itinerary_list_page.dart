// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../constants/app_colors.dart';
// import '../services/firestore_database.dart';
// import '../models/itinerary.dart';
// import '../models/favorite.dart';
// import 'itinerary_detail_page.dart';
//
// class ItineraryListPage extends StatefulWidget {
//   const ItineraryListPage({super.key});
//
//   @override
//   State<ItineraryListPage> createState() => _ItineraryListPageState();
// }
//
// class _ItineraryListPageState extends State<ItineraryListPage> {
//   final FirestoreDatabase _db = FirestoreDatabase();
//
//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;
//
//     if (user == null) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(title: const Text('我的行程')),
//         body: const Center(child: Text('請先登入')),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('我的行程', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: AppColors.textTitle, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Column(
//         children: [
//           _buildStatHeader(user.uid),
//           const Divider(height: 1, thickness: 1),
//
//           Expanded(
//             child: StreamBuilder<List<Itinerary>>(
//               stream: _db.getUserItineraries(user.uid),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 final itineraries = snapshot.data ?? [];
//
//                 return ListView(
//                   padding: const EdgeInsets.all(24),
//                   children: [
//                     _buildAddButton(user.uid),
//                     const SizedBox(height: 32),
//
//                     if (itineraries.isEmpty)
//                       const Center(child: Text('尚無行程，快來新增一個吧！', style: TextStyle(color: Colors.grey)))
//                     else
//                       ...itineraries.map((it) => _buildItineraryCard(it)),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatHeader(String uid) {
//     return StreamBuilder<List<Favorite>>(
//       stream: _db.getUserFavorites(uid),
//       builder: (context, favSnap) {
//         return StreamBuilder<List<Itinerary>>(
//           stream: _db.getUserItineraries(uid),
//           builder: (context, itinSnap) {
//             final itCount = itinSnap.data?.length ?? 0;
//             final favCount = favSnap.data?.length ?? 0;
//
//             return Padding(
//               padding: const EdgeInsets.only(top: 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _buildStatTab(itCount.toString(), '旅程', true),
//                   _buildStatTab(favCount.toString(), '景點收藏', false),
//                   _buildStatTab('0', '訂單', false),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildStatTab(String count, String label, bool isSelected) {
//     return Column(
//       children: [
//         Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 4),
//         Text(label, style: TextStyle(fontSize: 14, color: isSelected ? AppColors.textTitle : Colors.grey[400])),
//         const SizedBox(height: 10),
//         if (isSelected)
//           Container(height: 3, width: 60, color: AppColors.primary)
//         else
//           const SizedBox(height: 3),
//       ],
//     );
//   }
//
//   Widget _buildAddButton(String uid) {
//     return InkWell(
//       onTap: () => _showCreateDialog(uid),
//       child: Row(
//         children: [
//           Container(
//             width: 75, height: 75,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.grey[200]!, width: 2),
//               boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
//             ),
//             child: const Icon(Icons.add, size: 35, color: AppColors.primary),
//           ),
//           const SizedBox(width: 20),
//           const Text('新增旅程', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textTitle)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildItineraryCard(Itinerary itinerary) {
//     final String coverImg = itinerary.items.isNotEmpty ? itinerary.items.first.imageUrl : '';
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 28),
//       child: InkWell(
//         onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ItineraryDetailPage(itinerary: itinerary))),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             ClipOval(
//               child: Image.network(
//                 _convertDriveUrl(coverImg),
//                 width: 80, height: 80, fit: BoxFit.cover,
//                 errorBuilder: (c, e, s) => Container(color: AppColors.background, child: const Icon(Icons.image, color: Colors.grey)),
//               ),
//             ),
//             const SizedBox(width: 20),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(itinerary.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textTitle)),
//                       IconButton(
//                         icon: const Icon(Icons.delete_outline, color: AppColors.textTitle), // 💡 咖啡色
//                         onPressed: () => _confirmDelete(itinerary),
//                       ),
//                     ],
//                   ),
//                   Text(itinerary.dateRange, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showCreateDialog(String uid) {
//     final controller = TextEditingController();
//     showDialog(context: context, builder: (c) => AlertDialog(
//       title: const Text('建立新旅程'),
//       content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '輸入行程名稱')),
//       actions: [
//         TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')),
//         TextButton(onPressed: () async {
//           if (controller.text.isNotEmpty) {
//             final newIt = Itinerary(
//                 id: '',
//                 uid: uid,
//                 title: controller.text,
//                 dateRange: '未定日期',
//                 items: [],
//                 createdAt: DateTime.now()
//             );
//             await _db.saveItinerary(newIt);
//             if (mounted) Navigator.pop(c);
//           }
//         }, child: const Text('建立')),
//       ],
//     ));
//   }
//
//   void _confirmDelete(Itinerary itinerary) {
//     showDialog(context: context, builder: (c) => AlertDialog(
//       title: const Text('刪除行程'),
//       content: Text('確定要刪除「${itinerary.title}」嗎？'),
//       actions: [
//         TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')),
//         TextButton(onPressed: () async {
//           await _db.deleteItinerary(itinerary.id);
//           if (mounted) Navigator.pop(c);
//         }, child: const Text('刪除', style: TextStyle(color: Colors.red))),
//       ],
//     ));
//   }
//
//   String _convertDriveUrl(String url) {
//     if (url.contains('drive.google.com')) {
//       if (url.contains('id=')) {
//         final id = url.split('id=')[1].split('&')[0];
//         return 'https://drive.google.com/uc?export=view&id=$id';
//       } else if (url.contains('/file/d/')) {
//         final id = url.split('/file/d/')[1].split('/')[0];
//         return 'https://drive.google.com/uc?export=view&id=$id';
//       }
//     }
//     return url;
//   }
// }
