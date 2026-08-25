import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacySettings {
  final String contactPreference; // 'everyone', 'verified_only', 'women_only', 'nobody'
  final String phoneVisibility;    // 'nobody', 'approved', 'contacts'
  final String locationPrecision;  // 'city', 'area', 'approximate', 'exact'
  final bool allowCalls;
  final bool showGender;
  final bool showProfilePhoto;
  final bool anonymousProfile;
  final bool quietMode;

  const PrivacySettings({
    this.contactPreference = 'everyone',
    this.phoneVisibility = 'nobody',
    this.locationPrecision = 'city',
    this.allowCalls = false,
    this.showGender = false,
    this.showProfilePhoto = true,
    this.anonymousProfile = false,
    this.quietMode = false,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PrivacySettings();
    return PrivacySettings(
      contactPreference: map['contactPreference'] ?? 'everyone',
      phoneVisibility: map['phoneVisibility'] ?? 'nobody',
      locationPrecision: map['locationPrecision'] ?? 'city',
      allowCalls: map['allowCalls'] ?? false,
      showGender: map['showGender'] ?? false,
      showProfilePhoto: map['showProfilePhoto'] ?? true,
      anonymousProfile: map['anonymousProfile'] ?? false,
      quietMode: map['quietMode'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'contactPreference': contactPreference,
    'phoneVisibility': phoneVisibility,
    'locationPrecision': locationPrecision,
    'allowCalls': allowCalls,
    'showGender': showGender,
    'showProfilePhoto': showProfilePhoto,
    'anonymousProfile': anonymousProfile,
    'quietMode': quietMode,
  };

  PrivacySettings copyWith({
    String? contactPreference,
    String? phoneVisibility,
    String? locationPrecision,
    bool? allowCalls,
    bool? showGender,
    bool? showProfilePhoto,
    bool? anonymousProfile,
    bool? quietMode,
  }) {
    return PrivacySettings(
      contactPreference: contactPreference ?? this.contactPreference,
      phoneVisibility: phoneVisibility ?? this.phoneVisibility,
      locationPrecision: locationPrecision ?? this.locationPrecision,
      allowCalls: allowCalls ?? this.allowCalls,
      showGender: showGender ?? this.showGender,
      showProfilePhoto: showProfilePhoto ?? this.showProfilePhoto,
      anonymousProfile: anonymousProfile ?? this.anonymousProfile,
      quietMode: quietMode ?? this.quietMode,
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? nicNumber;
  final String phone;
  final String whatsAppNumber;
  final String photoUrl;
  final String avatarUrl;
  final bool isVerified;
  final String sellerTier;
  final bool isBusinessSeller;
  final bool isAdminApproved;
  final String idVerificationStatus;
  final String city;
  final String village;
  final int activeAdsCount;
  final int totalViews;
  final double rating;
  final bool isSuspended;
  final bool isAdmin;
  final PrivacySettings privacy;
  // Signup origin: 'web' | 'app'. Legacy accounts (no field) read as 'both'.
  final String platform;
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
    this.privacy = const PrivacySettings(),
    this.platform = 'both',
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
      privacy: PrivacySettings.fromMap(data['privacy']),
      platform: data['platform'] ?? 'both',
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
      'privacy': privacy.toMap(),
      'platform': platform,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? id, String? name, String? email, String? nicNumber, String? phone, String? whatsAppNumber,
    String? photoUrl, String? avatarUrl, bool? isVerified, String? sellerTier,
    bool? isBusinessSeller, bool? isAdminApproved, String? idVerificationStatus,
    String? city, String? village, int? activeAdsCount, int? totalViews,
    double? rating, bool? isSuspended, bool? isAdmin, PrivacySettings? privacy, DateTime? createdAt,
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
    privacy: privacy ?? this.privacy,
    createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayLocation {
    if (village.isNotEmpty) return '$city, $village';
    return city;
  }
}
