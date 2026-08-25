import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';

class FavoritesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _favoritesRef(String uid) =>
      _firestore.collection(FirestorePaths.favorites).doc(uid).collection(FirestorePaths.items);

  Future<void> _updateFavoritesCount(String productId, int delta) async {
    try {
      final productRef = _firestore.collection(FirestorePaths.products).doc(productId);
      final productDoc = await productRef.get();
      if (productDoc.exists) {
        await productRef.update({
          'favoritesCount': FieldValue.increment(delta),
        });
      }
    } catch (e) {
      debugPrint('Warning: Could not update favoritesCount for product $productId: $e');
    }
  }

  Future<void> toggleFavorite(String uid, String productId, Map<String, dynamic> productSnapshot) async {
    final ref = _favoritesRef(uid).doc(productId);
    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();
      await _updateFavoritesCount(productId, -1);
    } else {
      await ref.set({
        'productId': productId,
        'savedAt': FieldValue.serverTimestamp(),
        'productSnapshot': productSnapshot,
      });
      await _updateFavoritesCount(productId, 1);
    }
  }

  Future<void> removeFavorite(String uid, String productId) async {
    final ref = _favoritesRef(uid).doc(productId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
      await _updateFavoritesCount(productId, -1);
    }
  }

  Future<void> clearAllFavorites(String uid) async {
    final snapshot = await _favoritesRef(uid).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
      try {
        final productId = doc.id;
        final productRef = _firestore.collection(FirestorePaths.products).doc(productId);
        final productDoc = await productRef.get();
        if (productDoc.exists) {
          batch.update(productRef, {
            'favoritesCount': FieldValue.increment(-1),
          });
        }
      } catch (_) {}
    }
    await batch.commit();
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
