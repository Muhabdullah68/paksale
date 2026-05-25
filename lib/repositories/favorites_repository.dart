import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';

class FavoritesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _favoritesRef(String uid) =>
      _firestore.collection(FirestorePaths.favorites).doc(uid).collection(FirestorePaths.items);

  Future<void> toggleFavorite(String uid, String productId, Map<String, dynamic> productSnapshot) async {
    final ref = _favoritesRef(uid).doc(productId);
    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();
      // Optionally decrement favoritesCount on product doc
      await _firestore.collection(FirestorePaths.products).doc(productId).update({
        'favoritesCount': FieldValue.increment(-1),
      });
    } else {
      await ref.set({
        'productId': productId,
        'savedAt': FieldValue.serverTimestamp(),
        'productSnapshot': productSnapshot,
      });
      // Increment favoritesCount on product doc
      await _firestore.collection(FirestorePaths.products).doc(productId).update({
        'favoritesCount': FieldValue.increment(1),
      });
    }
  }

  Stream<List<String>> getFavoriteIds(String uid) {
    return _favoritesRef(uid).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<List<Map<String, dynamic>>> getFavoriteProductSnapshots(String uid) async {
    final snapshot = await _favoritesRef(uid).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'productSnapshot': data['productSnapshot'] as Map<String, dynamic>?,
      };
    }).where((item) => item['productSnapshot'] != null).toList();
  }
}
