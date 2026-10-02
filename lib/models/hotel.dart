import 'package:cloud_firestore/cloud_firestore.dart';

class Hotel {
  final String id;
  final String name;
  final String type;
  final String description;
  final String address;
  final GeoPoint geoPoint;
  final String phone;
  final String priceRange;
  final double averageRating;
  final List<String> images;
  final List<String> facilities;
  final DateTime updatedAt;

  Hotel({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.address,
    required this.geoPoint,
    required this.phone,
    required this.priceRange,
    required this.averageRating,
    required this.images,
    required this.facilities,
    required this.updatedAt,
  });

  factory Hotel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Hotel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      geoPoint: data['geoPoint'] ?? const GeoPoint(0, 0),
      phone: data['phone'] ?? '',
      priceRange: data['priceRange'] ?? '',
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      facilities: List<String>.from(data['facilities'] ?? []),
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
      'phone': phone,
      'priceRange': priceRange,
      'averageRating': averageRating,
      'images': images,
      'facilities': facilities,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
