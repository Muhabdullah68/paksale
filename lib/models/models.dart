// models/models.dart

class ProductModel {
  final String id;
  final String title;
  final double price;
  final String currency;
  final String category;
  final String subCategory;
  final String condition;
  final String sellerType;
  final String sellerName;
  final String sellerPhone;
  final String location;
  final String description;
  final int views;
  final String postedTime;
  final bool isFavorite;
  final bool isFeatured;
  final bool isSold;
  final bool isVerifiedSeller;
  final Map<String, String> specifications;
  final List<String> imageAssets;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    this.currency = 'Q.R',
    required this.category,
    this.subCategory = '',
    required this.condition,
    required this.sellerType,
    this.sellerName = 'Anonymous',
    this.sellerPhone = '+974 5000 0000',
    this.location = 'Doha',
    this.description = '',
    this.views = 0,
    required this.postedTime,
    this.isFavorite = false,
    this.isFeatured = false,
    this.isSold = false,
    this.isVerifiedSeller = false,
    this.specifications = const {},
    this.imageAssets = const [],
  });

  ProductModel copyWith({
    String? id,
    String? title,
    double? price,
    String? currency,
    String? category,
    String? subCategory,
    String? condition,
    String? sellerType,
    String? sellerName,
    String? sellerPhone,
    String? location,
    String? description,
    int? views,
    String? postedTime,
    bool? isFavorite,
    bool? isFeatured,
    bool? isSold,
    bool? isVerifiedSeller,
    Map<String, String>? specifications,
    List<String>? imageAssets,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      condition: condition ?? this.condition,
      sellerType: sellerType ?? this.sellerType,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      location: location ?? this.location,
      description: description ?? this.description,
      views: views ?? this.views,
      postedTime: postedTime ?? this.postedTime,
      isFavorite: isFavorite ?? this.isFavorite,
      isFeatured: isFeatured ?? this.isFeatured,
      isSold: isSold ?? this.isSold,
      isVerifiedSeller: isVerifiedSeller ?? this.isVerifiedSeller,
      specifications: specifications ?? this.specifications,
      imageAssets: imageAssets ?? this.imageAssets,
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final List<CategoryModel> subCategories;
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.subCategories = const [],
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final String status;
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.status = 'sent',
  });
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final bool isVerified;
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatar = '',
    this.isVerified = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE DATA
// ─────────────────────────────────────────────────────────────────────────────
class SampleData {
  // ── Categories ────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> homeCategories = [
    {'id': '1', 'name': 'Vehicles', 'icon': '🚗'},
    {'id': '2', 'name': 'Properties', 'icon': '🏠'},
    {'id': '3', 'name': 'WaterCrafts', 'icon': '⛵'},
    {'id': '4', 'name': 'Special Numbers', 'icon': '📟'},
    {'id': '5', 'name': 'Heavy Equipments', 'icon': '🏗️'},
    {'id': '6', 'name': 'Super Ads', 'icon': '⭐'},
    {'id': '7', 'name': 'Jobs Center', 'icon': '💼'},
    {'id': '8', 'name': 'Market', 'icon': '🛒'},
    {'id': '9', 'name': 'Jewellery', 'icon': '💎'},
    {'id': '10', 'name': 'Furniture & Décor', 'icon': '🪑'},
    {'id': '11', 'name': 'Mobile & Tablets', 'icon': '📱'},
    {'id': '12', 'name': 'Cameras & Equipment', 'icon': '📷'},
    {'id': '13', 'name': 'Video Games', 'icon': '🎮'},
    {'id': '14', 'name': 'Home Appliances', 'icon': '🏠'},
    {'id': '15', 'name': 'Computers & Parts', 'icon': '💻'},
    {'id': '16', 'name': 'Services', 'icon': '🔧'},
    {'id': '17', 'name': 'Clothes', 'icon': '👕'},
    {'id': '18', 'name': 'Health & Beauty', 'icon': '💄'},
    {'id': '19', 'name': 'Shoes & Bags', 'icon': '👟'},
    {'id': '20', 'name': 'Kids', 'icon': '🧸'},
    {'id': '21', 'name': 'Camping', 'icon': '⛺'},
    {'id': '22', 'name': 'Wrist Watches', 'icon': '⌚'},
  ];

  static const List<Map<String, dynamic>> allCategories = [
    {'name': 'All', 'hasArrow': false},
    {'name': 'Air Beds & Sleeping Bags', 'hasArrow': false},
    {'name': 'Arts, Crafts & Sewing', 'hasArrow': true},
    {'name': 'Bikes', 'hasArrow': false},
    {'name': 'Bikes accessories', 'hasArrow': true},
    {'name': 'Building Materials', 'hasArrow': false},
    {'name': 'Camping', 'hasArrow': true},
    {'name': 'Car Spare Parts & Accessories', 'hasArrow': true},
    {'name': 'Caravan', 'hasArrow': false},
    {'name': 'Cars For Rent', 'hasArrow': false},
    {'name': 'Cars For Sale', 'hasArrow': false},
    {'name': 'Clothes', 'hasArrow': true},
    {'name': 'Computers and Parts', 'hasArrow': true},
    {'name': 'Electronics', 'hasArrow': true},
    {'name': 'Furniture & Décor', 'hasArrow': true},
    {'name': 'Heavy Equipments', 'hasArrow': false},
    {'name': 'Home Appliances', 'hasArrow': true},
    {'name': 'Jobs Center', 'hasArrow': true},
    {'name': 'Jewellery', 'hasArrow': false},
    {'name': 'Market', 'hasArrow': true},
    {'name': 'Mobile & Tablets', 'hasArrow': true},
    {'name': 'Properties', 'hasArrow': true},
    {'name': 'Services', 'hasArrow': true},
    {'name': 'Vehicles', 'hasArrow': true},
    {'name': 'Video Games', 'hasArrow': false},
    {'name': 'WaterCrafts', 'hasArrow': false},
    {'name': 'Wrist Watches', 'hasArrow': false},
  ];

  static const List<Map<String, String>> mobileSubCategories = [
    {'name': 'Mobile, Telephone and Tablets', 'icon': '📱'},
    {'name': 'iPad & Tablets', 'icon': '📟'},
    {'name': 'Mobile Phones', 'icon': '📲'},
    {'name': 'Telephone / DeskPhone', 'icon': '☎️'},
    {'name': 'Headphones & Earbuds', 'icon': '🎧'},
    {'name': 'iPad & Tablets Accessories', 'icon': '💻'},
    {'name': 'Mobile Accessories', 'icon': '🔌'},
    {'name': 'Airpods and earbuds', 'icon': '🎵'},
  ];

  // ── Products ──────────────────────────────────────────────────────────────
  static final List<ProductModel> products = [
    ProductModel(
      id: '1',
      title: 'Apple iPhone 14 Pro - Light Violet - 512 GB',
      price: 2000,
      category: 'Mobile & Tablets',
      subCategory: 'Mobile Phones',
      condition: 'Sale',
      sellerType: 'Personal',
      sellerName: 'Ahmed Al-Mansoori',
      sellerPhone: '+974 5512 3456',
      isVerifiedSeller: true,
      location: 'Doha',
      description:
      'Excellent condition iPhone 14 Pro, 512GB storage, Light Violet color. Comes with original box, charger, and all accessories. No scratches, full battery health.',
      views: 342,
      postedTime: '2 h ago',
      isFeatured: true,
      specifications: {
        'Brand': 'Apple',
        'Color': 'Light Violet',
        'Storage': '512 GB',
        'Model Year': '2022',
        'Charging Port': 'USB-C',
        'RAM': '6 GB',
        'Wi-Fi 6': 'Yes',
        'Under Warranty': 'No',
        '5G Enabled': 'Yes',
        'Rear Cam': '48 MP',
        'Front Cam': '12 MP',
        'Rear Cameras': '3',
        'Dual Sim': 'Yes',
        'Series': 'iPhone 14',
        'Model': 'Pro',
      },
    ),
    ProductModel(
      id: '2',
      title: 'Apple iPhone 14 Pro - Space Black - 128 GB',
      price: 2100,
      category: 'Mobile & Tablets',
      subCategory: 'Mobile Phones',
      condition: 'Sale',
      sellerType: 'Personal',
      sellerName: 'Fatima Hassan',
      sellerPhone: '+974 5523 4567',
      location: 'Al Rayyan',
      description:
      'iPhone 14 Pro Space Black 128GB. Used for 6 months. Perfect condition with original accessories.',
      views: 24,
      postedTime: '5 h ago',
      specifications: {
        'Brand': 'Apple',
        'Color': 'Space Black',
        'Storage': '128 GB',
        'Model Year': '2022',
        'Under Warranty': 'Yes',
        '5G Enabled': 'Yes',
        'Series': 'iPhone 14',
        'Model': 'Pro',
      },
    ),
    ProductModel(
      id: '3',
      title: 'Apple iPhone 15 - Glacier Blue - 128 GB',
      price: 1800,
      category: 'Mobile & Tablets',
      subCategory: 'Mobile Phones',
      condition: 'Sale',
      sellerType: 'Personal',
      sellerName: 'Mohammed Khalid',
      sellerPhone: '+974 5534 5678',
      location: 'Lusail',
      description:
      'Brand new iPhone 15 in Glacier Blue, sealed box, official warranty.',
      views: 56,
      postedTime: '1 day ago',
      isFeatured: true,
      specifications: {
        'Brand': 'Apple',
        'Color': 'Glacier Blue',
        'Storage': '128 GB',
        'Model Year': '2023',
        'Under Warranty': 'Yes',
        'Dynamic Island': 'Yes',
        '5G Enabled': 'Yes',
        'Series': 'iPhone 15',
      },
    ),
    ProductModel(
      id: '4',
      title: 'Toyota Camry 2021 - GLE - Full Option',
      price: 97000,
      category: 'Vehicles',
      subCategory: 'Cars For Sale',
      condition: 'Sale',
      sellerType: 'Business',
      sellerName: 'Qatar Motors',
      sellerPhone: '+974 4412 3456',
      location: 'Al Wakrah',
      description:
      'Toyota Camry 2021 GLE, full option. Single owner, low mileage, excellent condition. Service history available.',
      views: 891,
      postedTime: '3 h ago',
      isFeatured: true,
      specifications: {
        'Brand': 'Toyota',
        'Model': 'Camry',
        'Year': '2021',
        'Mileage': '45,000 km',
        'Color': 'White',
        'Transmission': 'Automatic',
        'Fuel Type': 'Petrol',
        'Engine': '2.5L',
        'Condition': 'Excellent',
      },
    ),
    ProductModel(
      id: '5',
      title: 'Villa for Rent - 5 Bedrooms - West Bay Lagoon',
      price: 18000,
      category: 'Properties',
      subCategory: 'Villas',
      condition: 'Rent',
      sellerType: 'Business',
      sellerName: 'J Seven Real Estate',
      sellerPhone: '+974 4456 7890',
      location: 'West Bay',
      description:
      'Luxurious 5 bedroom villa in West Bay Lagoon. Private pool, fully furnished, 24/7 security. Available from January 2025.',
      views: 1203,
      postedTime: '2 days ago',
      isFeatured: true,
      specifications: {
        'Type': 'Villa',
        'Bedrooms': '5',
        'Bathrooms': '6',
        'Area': '850 sqm',
        'Furnished': 'Yes',
        'Parking': '3 Cars',
        'Pool': 'Private',
        'Floor': 'Ground + 1',
      },
    ),
    ProductModel(
      id: '6',
      title: 'Samsung 65" QLED 4K Smart TV - 2023 Model',
      price: 3200,
      category: 'Home Appliances',
      subCategory: 'TVs',
      condition: 'Sale',
      sellerType: 'Personal',
      sellerName: 'Noor Al-Sabah',
      sellerPhone: '+974 5545 6789',
      location: 'Al Khor',
      description:
      'Samsung 65 inch QLED 4K Smart TV, 2023 model. Used 6 months, perfect working condition. Original remote and stand included.',
      views: 178,
      postedTime: '4 h ago',
      specifications: {
        'Brand': 'Samsung',
        'Size': '65 inch',
        'Resolution': '4K UHD',
        'Display': 'QLED',
        'Smart': 'Yes',
        'HDR': 'Yes',
        'Refresh Rate': '120Hz',
        'Year': '2023',
      },
    ),
    ProductModel(
      id: '7',
      title: 'MacBook Pro M2 - 16GB RAM - 512GB SSD',
      price: 4500,
      category: 'Computers & Parts',
      subCategory: 'Laptops',
      condition: 'Sale',
      sellerType: 'Personal',
      sellerName: 'Khalid Al-Dosari',
      sellerPhone: '+974 5556 7890',
      location: 'Doha',
      description:
      'MacBook Pro M2 chip, 16GB unified memory, 512GB SSD. Space Gray. Purchased 4 months ago, still under warranty.',
      views: 567,
      postedTime: '6 h ago',
      isFeatured: true,
      specifications: {
        'Brand': 'Apple',
        'Chip': 'Apple M2',
        'RAM': '16 GB',
        'Storage': '512 GB SSD',
        'Display': '14 inch',
        'Color': 'Space Gray',
        'Battery': 'Up to 18 hrs',
        'Under Warranty': 'Yes',
      },
    ),
    ProductModel(
      id: '8',
      title: 'PlayStation 5 - Disc Edition - Bundle',
      price: 1800,
      category: 'Video Games',
      subCategory: 'Consoles',
      condition: 'Sale',
      sellerType: 'Personal',
      sellerName: 'Omar Hassan',
      sellerPhone: '+974 5567 8901',
      location: 'Doha',
      description:
      'PS5 Disc Edition with 2 controllers and 3 games. Excellent condition, all original accessories.',
      views: 234,
      postedTime: '8 h ago',
      specifications: {
        'Brand': 'Sony',
        'Model': 'PS5 Disc',
        'Storage': '825 GB SSD',
        'Controllers': '2',
        'Games Included': '3',
        'Condition': 'Like New',
      },
    ),
    ProductModel(
      id: '9',
      title: 'Rolex Submariner - Date - Black Dial',
      price: 45000,
      category: 'Wrist Watches',
      subCategory: 'Luxury Watches',
      condition: 'Sale',
      sellerType: 'Business',
      sellerName: 'Luxury Time Qatar',
      sellerPhone: '+974 4467 8901',
      location: 'Doha',
      description:
      'Authentic Rolex Submariner Date, black dial, stainless steel. Comes with box and papers. Recently serviced.',
      views: 1567,
      postedTime: '1 day ago',
      isFeatured: true,
      specifications: {
        'Brand': 'Rolex',
        'Model': 'Submariner',
        'Reference': '126610LN',
        'Material': 'Stainless Steel',
        'Dial': 'Black',
        'Year': '2021',
        'Box & Papers': 'Yes',
        'Water Resistant': '300m',
      },
    ),
    ProductModel(
      id: '10',
      title: 'L-Shaped Sofa Set - Leather - 7 Seater',
      price: 2800,
      category: 'Furniture & Décor',
      subCategory: 'Sofas',
      condition: 'Sale',
      sellerType: 'Personal',
      sellerName: 'Ibrahim Al-Kuwari',
      sellerPhone: '+974 5578 9012',
      location: 'Al Rayyan',
      description:
      'Premium leather L-shaped sofa, 7 seater. Dark brown color, excellent condition. Moving sale.',
      views: 89,
      postedTime: '12 h ago',
      specifications: {
        'Material': 'Genuine Leather',
        'Color': 'Dark Brown',
        'Seats': '7',
        'Shape': 'L-Shaped',
        'Condition': 'Like New',
        'Age': '1 Year',
      },
    ),
    ProductModel(
      id: '11',
      title: 'Software Engineer - Full Stack - Remote',
      price: 0,
      currency: 'Q.R/mo',
      category: 'Jobs Center',
      subCategory: 'Technology',
      condition: 'Full Time',
      sellerType: 'Business',
      sellerName: 'TechQatar',
      sellerPhone: '+974 4478 9012',
      location: 'Remote / Doha',
      description:
      'Looking for experienced full-stack developer. React, Node.js, Flutter required. 3+ years experience. Competitive salary.',
      views: 445,
      postedTime: '3 h ago',
      specifications: {
        'Position': 'Full Stack Developer',
        'Experience': '3+ Years',
        'Type': 'Full Time',
        'Skills': 'React, Node.js',
        'Salary': 'Competitive',
        'Location': 'Remote/Doha',
      },
    ),
    ProductModel(
      id: '12',
      title: 'Yamaha FZS 250 - 2022 - Low Mileage',
      price: 8500,
      category: 'Vehicles',
      subCategory: 'Bikes',
      condition: 'Sale',
      sellerType: 'Personal',
      sellerName: 'Saad Al-Thani',
      sellerPhone: '+974 5589 0123',
      location: 'Lusail',
      description:
      'Yamaha FZS 250, 2022 model, 12,000 km mileage. Well maintained, all original parts.',
      views: 156,
      postedTime: '2 days ago',
      specifications: {
        'Brand': 'Yamaha',
        'Model': 'FZS 250',
        'Year': '2022',
        'Mileage': '12,000 km',
        'Color': 'Matte Black',
        'Engine': '249cc',
        'Under Warranty': 'No',
      },
    ),
  ];

  // ── Filter helpers ────────────────────────────────────────────────────────
  static List<ProductModel> filterProducts({
    String? query,
    String? category,
    String? location,
    String? condition,
    String? sellerType,
    double? minPrice,
    double? maxPrice,
  }) {
    return products.where((p) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!p.title.toLowerCase().contains(q) &&
            !p.category.toLowerCase().contains(q) &&
            !p.location.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (category != null && category != 'All' && p.category != category) {
        return false;
      }
      if (location != null && location != 'All' && !p.location.contains(location)) {
        return false;
      }
      if (condition != null && condition != 'All' && p.condition != condition) {
        return false;
      }
      if (sellerType != null && sellerType != 'All' && p.sellerType != sellerType) {
        return false;
      }
      if (minPrice != null && p.price < minPrice) {
        return false;
      }
      if (maxPrice != null && maxPrice > 0 && p.price > maxPrice) {
        return false;
      }
      return true;
    }).toList();
  }

  static List<ProductModel> getByCategory(String category) =>
      products.where((p) => p.category == category).toList();

  static List<ProductModel> getFeatured() =>
      products.where((p) => p.isFeatured).toList();
}