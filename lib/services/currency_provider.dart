import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider extends ChangeNotifier {
  static const String _key = 'selected_currency';
  String _selectedCurrency = 'Rs.';
  
  String get selectedCurrency => _selectedCurrency;

  CurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString(_key) ?? 'Rs.';
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    if (_selectedCurrency == currency) return;
    _selectedCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, currency);
    notifyListeners();
  }

  String formatPrice(double price) {
    final fmt = price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$fmt $_selectedCurrency';
  }
}
