import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String productId;
  final String productTitle;
  final String productImage;
  final double price;
  final String currency;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String? buyerAddress;
  final String deliveryLocation;
  final String? contactNumber;
  final String status; // pending | confirmed | shipped | delivered | cancelled
  // Ordering surface: 'web' | 'app'. Legacy orders (no field) read as 'both'.
  final String platform;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    this.productImage = '',
    required this.price,
    this.currency = 'Rs.',
    required this.sellerId,
    this.sellerName = '',
    this.sellerPhone = '',
    required this.buyerId,
    this.buyerName = '',
    this.buyerPhone = '',
    this.buyerAddress,
    this.deliveryLocation = '',
    this.contactNumber,
    this.status = 'pending',
    this.platform = 'both',
    required this.createdAt,
    this.deliveredAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      productId: d['productId'] ?? '',
      productTitle: d['productTitle'] ?? '',
      productImage: d['productImage'] ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0,
      currency: d['currency'] ?? 'Rs.',
      sellerId: d['sellerId'] ?? '',
      sellerName: d['sellerName'] ?? '',
      sellerPhone: d['sellerPhone'] ?? '',
      buyerId: d['buyerId'] ?? '',
      buyerName: d['buyerName'] ?? '',
      buyerPhone: d['buyerPhone'] ?? '',
      buyerAddress: d['buyerAddress'],
      deliveryLocation: d['deliveryLocation'] ?? '',
      contactNumber: d['contactNumber'],
      status: d['status'] ?? 'pending',
      platform: d['platform'] ?? 'both',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (d['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'productId': productId,
    'productTitle': productTitle,
    'productImage': productImage,
    'price': price,
    'currency': currency,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'sellerPhone': sellerPhone,
    'buyerId': buyerId,
    'buyerName': buyerName,
    'buyerPhone': buyerPhone,
    'buyerAddress': buyerAddress,
    'deliveryLocation': deliveryLocation,
    'contactNumber': contactNumber,
    'status': status,
    'platform': platform,
    'createdAt': Timestamp.fromDate(createdAt),
    'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
  };

  OrderModel copyWith({
    String? id, String? productId, String? productTitle, String? productImage,
    double? price, String? currency, String? sellerId, String? sellerName,
    String? sellerPhone, String? buyerId, String? buyerName, String? buyerPhone,
    String? buyerAddress, String? deliveryLocation, String? contactNumber,
    String? status, DateTime? createdAt, DateTime? deliveredAt, String? platform,
  }) => OrderModel(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    productTitle: productTitle ?? this.productTitle,
    productImage: productImage ?? this.productImage,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    sellerId: sellerId ?? this.sellerId,
    sellerName: sellerName ?? this.sellerName,
    sellerPhone: sellerPhone ?? this.sellerPhone,
    buyerId: buyerId ?? this.buyerId,
    buyerName: buyerName ?? this.buyerName,
    buyerPhone: buyerPhone ?? this.buyerPhone,
    buyerAddress: buyerAddress ?? this.buyerAddress,
    deliveryLocation: deliveryLocation ?? this.deliveryLocation,
    contactNumber: contactNumber ?? this.contactNumber,
    status: status ?? this.status,
    platform: platform ?? this.platform,
    createdAt: createdAt ?? this.createdAt,
    deliveredAt: deliveredAt ?? this.deliveredAt,
  );
}
