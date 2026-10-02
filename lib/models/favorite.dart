import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  final String id;
  final String uid;
  final String targetType; // spot, food, hotel
  final String targetId;
  final DateTime createdAt;

  Favorite({
    required this.id,
    required this.uid,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  factory Favorite.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Favorite(
      id: doc.id,
      uid: data['uid'] ?? '',
      targetType: data['targetType'] ?? '',
      targetId: data['targetId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'targetType': targetType,
      'targetId': targetId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
