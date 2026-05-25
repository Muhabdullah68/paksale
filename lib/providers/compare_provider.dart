import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CompareProvider extends ChangeNotifier {
  final List<ProductModel> _compareList = [];
  List<ProductModel> get compareList => List.unmodifiable(_compareList);

  bool isInCompare(String id) => _compareList.any((p) => p.id == id);

  bool toggleCompare(ProductModel product) {
    if (isInCompare(product.id)) {
      _compareList.removeWhere((p) => p.id == product.id);
      notifyListeners();
      return false;
    } else {
      if (_compareList.length >= 3) return false;
      _compareList.add(product);
      notifyListeners();
      return true;
    }
  }

  void removeFromCompare(String id) {
    _compareList.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void clearCompare() {
    _compareList.clear();
    notifyListeners();
  }
}
