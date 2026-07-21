// models/models.dart

export 'product_model.dart';
export 'user_model.dart';
export 'chat_model.dart';
export 'notification_model.dart';
export 'category_model.dart';
export 'report_model.dart';
export 'order_model.dart';

import 'product_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SAMPLE DATA (Legacy - will be replaced by Firebase Repositories)
// ─────────────────────────────────────────────────────────────────────────────
class SampleData {
  // ── Categories ────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> homeCategories = [
    {
      'id': '0', 
      'name': 'Offers', 
      'icon': '🏷️',
      'subCategories': [
        {'name': 'All Offers', 'icon': '🏷️'},
        {'name': 'Today\'s Deals', 'icon': '🔥'},
        {'name': 'Limited Time', 'icon': '⏰'},
        {'name': 'Buy One Get One', 'icon': '🎁'},
      ]
    },
    {
      'id': '1', 
      'name': 'Vehicles', 
      'icon': '🚗',
      'subCategories': [
        {'name': 'All Vehicles', 'icon': '🚗'},
        {'name': 'Cars', 'icon': '🚙'},
        {'name': 'Motorcycles', 'icon': '🏍️'},
        {'name': 'Trucks', 'icon': '🚛'},
        {'name': 'Buses', 'icon': '🚌'},
        {'name': 'Spare Parts', 'icon': '🔧'},
      ]
    },
    {
      'id': '2', 
      'name': 'Properties', 
      'icon': '🏠',
      'subCategories': [
        {'name': 'All Properties', 'icon': '🏠'},
        {'name': 'Houses for Sale', 'icon': '🏡'},
        {'name': 'Apartments for Rent', 'icon': '🏢'},
        {'name': 'Commercial Properties', 'icon': '🏪'},
        {'name': 'Plots & Lands', 'icon': '🏜️'},
      ]
    },
    {
      'id': '3', 
      'name': 'Electronics', 
      'icon': '⚡',
      'subCategories': [
        {'name': 'All Electronics', 'icon': '⚡'},
        {'name': 'Mobile Phones', 'icon': '📱'},
        {'name': 'iPads & Tablets', 'icon': '📟'},
        {'name': 'Laptops & Computers', 'icon': '💻'},
        {'name': 'TVs & Home Appliances', 'icon': '📺'},
        {'name': 'Cameras & Photography', 'icon': '📷'},
        {'name': 'Gaming Consoles', 'icon': '🎮'},
        {'name': 'Mobile Accessories', 'icon': '🔌'},
      ]
    },
    {
      'id': '4', 
      'name': 'Furniture & Décor', 
      'icon': '🪑',
      'subCategories': [
        {'name': 'All Furniture', 'icon': '🪑'},
        {'name': 'Sofas & Couches', 'icon': '🛋️'},
        {'name': 'Tables & Chairs', 'icon': '🪑'},
        {'name': 'Beds & Mattresses', 'icon': '🛏️'},
        {'name': 'Home Decor', 'icon': '🎨'},
      ]
    },
    {
      'id': '5', 
      'name': 'WaterCrafts', 
      'icon': '⛵',
      'subCategories': [
        {'name': 'All WaterCrafts', 'icon': '⛵'},
        {'name': 'Yachts', 'icon': '🚢'},
        {'name': 'Jet Skis', 'icon': '🏄'},
        {'name': 'Boats', 'icon': '⛵'},
      ]
    },
    {
      'id': '6', 
      'name': 'Jewellery', 
      'icon': '💎',
      'subCategories': [
        {'name': 'All Jewellery', 'icon': '💎'},
        {'name': 'Rings', 'icon': '💍'},
        {'name': 'Necklaces', 'icon': '📿'},
        {'name': 'Watches', 'icon': '⌚'},
        {'name': 'Gold & Silver', 'icon': '🥇'},
      ]
    },
    {
      'id': '7', 
      'name': 'Lifestyle', 
      'icon': '🛍️',
      'subCategories': [
        {'name': 'All Lifestyle', 'icon': '🛍️'},
        {'name': 'Clothing & Shoes', 'icon': '👕'},
        {'name': 'Health & Beauty', 'icon': '💄'},
        {'name': 'Sports Equipment', 'icon': '⚽'},
        {'name': 'Books & Stationery', 'icon': '📚'},
      ]
    },
    {
      'id': '8', 
      'name': 'Market', 
      'icon': '🛒',
      'subCategories': [
        {'name': 'All Market', 'icon': '🛒'},
        {'name': 'Food & Groceries', 'icon': '🍎'},
        {'name': 'Home & Garden', 'icon': '🌱'},
        {'name': 'Pet Supplies', 'icon': '🐕'},
        {'name': 'Tools & Hardware', 'icon': '🔨'},
      ]
    },
    {
      'id': '9', 
      'name': 'Outdoor & Leisure', 
      'icon': '⛺',
      'subCategories': [
        {'name': 'All Outdoor', 'icon': '⛺'},
        {'name': 'Camping Gear', 'icon': '🏕️'},
        {'name': 'Musical Instruments', 'icon': '🎸'},
        {'name': 'Fishing', 'icon': '🎣'},
        {'name': 'Cycling', 'icon': '🚲'},
      ]
    },
    {
      'id': '10', 
      'name': 'Special Numbers', 
      'icon': '🔢',
      'subCategories': [
        {'name': 'All Numbers', 'icon': '🔢'},
        {'name': 'VIP Mobile Numbers', 'icon': '📱'},
        {'name': 'Car Plate Numbers', 'icon': '🚗'},
      ]
    },
    {
      'id': '11', 
      'name': 'Heavy Equipments', 
      'icon': '🏗️',
      'subCategories': [
        {'name': 'All Equipment', 'icon': '🏗️'},
        {'name': 'Excavators', 'icon': '🏗️'},
        {'name': 'Cranes', 'icon': '🏗️'},
        {'name': 'Loaders', 'icon': '🚜'},
        {'name': 'Tractors', 'icon': '🚜'},
      ]
    },
    {
      'id': '12', 
      'name': 'Jobs Center', 
      'icon': '💼',
      'subCategories': [
        {'name': 'All Jobs', 'icon': '💼'},
        {'name': 'IT & Software', 'icon': '💻'},
        {'name': 'Sales & Marketing', 'icon': '📊'},
        {'name': 'Engineering', 'icon': '🔧'},
        {'name': 'Part Time', 'icon': '⏰'},
      ]
    },
    {
      'id': '13', 
      'name': 'Super Ads', 
      'icon': '⭐',
      'subCategories': [
        {'name': 'All Super Ads', 'icon': '⭐'},
        {'name': 'Featured Ads', 'icon': '🌟'},
        {'name': 'Urgent Sales', 'icon': '⚡'},
      ]
    },
  ];

  static const List<Map<String, dynamic>> allCategories = [
    {'name': 'All', 'hasArrow': false},
    {'name': 'Vehicles', 'hasArrow': true},
    {'name': 'Properties', 'hasArrow': true},
    {'name': 'Electronics', 'hasArrow': true},
    {'name': 'Furniture & Décor', 'hasArrow': true},
    {'name': 'WaterCrafts', 'hasArrow': true},
    {'name': 'Jewellery', 'hasArrow': true},
    {'name': 'Lifestyle', 'hasArrow': true},
    {'name': 'Market', 'hasArrow': true},
    {'name': 'Outdoor & Leisure', 'hasArrow': true},
    {'name': 'Special Numbers', 'hasArrow': true},
    {'name': 'Heavy Equipments', 'hasArrow': true},
    {'name': 'Jobs Center', 'hasArrow': true},
    {'name': 'Super Ads', 'hasArrow': false},
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
      price: 185000,
      currency: 'Rs.',
      category: 'Mobile & Tablets',
      subCategory: 'Mobile Phones',
      condition: 'Used',
      sellerType: 'Personal',
      sellerId: 'user1',
      sellerName: 'Ali Khan',
      sellerPhone: '+92 300 1234567',
      whatsAppNumber: '+92 300 1234567',
      isVerifiedSeller: true,
      location: 'Pakistan',
      city: 'Lahore',
      village: 'Gulberg',
      description:
      'Excellent condition iPhone 14 Pro, 512GB storage, Light Violet color. Comes with original box, charger, and all accessories. No scratches, full battery health.',
      views: 342,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
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
    // ... adding a few more for sample if needed, but updated to match new model
  ];

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
