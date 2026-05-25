import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../repositories/favorites_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesRepository _favoritesRepo = FavoritesRepository();
  final String uid;

  List<String> _favoriteIds = [];
  List<ProductModel> _favoriteProducts = [];
  bool _isLoading = false;

  List<String> get favoriteIds => _favoriteIds;
  List<ProductModel> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;

  FavoritesProvider({required this.uid}) {
    _favoritesRepo.getFavoriteIds(uid).listen((ids) async {
      _favoriteIds = ids;
      await _fetchFavoriteProducts();
      notifyListeners();
    });
  }

  Future<void> _fetchFavoriteProducts() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshots = await _favoritesRepo.getFavoriteProductSnapshots(uid);
      
      _favoriteProducts = snapshots.map((item) {
        final productSnapshot = item['productSnapshot'] as Map<String, dynamic>;
        return ProductModel(
          id: item['id'] as String,
          title: productSnapshot['title'] ?? '',
          price: (productSnapshot['price'] as num?)?.toDouble() ?? 0,
          category: productSnapshot['category'] ?? '',
          condition: productSnapshot['condition'] ?? '',
          sellerId: productSnapshot['sellerId'] ?? '',
          sellerType: productSnapshot['sellerType'] ?? 'Personal',
          createdAt: (productSnapshot['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          location: productSnapshot['location'] ?? '',
          imageUrls: List<String>.from(productSnapshot['imageUrls'] ?? []),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching favorite products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<void> toggleFavorite(ProductModel product) async {
    await _favoritesRepo.toggleFavorite(uid, product.id, product.toFirestore());
  }

  Future<void> clearFavorites() async {
    for (var id in _favoriteIds) {
      await _favoritesRepo.toggleFavorite(uid, id, {});
    }
  }
}
