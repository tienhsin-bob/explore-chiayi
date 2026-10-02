import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String name;
  final String type;
  final String description;
  final String address;
  final GeoPoint geoPoint;
  final String openHours;
  final String phone;
  final double averageRating;
  final List<String> images;
  final List<String> tags;
  final DateTime updatedAt;

  Food({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.address,
    required this.geoPoint,
    required this.openHours,
    required this.phone,
    required this.averageRating,
    required this.images,
    required this.tags,
    required this.updatedAt,
  });

  factory Food.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Food(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      // 💡 優先讀取 latlng 欄位，若無則讀取 geoPoint，預設為嘉義中心
      geoPoint: data['latlng'] ?? data['geoPoint'] ?? const GeoPoint(23.4811, 120.4497),
      openHours: data['openHours'] ?? '',
      phone: data['phone'] ?? '',
      averageRating: (data['rating'] ?? 0.0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'address': address,
      'geoPoint': geoPoint,
      'openHours': openHours,
      'phone': phone,
      'averageRating': averageRating,
      'images': images,
      'tags': tags,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}