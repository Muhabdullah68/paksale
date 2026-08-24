import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/product_model.dart';
import '../core/constants/firestore_paths.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Platforms whose listings are visible on this surface.
  /// Web sees 'web'+'both'; mobile app sees 'app'+'both'.
  /// Applied client-side to keep paginated queries free of extra
  /// composite-index requirements. Legacy docs default to 'both'.
  static bool matchesPlatform(String platform) =>
      platform == 'both' || platform == (kIsWeb ? 'web' : 'app');

  CollectionReference get _productsRef =>
      _firestore.collection(FirestorePaths.products);

  Future<List<ProductModel>> getProducts({
    String? category,
    String? sellerId,
    bool featuredOnly = false,
    DocumentSnapshot? lastDocument,
    int limit = 10,
    String? status = 'approved', // Default to approved
  }) async {
    Query query = _productsRef.where('isActive', isEqualTo: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    if (sellerId != null) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }

    if (featuredOnly) {
      query = query.where('isFeatured', isEqualTo: true);
    }

    // Always sort by creation time for consistent pagination
    query = query.orderBy('createdAt', descending: true);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .where((p) => matchesPlatform(p.platform))
        .toList();
  }

  Future<QuerySnapshot> getProductsSnapshot({
    String? category,
    String? sellerId,
    bool featuredOnly = false,
    DocumentSnapshot? lastDocument,
    int limit = 10,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? status = 'approved', // Default to approved
  }) async {
    Query query = _productsRef.where('isActive', isEqualTo: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    if (sellerId != null) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }

    if (featuredOnly) {
      query = query.where('isFeatured', isEqualTo: true);
    }

    if (condition != null) {
      query = query.where('condition', isEqualTo: condition);
    }

    if (location != null && location != 'All') {
      query = query.where('location', isEqualTo: location);
    }

    // Note: Price range queries with multiple filters might require Firestore indexes
    if (minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }

    query = query.orderBy('createdAt', descending: true);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    return await query.get();
  }

  Future<ProductModel?> getProductById(String id) async {
    final doc = await _productsRef.doc(id).get();
    if (doc.exists) {
      return ProductModel.fromFirestore(doc);
    }
    return null;
  }

  DocumentReference getNewDocRef() {
    return _productsRef.doc();
  }

  Future<void> createProduct(ProductModel product) async {
    final docRef = _productsRef.doc();
    final newProduct = product.copyWith(id: docRef.id);
    await docRef.set(newProduct.toFirestore());
  }

  Future<void> createProductWithId(ProductModel product) async {
    await _productsRef.doc(product.id).set(product.toFirestore());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _productsRef.doc(product.id).update(product.toFirestore());
  }

  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }

  Future<void> incrementViews(String id) async {
    await _productsRef.doc(id).update({
      'views': FieldValue.increment(1),
    });
  }

  Future<List<ProductModel>> getProductsByUser(String userId, {bool approvedOnly = false}) async {
    Query query = _productsRef.where('sellerId', isEqualTo: userId);
    if (approvedOnly) {
      query = query.where('status', isEqualTo: 'approved');
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  Future<void> blockProduct(String id, bool block) async {
    await _productsRef.doc(id).update({'isActive': !block});
  }
}
