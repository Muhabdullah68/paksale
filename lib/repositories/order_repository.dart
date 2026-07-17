import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _ordersRef => _firestore.collection('cod_orders');

  Future<void> createOrder(OrderModel order) async {
    final docRef = _ordersRef.doc();
    final newOrder = order.copyWith(id: docRef.id);
    await docRef.set(newOrder.toFirestore());
  }

  Future<List<OrderModel>> getOrdersByBuyer(String buyerId) async {
    final snapshot = await _ordersRef
        .where('buyerId', isEqualTo: buyerId)
        .get();
    final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<List<OrderModel>> getOrdersBySeller(String sellerId) async {
    final snapshot = await _ordersRef
        .where('sellerId', isEqualTo: sellerId)
        .get();
    final orders = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _ordersRef.doc(orderId).update({
      'status': status,
      if (status == 'delivered') 'deliveredAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getAllOrdersStream() {
    return _ordersRef.orderBy('createdAt', descending: true).snapshots();
  }
}
