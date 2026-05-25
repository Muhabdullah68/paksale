import '../models/product_model.dart';
import '../repositories/product_repository.dart';

class DataSeeder {
  static final ProductRepository _repository = ProductRepository();

  static Future<void> seedAllData() async {
    final List<ProductModel> products = [
      // ── Vehicles ──────────────────────────────────────────────────────────
      _createProduct(
        title: '2023 Toyota Land Cruiser VXR',
        price: 75000000,
        category: 'Vehicles',
        condition: 'Used',
        description: 'Perfect condition, low mileage, full options. Japanese specs.',
        imageUrls: ['https://images.unsplash.com/photo-1594568284297-7c64464062b1?q=80&w=800'],
      ),
      _createProduct(
        title: 'Honda Civic RS 2024',
        price: 9500000,
        category: 'Vehicles',
        condition: 'New',
        description: 'Brand new, black color, fully loaded.',
        imageUrls: ['https://images.unsplash.com/photo-1560958089-b8a1929cea89?q=80&w=800'],
      ),
      _createProduct(
        title: 'Suzuki Swift GLX 2022',
        price: 4500000,
        category: 'Vehicles',
        condition: 'Used',
        description: 'First owner, total genuine, low mileage.',
        imageUrls: ['https://images.unsplash.com/photo-1520031441872-265e4ff70366?q=80&w=800'],
      ),

      // ── Properties ────────────────────────────────────────────────────────
      _createProduct(
        title: 'Luxury Villa in Bahria Town',
        price: 85000000,
        category: 'Properties',
        condition: 'New',
        description: '1 Kanal designer villa with basement and swimming pool.',
        imageUrls: ['https://images.unsplash.com/photo-1613490493576-7fde63acd811?q=80&w=800'],
      ),
      _createProduct(
        title: 'Modern Apartment in DHA Phase 6',
        price: 12000000,
        category: 'Properties',
        condition: 'New',
        description: '2 Bedroom luxury apartment with modern amenities.',
        imageUrls: ['https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=800'],
      ),
      _createProduct(
        title: 'Commercial Plot in Gulberg',
        price: 45000000,
        category: 'Properties',
        condition: 'Used',
        description: 'Prime location commercial plot for offices or showroom.',
        imageUrls: ['https://images.unsplash.com/photo-1536376074432-ad717461274f?q=80&w=800'],
      ),

      // ── Electronics ───────────────────────────────────────────────────────
      _createProduct(
        title: 'iPhone 15 Pro Max 256GB',
        price: 485000,
        category: 'Electronics',
        condition: 'New',
        description: 'Brand new, PTA approved, Titanium Blue.',
        imageUrls: ['https://images.unsplash.com/photo-1696446701796-da61225697cc?q=80&w=800'],
      ),
      _createProduct(
        title: 'Samsung S24 Ultra',
        price: 425000,
        category: 'Electronics',
        condition: 'New',
        description: 'Latest model, PTA approved, 12GB/512GB.',
        imageUrls: ['https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=800'],
      ),
      _createProduct(
        title: 'Sony PlayStation 5 Slim',
        price: 185000,
        category: 'Electronics',
        condition: 'New',
        description: 'Disc edition with extra controller and 2 games.',
        imageUrls: ['https://images.unsplash.com/photo-1606144042614-b2417e99c4e3?q=80&w=800'],
      ),

      // ── Furniture & Décor ─────────────────────────────────────────────────
      _createProduct(
        title: 'Modern L-Shaped Sofa',
        price: 3500,
        category: 'Furniture & Décor',
        condition: 'New',
        description: 'Grey fabric, comfortable, seats 5 people easily.',
        imageUrls: ['https://images.unsplash.com/photo-1555041469-a586c61ea9bc?q=80&w=800'],
      ),
      _createProduct(
        title: 'Dining Table Set (6 Chairs)',
        price: 2800,
        category: 'Furniture & Décor',
        condition: 'Used',
        description: 'Solid oak wood table with leather cushioned chairs.',
        imageUrls: ['https://images.unsplash.com/photo-1530018607912-eff2df114f11?q=80&w=800'],
      ),
      _createProduct(
        title: 'Queen Size Bed with Mattress',
        price: 1500,
        category: 'Furniture & Décor',
        condition: 'Used',
        description: 'Minimalist design, including orthopedic mattress.',
        imageUrls: ['https://images.unsplash.com/photo-1505691723518-36a5ac3be353?q=80&w=800'],
      ),

      // ── WaterCrafts ───────────────────────────────────────────────────────
      _createProduct(
        title: 'Luxury Yacht 50ft',
        price: 2500000,
        category: 'WaterCrafts',
        condition: 'Used',
        description: '3 Cabins, spacious deck, fully serviced in 2023.',
        imageUrls: ['https://images.unsplash.com/photo-1567899378494-47b22a2ae96a?q=80&w=800'],
      ),
      _createProduct(
        title: 'Jet Ski Yamaha FX Cruiser',
        price: 65000,
        category: 'WaterCrafts',
        condition: 'Used',
        description: 'High performance, low hours, includes trailer.',
        imageUrls: ['https://images.unsplash.com/photo-1605281317010-fe5ffe798156?q=80&w=800'],
      ),
      _createProduct(
        title: 'Speed Boat 24ft',
        price: 185000,
        category: 'WaterCrafts',
        condition: 'New',
        description: 'Perfect for fishing and family trips. Mercury engine.',
        imageUrls: ['https://images.unsplash.com/photo-1540946484620-2c4c7271548b?q=80&w=800'],
      ),

      // ── Jewellery ─────────────────────────────────────────────────────────
      _createProduct(
        title: 'Diamond Engagement Ring',
        price: 15000,
        category: 'Jewellery',
        condition: 'New',
        description: '1 Carat solitaire diamond, 18K white gold band.',
        imageUrls: ['https://images.unsplash.com/photo-1605100804763-247f67b3557e?q=80&w=800'],
      ),
      _createProduct(
        title: 'Rolex Submariner Date',
        price: 55000,
        category: 'Jewellery',
        condition: 'Used',
        description: '2021 model, full set with box and papers. Excellent condition.',
        imageUrls: ['https://images.unsplash.com/photo-1523170335258-f5ed11844a49?q=80&w=800'],
      ),
      _createProduct(
        title: 'Gold Necklace 22K',
        price: 8500,
        category: 'Jewellery',
        condition: 'New',
        description: 'Traditional design, 35 grams, high purity gold.',
        imageUrls: ['https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?q=80&w=800'],
      ),

      // ── Lifestyle ─────────────────────────────────────────────────────────
      _createProduct(
        title: 'Nike Air Jordan 1 Retro',
        price: 950,
        category: 'Lifestyle',
        condition: 'New',
        description: 'Classic Chicago colorway, size 42. Authentic with box.',
        imageUrls: ['https://images.unsplash.com/photo-1584735175315-9d5df23860e6?q=80&w=800'],
      ),
      _createProduct(
        title: 'Designer Handbag',
        price: 4500,
        category: 'Lifestyle',
        condition: 'New',
        description: 'Italian leather, elegant design for any occasion.',
        imageUrls: ['https://images.unsplash.com/photo-1584917865442-de89df76afd3?q=80&w=800'],
      ),
      _createProduct(
        title: 'Electric Scooter Pro',
        price: 1800,
        category: 'Lifestyle',
        condition: 'New',
        description: '45km range, foldable, LED display, great for commuting.',
        imageUrls: ['https://images.unsplash.com/photo-1601362840469-51e4d8d59085?q=80&w=800'],
      ),

      // ── Market ────────────────────────────────────────────────────────────
      _createProduct(
        title: 'Organic Honey 1kg',
        price: 150,
        category: 'Market',
        condition: 'New',
        description: 'Pure sidr honey from local farms. No additives.',
        imageUrls: ['https://images.unsplash.com/photo-1587049352846-4a222e784d38?q=80&w=800'],
      ),
      _createProduct(
        title: 'Outdoor Gas Grill',
        price: 1200,
        category: 'Market',
        condition: 'New',
        description: '4 Burners, side sear station, perfect for BBQ nights.',
        imageUrls: ['https://images.unsplash.com/photo-1555507036-ab1f4038808a?q=80&w=800'],
      ),
      _createProduct(
        title: 'Mountain Bike 29"',
        price: 2400,
        category: 'Market',
        condition: 'New',
        description: 'Aluminum frame, Shimano gears, front suspension.',
        imageUrls: ['https://images.unsplash.com/photo-1532298229144-0ec0c57515c7?q=80&w=800'],
      ),

      // ── Outdoor & Leisure ─────────────────────────────────────────────────
      _createProduct(
        title: 'Camping Tent for 4',
        price: 650,
        category: 'Outdoor & Leisure',
        condition: 'New',
        description: 'Waterproof, easy setup, great for desert camping.',
        imageUrls: ['https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?q=80&w=800'],
      ),
      _createProduct(
        title: 'Acoustic Guitar',
        price: 1200,
        category: 'Outdoor & Leisure',
        condition: 'Used',
        description: 'Fender acoustic guitar, warm sound, includes bag.',
        imageUrls: ['https://images.unsplash.com/photo-1511379938547-c1f69419868d?q=80&w=800'],
      ),
      _createProduct(
        title: 'Stand Up Paddleboard',
        price: 1800,
        category: 'Outdoor & Leisure',
        condition: 'New',
        description: 'Inflatable, stable, includes pump and paddle.',
        imageUrls: ['https://images.unsplash.com/photo-1517176641128-d40ec9039c44?q=80&w=800'],
      ),

      // ── Special Numbers ───────────────────────────────────────────────────
      _createProduct(
        title: 'VIP Mobile Number 55XXXXXX',
        price: 25000,
        category: 'Special Numbers',
        condition: 'New',
        description: 'Unique repeating digits, easy to remember. Transfer included.',
        imageUrls: ['https://images.unsplash.com/photo-1598327105666-5b89351aff97?q=80&w=800'],
      ),
      _createProduct(
        title: 'Car Plate Number 123XXX',
        price: 45000,
        category: 'Special Numbers',
        condition: 'Used',
        description: 'Short number, 5 digits, very prestigious.',
        imageUrls: ['https://images.unsplash.com/photo-1621410015657-c1303abd970f?q=80&w=800'],
      ),
      _createProduct(
        title: 'Premium Plate 8888',
        price: 150000,
        category: 'Special Numbers',
        condition: 'Used',
        description: 'Exclusive 4-digit repeating number.',
        imageUrls: ['https://images.unsplash.com/photo-1621410015657-c1303abd970f?q=80&w=800'],
      ),

      // ── Heavy Equipments ──────────────────────────────────────────────────
      _createProduct(
        title: 'Caterpillar Excavator 320',
        price: 450000,
        category: 'Heavy Equipments',
        condition: 'Used',
        description: '2019 model, well maintained, 4500 working hours.',
        imageUrls: ['https://images.unsplash.com/photo-1579412691511-27468b7ca3c3?q=80&w=800'],
      ),
      _createProduct(
        title: 'JCB Backhoe Loader',
        price: 185000,
        category: 'Heavy Equipments',
        condition: 'Used',
        description: 'Versatile machine for construction and digging.',
        imageUrls: ['https://images.unsplash.com/photo-1581094288338-2314dddb7ec4?q=80&w=800'],
      ),
      _createProduct(
        title: 'Tower Crane 10 Ton',
        price: 850000,
        category: 'Heavy Equipments',
        condition: 'New',
        description: 'High reach, robust construction crane. Installation optional.',
        imageUrls: ['https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?q=80&w=800'],
      ),

      // ── Jobs Center ────────────────────────────────────────────────────────
      _createProduct(
        title: 'Senior Software Engineer',
        price: 25000,
        category: 'Jobs Center',
        condition: 'New',
        description: 'Full-time position in West Bay. Flutter experience required.',
        imageUrls: ['https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d?q=80&w=800'],
      ),
      _createProduct(
        title: 'Real Estate Agent',
        price: 10000,
        category: 'Jobs Center',
        condition: 'New',
        description: 'Commission based with basic salary. Driving license needed.',
        imageUrls: ['https://images.unsplash.com/photo-1560518883-ce09059eeffa?q=80&w=800'],
      ),
      _createProduct(
        title: 'Customer Service Executive',
        price: 6500,
        category: 'Jobs Center',
        condition: 'New',
        description: 'Fluent in English and Arabic. Shift based work.',
        imageUrls: ['https://images.unsplash.com/photo-1549923746-c502d488b3ea?q=80&w=800'],
      ),

      // ── Super Ads ─────────────────────────────────────────────────────────
      _createProduct(
        title: 'Premium Business Listing',
        price: 500,
        category: 'Super Ads',
        condition: 'New',
        description: 'Get your business featured on the home page for 30 days.',
        imageUrls: ['https://images.unsplash.com/photo-1460925895917-afdab827c52f?q=80&w=800'],
      ),
      _createProduct(
        title: 'Urgent Sale Booster',
        price: 150,
        category: 'Super Ads',
        condition: 'New',
        description: 'Highlight your ad with an "URGENT" tag and top placement.',
        imageUrls: ['https://images.unsplash.com/photo-1563986768609-322da13575f3?q=80&w=800'],
      ),
      _createProduct(
        title: 'Social Media Promotion',
        price: 300,
        category: 'Super Ads',
        condition: 'New',
        description: 'We will share your ad on our Instagram and Facebook pages.',
        imageUrls: ['https://images.unsplash.com/photo-1611162617213-7d7a39e9b1d7?q=80&w=800'],
      ),
    ];

    for (var product in products) {
      await _repository.createProduct(product);
    }
  }

  static ProductModel _createProduct({
    required String title,
    required double price,
    required String category,
    required String condition,
    required String description,
    required List<String> imageUrls,
  }) {
    return ProductModel(
      id: '', // Firestore will generate this
      title: title,
      price: price,
      category: category,
      condition: condition,
      sellerType: 'Personal',
      sellerId: 'admin_seed_user', // Placeholder
      sellerName: 'Marketplace Official',
      location: 'Pakistan',
      description: description,
      createdAt: DateTime.now(),
      imageUrls: imageUrls,
      isActive: true,
      isFeatured: true,
      status: 'approved',
    );
  }
}
