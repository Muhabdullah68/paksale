import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String title;
  final double price;
  final String currency;
  final String category;
  final String subCategory;
  final String condition;
  final String sellerType;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final String whatsAppNumber;
  final String sellerAvatarUrl;
  final String sellerTier; // NEW
  final String location;
  final String city; // NEW
  final String village; // NEW
  final String description;
  final int views;
  final int favoritesCount;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? boostExpiresAt; // NEW
  final bool isFavorite;
  final bool isFeatured;
  final bool isBoosted; // NEW
  final bool isSold;
  final String? soldLocation; // NEW
  final String? buyerNic; // NEW: Required if price > 20k
  final bool isActive;
  final bool isVerifiedSeller;
  final Map<String, String> specifications;
  final List<String> imageUrls;

  // ── Bidding / Auction Fields (Simplified or legacy) ──────────────────────
  final bool isAuction;
  final double? currentBid;
  final String? lastBidderId;
  final DateTime? auctionEndTime;
  final List<Map<String, dynamic>> bidHistory;

  // ── Cash on Delivery Fields ──────────────────────────────────────────────
  final bool acceptsCOD;
  final String? codDeliveryLocation;
  final String? codContactNumber;

  // ── Job Logic Fields (Simplified or legacy) ──────────────────────────────
  final bool isJob;
  final String? companyName;
  final String? jobType;
  final String? salaryRange;
  final List<String> applicationIds;

  // ── Lifecycle State ──────────────────────────────────────────────────────
  final String status; // 'pending' | 'approved' | 'rejected' | 'sold'

  // ── Audience ─────────────────────────────────────────────────────────────
  // Which platform(s) show this listing: 'web' | 'app' | 'both'.
  // Legacy docs without the field default to 'both'.
  final String platform;

  const ProductModel({
    required this.id,
    required this.title,
    required this.price,
    this.currency = 'Rs.', // Changed from Q.R to Rs.
    required this.category,
    this.subCategory = '',
    required this.condition,
    required this.sellerType,
    required this.sellerId,
    this.sellerName = 'Anonymous',
    this.sellerPhone = '',
    this.whatsAppNumber = '',
    this.sellerAvatarUrl = '',
    this.sellerTier = 'free', // NEW
    this.location = 'Pakistan', // Changed from Doha
    this.city = '', // NEW
    this.village = '', // NEW
    this.description = '',
    this.views = 0,
    this.favoritesCount = 0,
    required this.createdAt,
    this.expiresAt,
    this.boostExpiresAt, // NEW
    this.isFavorite = false,
    this.isFeatured = false,
    this.isBoosted = false, // NEW
    this.isSold = false,
    this.soldLocation,
    this.buyerNic,
    this.isActive = true,
    this.isVerifiedSeller = false,
    this.specifications = const {},
    this.imageUrls = const [],
    // Bidding
    this.isAuction = false,
    this.currentBid,
    this.lastBidderId,
    this.auctionEndTime,
    this.bidHistory = const [],
    // COD
    this.acceptsCOD = false,
    this.codDeliveryLocation,
    this.codContactNumber,
    // Job
    this.isJob = false,
    this.companyName,
    this.jobType,
    this.salaryRange,
    this.applicationIds = const [],
    // Status
    this.status = 'approved',
    this.platform = 'both',
  });

  // ── Helper Getters ───────────────────────────────────────────────────────
  String get postedTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  bool get isAuctionActive => isAuction && auctionEndTime != null && DateTime.now().isBefore(auctionEndTime!);

  // ── Firestore deserialization ────────────────────────────────────────────
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      price: (d['price'] as num?)?.toDouble() ?? 0,
      currency: d['currency'] as String? ?? 'Rs.',
      category: d['category'] as String? ?? '',
      subCategory: d['subCategory'] as String? ?? '',
      condition: d['condition'] as String? ?? '',
      sellerType: d['sellerType'] as String? ?? 'Personal',
      sellerId: d['sellerId'] as String? ?? '',
      sellerName: d['sellerName'] as String? ?? 'Anonymous',
      sellerPhone: d['sellerPhone'] as String? ?? '',
       whatsAppNumber: d['whatsAppNumber'] as String? ?? '',
       sellerAvatarUrl: d['sellerAvatarUrl'] as String? ?? '',
       sellerTier: d['sellerTier'] as String? ?? 'free',
       location: d['location'] as String? ?? 'Pakistan',
      city: d['city'] as String? ?? '',
      village: d['village'] as String? ?? '',
      description: d['description'] as String? ?? '',
      views: (d['views'] as int?) ?? 0,
      favoritesCount: (d['favoritesCount'] as int?) ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
      boostExpiresAt: (d['boostExpiresAt'] as Timestamp?)?.toDate(),
      isFeatured: d['isFeatured'] as bool? ?? false,
      isBoosted: d['isBoosted'] as bool? ?? false,
      isSold: d['isSold'] as bool? ?? false,
      isActive: d['isActive'] as bool? ?? true,
      isVerifiedSeller: d['isVerifiedSeller'] as bool? ?? false,
      specifications: Map<String, String>.from(d['specifications'] as Map? ?? {}),
      imageUrls: List<String>.from(d['imageUrls'] as List? ?? []),
      // Bidding
      isAuction: d['isAuction'] as bool? ?? false,
      currentBid: (d['currentBid'] as num?)?.toDouble(),
      lastBidderId: d['lastBidderId'] as String?,
      auctionEndTime: (d['auctionEndTime'] as Timestamp?)?.toDate(),
      bidHistory: List<Map<String, dynamic>>.from(d['bidHistory'] as List? ?? []),
      // COD
      acceptsCOD: d['acceptsCOD'] as bool? ?? false,
      codDeliveryLocation: d['codDeliveryLocation'] as String?,
      codContactNumber: d['codContactNumber'] as String?,
      // Job
      isJob: d['isJob'] as bool? ?? false,
      companyName: d['companyName'] as String?,
      jobType: d['jobType'] as String?,
      salaryRange: d['salaryRange'] as String?,
      applicationIds: List<String>.from(d['applicationIds'] as List? ?? []),
      // Status
      status: d['status'] as String? ?? 'approved',
      platform: d['platform'] as String? ?? 'both',
    );
  }

  // ── Firestore serialization ───────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
    'title': title,
    'titleLower': title.toLowerCase(),
    'searchKeywords': _buildKeywords(),
    'price': price,
    'currency': currency,
    'category': category,
    'subCategory': subCategory,
    'condition': condition,
    'sellerType': sellerType,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'sellerPhone': sellerPhone,
    'whatsAppNumber': whatsAppNumber,
    'sellerAvatarUrl': sellerAvatarUrl,
    'sellerTier': sellerTier,
    'location': location,
    'city': city,
    'village': village,
    'description': description,
    'views': views,
    'favoritesCount': favoritesCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'boostExpiresAt': boostExpiresAt != null ? Timestamp.fromDate(boostExpiresAt!) : null,
    'isFeatured': isFeatured,
    'isBoosted': isBoosted,
    'isSold': isSold,
    'soldLocation': soldLocation,
    'buyerNic': buyerNic,
    'isActive': isActive,
    'isVerifiedSeller': isVerifiedSeller,
    'specifications': specifications,
    'imageUrls': imageUrls,
    // Bidding
    'isAuction': isAuction,
    'currentBid': currentBid,
    'lastBidderId': lastBidderId,
    'auctionEndTime': auctionEndTime != null ? Timestamp.fromDate(auctionEndTime!) : null,
    'bidHistory': bidHistory,
    // COD
    'acceptsCOD': acceptsCOD,
    'codDeliveryLocation': codDeliveryLocation,
    'codContactNumber': codContactNumber,
    // Job
    'isJob': isJob,
    'companyName': companyName,
    'jobType': jobType,
    'salaryRange': salaryRange,
    'applicationIds': applicationIds,
    // Status
    'status': status,
    'platform': platform,
  };


  List<String> _buildKeywords() {
    final words = '$title $category $location'.toLowerCase().split(' ');
    final keywords = <String>{};
    for (final word in words) {
      for (var i = 2; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }
    return keywords.toList();
  }

  // ── Human-readable posted time ───────────────────────────────────────────

  ProductModel copyWith({
    String? id, String? title, double? price, String? currency,
    String? category, String? subCategory, String? condition, String? sellerType,
    String? sellerId, String? sellerName, String? sellerPhone, String? whatsAppNumber,
    String? sellerAvatarUrl, String? sellerTier, String? location, String? city, String? village,
    String? description, int? views, int? favoritesCount,
    DateTime? createdAt, DateTime? expiresAt, DateTime? boostExpiresAt,
    bool? isFavorite, bool? isFeatured, bool? isBoosted, bool? isSold,
    String? soldLocation, String? buyerNic,
    bool? isActive,
    bool? isVerifiedSeller, Map<String, String>? specifications, List<String>? imageUrls,
    bool? isAuction, double? currentBid, String? lastBidderId, DateTime? auctionEndTime,
    List<Map<String, dynamic>>? bidHistory,
    bool? acceptsCOD, String? codDeliveryLocation, String? codContactNumber,
    bool? isJob, String? companyName,
    String? jobType, String? salaryRange, List<String>? applicationIds, String? status,
    String? platform,
  }) => ProductModel(
    id: id ?? this.id,
    title: title ?? this.title,
    price: price ?? this.price,
    currency: currency ?? this.currency,
    category: category ?? this.category,
    subCategory: subCategory ?? this.subCategory,
    condition: condition ?? this.condition,
    sellerType: sellerType ?? this.sellerType,
    sellerId: sellerId ?? this.sellerId,
    sellerName: sellerName ?? this.sellerName,
    sellerPhone: sellerPhone ?? this.sellerPhone,
    whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
    sellerAvatarUrl: sellerAvatarUrl ?? this.sellerAvatarUrl,
    sellerTier: sellerTier ?? this.sellerTier,
    location: location ?? this.location,
    city: city ?? this.city,
    village: village ?? this.village,
    description: description ?? this.description,
    views: views ?? this.views,
    favoritesCount: favoritesCount ?? this.favoritesCount,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
    isFavorite: isFavorite ?? this.isFavorite,
    isFeatured: isFeatured ?? this.isFeatured,
    isBoosted: isBoosted ?? this.isBoosted,
    isSold: isSold ?? this.isSold,
    soldLocation: soldLocation ?? this.soldLocation,
    buyerNic: buyerNic ?? this.buyerNic,
    isActive: isActive ?? this.isActive,
    isVerifiedSeller: isVerifiedSeller ?? this.isVerifiedSeller,
    specifications: specifications ?? this.specifications,
    imageUrls: imageUrls ?? this.imageUrls,
    isAuction: isAuction ?? this.isAuction,
    currentBid: currentBid ?? this.currentBid,
    lastBidderId: lastBidderId ?? this.lastBidderId,
    auctionEndTime: auctionEndTime ?? this.auctionEndTime,
    bidHistory: bidHistory ?? this.bidHistory,
    acceptsCOD: acceptsCOD ?? this.acceptsCOD,
    codDeliveryLocation: codDeliveryLocation ?? this.codDeliveryLocation,
    codContactNumber: codContactNumber ?? this.codContactNumber,
    isJob: isJob ?? this.isJob,
    companyName: companyName ?? this.companyName,
    jobType: jobType ?? this.jobType,
    salaryRange: salaryRange ?? this.salaryRange,
    applicationIds: applicationIds ?? this.applicationIds,
    status: status ?? this.status,
    platform: platform ?? this.platform,
  );
}
