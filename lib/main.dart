import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QatarSale Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

// Global state using ChangeNotifier for reactive updates
class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final List<ProductModel> _favorites = [];
  List<ProductModel> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(String id) => _favorites.any((p) => p.id == id);

  void toggleFavorite(ProductModel product) {
    if (isFavorite(product.id)) {
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      _favorites.add(product.copyWith(isFavorite: true));
    }
    notifyListeners(); // Notify listeners of change
  }

  void removeFavorite(String id) {
    _favorites.removeWhere((p) => p.id == id);
    notifyListeners();
  }

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

  final List<ProductModel> _myAds = [];
  List<ProductModel> get myAds => List.unmodifiable(_myAds);

  void addMyAd(ProductModel product) {
    _myAds.add(product);
    notifyListeners();
  }

  void removeMyAd(String id) {
    _myAds.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}