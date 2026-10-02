import 'package:cloud_firestore/cloud_firestore.dart';

class Spot {
  final String id;
  final String name;
  final String category;
  final String description;
  final String address;
  final GeoPoint geoPoint;
  final String openHours;
  final String phone;
  final double averageRating;
  final List<String> images;
  final List<String> tags;
  final DateTime updatedAt;

  Spot({
    required this.id,
    required this.name,
    required this.category,
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

  factory Spot.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // 相容性處理：如果只有 image_url (String)，則轉為 List
    List<String> imageList = [];
    if (data['images'] != null) {
      imageList = List<String>.from(data['images']);
    } else if (data['image_url'] != null) {
      imageList = [data['image_url'] as String];
    }

    return Spot(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      // 💡 優先讀取 latlng 欄位，若無則讀取 geoPoint
      geoPoint: data['latlng'] ?? data['geoPoint'] ?? const GeoPoint(23.4811, 120.4497),
      openHours: data['openHours'] ?? '',
      phone: data['phone'] ?? '',
      averageRating: (data['rating'] ?? 0.0).toDouble(),
      images: imageList,
      tags: List<String>.from(data['tags'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
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
