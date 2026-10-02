import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spot.dart';
import '../models/food.dart';
import '../models/hotel.dart';
import '../models/news.dart';
import '../models/app_user.dart';
import '../models/favorite.dart';
import '../models/itinerary.dart';

class FirestoreDatabase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 使用者 (Users) ---
  Future<void> saveUserData(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Stream<AppUser?> getUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      return doc.exists ? AppUser.fromFirestore(doc) : null;
    });
  }

  // --- 景點 (Spots) ---
  Stream<List<Spot>> getSpots() {
    return _db.collection('spots').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Spot.fromFirestore(doc)).toList();
    });
  }

  Future<Spot?> getSpot(String id) async {
    final doc = await _db.collection('spots').doc(id).get();
    return doc.exists ? Spot.fromFirestore(doc) : null;
  }

  // --- 美食 (Foods) ---
  Stream<List<Food>> getFoods() {
    return _db.collection('foods').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Food.fromFirestore(doc)).toList();
    });
  }

  Future<Food?> getFood(String id) async {
    final doc = await _db.collection('foods').doc(id).get();
    return doc.exists ? Food.fromFirestore(doc) : null;
  }

  // --- 消息 (News) ---
  Stream<List<News>> getNews() {
    return _db
        .collection('news')
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => News.fromFirestore(doc)).toList();
    });
  }

  // --- 收藏 (Favorites) ---
  Future<void> toggleFavorite(String uid, String targetType, String targetId) async {
    final collection = _db.collection('favorites');
    final query = await collection
        .where('uid', isEqualTo: uid)
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .get();

    if (query.docs.isEmpty) {
      await collection.add({
        'uid': uid,
        'targetType': targetType,
        'targetId': targetId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      for (var doc in query.docs) {
        await doc.reference.delete();
      }
    }
  }

  Stream<List<Favorite>> getUserFavorites(String uid) {
    return _db
        .collection('favorites')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Favorite.fromFirestore(doc)).toList();
    });
  }

  // --- 行程 (Itineraries) ---
  Stream<List<Itinerary>> getUserItineraries(String uid) {
    return _db
        .collection('itineraries')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Itinerary.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String> saveItinerary(Itinerary itinerary) async {
    if (itinerary.id.isEmpty) {
      final docRef = await _db.collection('itineraries').add(itinerary.toMap());
      return docRef.id;
    } else {
      await _db.collection('itineraries').doc(itinerary.id).set(itinerary.toMap(), SetOptions(merge: true));
      return itinerary.id;
    }
  }

  Future<void> deleteItinerary(String id) async {
    await _db.collection('itineraries').doc(id).delete();
  }

  Future<void> addItemToItinerary(String uid, ItineraryItem item, {String? itineraryId}) async {
    final collection = _db.collection('itineraries');
    
    if (itineraryId == null || itineraryId.isEmpty) {
      final query = await collection.where('uid', isEqualTo: uid).limit(1).get();
      if (query.docs.isEmpty) {
        await collection.add({
          'uid': uid,
          'title': '我的嘉義行程',
          'items': [item.toMap()],
          'createdAt': FieldValue.serverTimestamp(),
          'dateRange': '未定日期',
        });
        return;
      }
      itineraryId = query.docs.first.id;
    }

    await collection.doc(itineraryId).update({
      'items': FieldValue.arrayUnion([item.toMap()])
    });
  }
}
