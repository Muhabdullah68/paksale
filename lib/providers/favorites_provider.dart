import 'dart:async';
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
  StreamSubscription<List<String>>? _idsSubscription;

  List<String> get favoriteIds => _favoriteIds;
  List<ProductModel> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;

  FavoritesProvider({required this.uid}) {
    _idsSubscription = _favoritesRepo.getFavoriteIds(uid).listen((ids) async {
      _favoriteIds = ids;
      await _fetchFavoriteProducts();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to favorite IDs: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _idsSubscription?.cancel();
    _idsSubscription = null;
    super.dispose();
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
          currency: productSnapshot['currency'] ?? 'Rs.',
          category: productSnapshot['category'] ?? '',
          subCategory: productSnapshot['subCategory'] ?? '',
          condition: productSnapshot['condition'] ?? '',
          sellerId: productSnapshot['sellerId'] ?? '',
          sellerType: productSnapshot['sellerType'] ?? 'Personal',
          sellerName: productSnapshot['sellerName'] ?? 'Anonymous',
          sellerAvatarUrl: productSnapshot['sellerAvatarUrl'] ?? '',
          createdAt: (productSnapshot['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          location: productSnapshot['location'] ?? '',
          city: productSnapshot['city'] ?? '',
          village: productSnapshot['village'] ?? '',
          description: productSnapshot['description'] ?? '',
          views: (productSnapshot['views'] as int?) ?? 0,
          favoritesCount: (productSnapshot['favoritesCount'] as int?) ?? 0,
          isFeatured: productSnapshot['isFeatured'] as bool? ?? false,
          isBoosted: productSnapshot['isBoosted'] as bool? ?? false,
          isSold: productSnapshot['isSold'] as bool? ?? false,
          isActive: productSnapshot['isActive'] as bool? ?? true,
          isVerifiedSeller: productSnapshot['isVerifiedSeller'] as bool? ?? false,
          specifications: Map<String, String>.from(productSnapshot['specifications'] as Map? ?? {}),
          imageUrls: List<String>.from(productSnapshot['imageUrls'] ?? []),
          isAuction: productSnapshot['isAuction'] as bool? ?? false,
          acceptsCOD: productSnapshot['acceptsCOD'] as bool? ?? false,
          isJob: productSnapshot['isJob'] as bool? ?? false,
          status: productSnapshot['status'] as String? ?? 'approved',
          platform: productSnapshot['platform'] as String? ?? 'both',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching favorite products: $e');
      _favoriteProducts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<bool> toggleFavorite(ProductModel product) async {
    try {
      await _favoritesRepo.toggleFavorite(uid, product.id, product.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }

  Future<void> removeFavorite(String productId) async {
    try {
      await _favoritesRepo.removeFavorite(uid, productId);
    } catch (e) {
      debugPrint('Error removing favorite: $e');
    }
  }

  Future<void> clearFavorites() async {
    try {
      await _favoritesRepo.clearAllFavorites(uid);
      _favoriteIds = [];
      _favoriteProducts = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
    }
  }
}
