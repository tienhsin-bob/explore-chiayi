import 'package:cloud_firestore/cloud_firestore.dart';

class ItineraryItem {
  final String id;
  final String name;
  final String type; 
  final GeoPoint geoPoint;
  final String imageUrl;
  final String? startTime;
  final String? stayDuration;
  final int day; // 💡 新增：哪一天 (1, 2, 3...)
  final String? transportMode; // 💡 新增：交通方式 (car, walk)
  final String? travelTime; // 💡 新增：交通時間 (約 10 分鐘)

  ItineraryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.geoPoint,
    required this.imageUrl,
    this.startTime,
    this.stayDuration,
    this.day = 1,
    this.transportMode,
    this.travelTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'geoPoint': geoPoint,
      'imageUrl': imageUrl,
      'startTime': startTime,
      'stayDuration': stayDuration,
      'day': day,
      'transportMode': transportMode,
      'travelTime': travelTime,
    };
  }

  factory ItineraryItem.fromMap(Map<String, dynamic> map) {
    return ItineraryItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      geoPoint: map['geoPoint'] ?? const GeoPoint(0, 0),
      imageUrl: map['imageUrl'] ?? '',
      startTime: map['startTime'],
      stayDuration: map['stayDuration'],
      day: map['day'] ?? 1,
      transportMode: map['transportMode'],
      travelTime: map['travelTime'],
    );
  }
}

class Itinerary {
  final String id;
  final String uid;
  final String title;
  final String dateRange;
  final List<ItineraryItem> items;
  final DateTime createdAt;

  Itinerary({
    required this.id,
    required this.uid,
    required this.title,
    required this.dateRange,
    required this.items,
    required this.createdAt,
  });

  factory Itinerary.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Itinerary(
      id: doc.id,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '我的行程',
      dateRange: data['dateRange'] ?? '未定日期',
      items: (data['items'] as List? ?? [])
          .map((item) => ItineraryItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'dateRange': dateRange,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
