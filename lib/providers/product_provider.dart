import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';
import '../services/storage_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _productRepo = ProductRepository();
  final StorageService _storageService = StorageService();

  List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _userProducts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  DocumentSnapshot? _lastDocument;

  List<ProductModel> get products => _products;
  List<ProductModel> get featuredProducts => _featuredProducts;
  List<ProductModel> get userProducts => _userProducts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> fetchProducts({
    String? category,
    bool refresh = true,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? location,
  }) async {
    if (refresh) {
      _setLoading(true);
      _products = [];
      _lastDocument = null;
      _hasMore = true;
    } else {
      if (!_hasMore || _isLoadingMore) return;
      _setLoadingMore(true);
    }

    try {
      final snapshot = await _productRepo.getProductsSnapshot(
        category: category,
        lastDocument: _lastDocument,
        limit: 10,
        condition: condition,
        minPrice: minPrice,
        maxPrice: maxPrice,
        location: location,
      );

      final newProducts = snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
      
      if (refresh) {
        _products = newProducts;
        

      } else {
        _products.addAll(newProducts);
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      
      _hasMore = newProducts.length == 10;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
      _setLoadingMore(false);
    }
  }

  Future<void> fetchFeaturedProducts() async {
    _setLoading(true);
    try {
      _featuredProducts = await _productRepo.getProducts(featuredOnly: true);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addProduct(ProductModel product, List<XFile> images) async {
    _setLoading(true);
    try {
      // Generate the document reference first to get the final ID
      final docRef = _productRepo.getNewDocRef();
      final String productId = docRef.id;
      
      List<String> imageUrls = [];
      for (var image in images) {
        final url = await _storageService.uploadProductImage(productId, image);
        imageUrls.add(url);
      }

      final productWithImages = product.copyWith(
        id: productId,
        imageUrls: imageUrls,
      );

      await _productRepo.createProductWithId(productWithImages);
      await fetchProducts();
      // Update user products list as well
      if (_userProducts.isNotEmpty && product.sellerId.isNotEmpty) {
        _userProducts.insert(0, productWithImages);
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProduct(ProductModel product, List<XFile> newImages) async {
    _setLoading(true);
    try {
      List<String> imageUrls = List.from(product.imageUrls);
      
      // Upload new images if any
      for (var image in newImages) {
        final url = await _storageService.uploadProductImage(product.id, image);
        imageUrls.add(url);
      }

      final updatedProduct = product.copyWith(
        imageUrls: imageUrls,
      );

      await _productRepo.updateProduct(updatedProduct);
      await fetchProducts();
      // Update user products list as well
      final userIdx = _userProducts.indexWhere((p) => p.id == product.id);
      if (userIdx != -1) {
        _userProducts[userIdx] = updatedProduct;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _productRepo.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _userProducts.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> incrementViews(String id) async {
    try {
      await _productRepo.incrementViews(id);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = _products[index].copyWith(views: _products[index].views + 1);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  List<ProductModel> getMyAds(String userId) {
    return _userProducts.isEmpty 
        ? _products.where((p) => p.sellerId == userId).toList()
        : _userProducts;
  }

  Future<void> fetchUserProducts(String userId) async {
    _setLoading(true);
    try {
      _userProducts = await _productRepo.getProductsByUser(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  List<ProductModel> _allProducts = [];
  List<ProductModel> get allProducts => _allProducts;

  Future<void> fetchAllProductsForAdmin({String? status}) async {
    _setLoading(true);
    try {
      _allProducts = await _productRepo.getProducts(status: status, limit: 100);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProductStatus(String productId, String status) async {
    try {
      final product = await _productRepo.getProductById(productId);
      if (product != null) {
        final updated = product.copyWith(status: status);
        await _productRepo.updateProduct(updated);
        
        // Update local list
        final idx = _allProducts.indexWhere((p) => p.id == productId);
        if (idx != -1) {
          _allProducts[idx] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<ProductModel?> fetchProductById(String id) async {
    try {
      return await _productRepo.getProductById(id);
    } catch (e) {
      debugPrint('Error fetching product by id: $e');
      return null;
    }
  }

  void clearUserProducts() {
    _userProducts = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setLoadingMore(bool value) {
    _isLoadingMore = value;
    notifyListeners();
  }
}
