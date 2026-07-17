import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? nicNumber;
  final String phone;
  final String whatsAppNumber; // NEW
  final String photoUrl;
  final String avatarUrl;
  final bool isVerified;
  final String sellerTier; // NEW: 'free', 'verified', 'premium'
  final bool isBusinessSeller; // NEW
  final bool isAdminApproved; // NEW: for business sellers
  final String idVerificationStatus; // NEW: 'none', 'pending', 'verified', 'rejected'
  final String city; // NEW
  final String village; // NEW
  final int activeAdsCount;
  final int totalViews;
  final double rating;
  final bool isSuspended; // NEW
  final bool isAdmin; // NEW
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.nicNumber,
    this.phone = '',
    this.whatsAppNumber = '',
    this.photoUrl = '',
    this.avatarUrl = '',
    this.isVerified = false,
    this.sellerTier = 'free',
    this.isBusinessSeller = false,
    this.isAdminApproved = false,
    this.idVerificationStatus = 'none',
    this.city = '',
    this.village = '',
    this.activeAdsCount = 0,
    this.totalViews = 0,
    this.rating = 0.0,
    this.isSuspended = false,
    this.isAdmin = false,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      nicNumber: data['nicNumber'],
      phone: data['phone'] ?? '',
      whatsAppNumber: data['whatsAppNumber'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      isVerified: data['isVerified'] ?? false,
      sellerTier: data['sellerTier'] ?? 'free',
      isBusinessSeller: data['isBusinessSeller'] ?? false,
      isAdminApproved: data['isAdminApproved'] ?? false,
      idVerificationStatus: data['idVerificationStatus'] ?? 'none',
      city: data['city'] ?? '',
      village: data['village'] ?? '',
      activeAdsCount: data['activeAdsCount'] ?? 0,
      totalViews: data['totalViews'] ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      isSuspended: data['isSuspended'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'nicNumber': nicNumber,
      'phone': phone,
      'whatsAppNumber': whatsAppNumber,
      'photoUrl': photoUrl,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'sellerTier': sellerTier,
      'isBusinessSeller': isBusinessSeller,
      'isAdminApproved': isAdminApproved,
      'idVerificationStatus': idVerificationStatus,
      'city': city,
      'village': village,
      'activeAdsCount': activeAdsCount,
      'totalViews': totalViews,
      'rating': rating,
      'isSuspended': isSuspended,
      'isAdmin': isAdmin,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? id, String? name, String? email, String? nicNumber, String? phone, String? whatsAppNumber,
    String? photoUrl, String? avatarUrl, bool? isVerified, String? sellerTier,
    bool? isBusinessSeller, bool? isAdminApproved, String? idVerificationStatus,
    String? city, String? village, int? activeAdsCount, int? totalViews,
    double? rating, bool? isSuspended, bool? isAdmin, DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      nicNumber: nicNumber ?? this.nicNumber,
      phone: phone ?? this.phone,
      whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
    photoUrl: photoUrl ?? this.photoUrl,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    isVerified: isVerified ?? this.isVerified,
    sellerTier: sellerTier ?? this.sellerTier,
    isBusinessSeller: isBusinessSeller ?? this.isBusinessSeller,
    isAdminApproved: isAdminApproved ?? this.isAdminApproved,
    idVerificationStatus: idVerificationStatus ?? this.idVerificationStatus,
    city: city ?? this.city,
    village: village ?? this.village,
    activeAdsCount: activeAdsCount ?? this.activeAdsCount,
    totalViews: totalViews ?? this.totalViews,
    rating: rating ?? this.rating,
    isSuspended: isSuspended ?? this.isSuspended,
    isAdmin: isAdmin ?? this.isAdmin,
    createdAt: createdAt ?? this.createdAt,
    );
  }
}
