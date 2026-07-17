import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repo = OrderRepository();

  List<OrderModel> _buyerOrders = [];
  List<OrderModel> _sellerOrders = [];
  bool _isLoading = false;

  List<OrderModel> get buyerOrders => _buyerOrders;
  List<OrderModel> get sellerOrders => _sellerOrders;
  bool get isLoading => _isLoading;

  Future<void> fetchBuyerOrders(String buyerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _buyerOrders = await _repo.getOrdersByBuyer(buyerId);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSellerOrders(String sellerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _sellerOrders = await _repo.getOrdersBySeller(sellerId);
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Stream<QuerySnapshot> getAllOrdersStream() => _repo.getAllOrdersStream();

  Future<void> placeOrder(OrderModel order) async {
    await _repo.createOrder(order);
    _buyerOrders.insert(0, order.copyWith(id: order.id));
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _repo.updateOrderStatus(orderId, status);
    final bIdx = _buyerOrders.indexWhere((o) => o.id == orderId);
    if (bIdx != -1) {
      _buyerOrders[bIdx] = _buyerOrders[bIdx].copyWith(
        status: status,
        deliveredAt: status == 'delivered' ? DateTime.now() : null,
      );
    }
    final sIdx = _sellerOrders.indexWhere((o) => o.id == orderId);
    if (sIdx != -1) {
      _sellerOrders[sIdx] = _sellerOrders[sIdx].copyWith(
        status: status,
        deliveredAt: status == 'delivered' ? DateTime.now() : null,
      );
    }
    notifyListeners();
  }
}
