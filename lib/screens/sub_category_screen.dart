import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'listing_screen.dart';

class SubCategoryScreen extends StatelessWidget {
  final String categoryName;

  const SubCategoryScreen({super.key, required this.categoryName});

  static const List<Map<String, String>> _mobileSubs = [
    {'name': 'Mobile, Telephone and Tablets', 'icon': '📱'},
    {'name': 'iPad & Tablets', 'icon': '📟'},
    {'name': 'Mobile Phones', 'icon': '📲'},
    {'name': 'Telephone / DeskPhone', 'icon': '☎️'},
    {'name': 'Headphones & Earbuds, Airpods', 'icon': '🎧'},
    {'name': 'iPad & Tablets Accessories', 'icon': '💻'},
    {'name': 'Mobile Accessories', 'icon': '🔌'},
    {'name': 'Airpods and earbuds cleaning', 'icon': '🎵'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListingScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              categoryName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Dynamically size the circle so it always fits on any screen.
                // 3 columns + spacing: available width per cell ≈ (width - 2*16 - 2*12) / 3
                final cellWidth =
                    (constraints.maxWidth - 32 - 24) / 3; // padding + 2 gaps
                // Circle = 80% of cell width, capped at 80 logical pixels
                final circleSize = (cellWidth * 0.80).clamp(56.0, 80.0);
                // Icon font size = 44% of circle
                final iconSize = circleSize * 0.44;
                // childAspectRatio: width / height
                // height needed = circle + 8 + ~28 (2-line text at 11sp * 1.3 line-height)
                final cellHeight = circleSize + 8 + 30;
                final ratio = cellWidth / cellHeight;

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    // Use the computed ratio so cells are always tall enough
                    childAspectRatio: ratio,
                  ),
                  itemCount: _mobileSubs.length,
                  itemBuilder: (ctx, i) {
                    final sub = _mobileSubs[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ListingScreen(
                            categoryTitle: sub['name'],
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Circle icon — sized relative to cell
                          Container(
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.card,
                              border: Border.all(
                                color: AppColors.divider.withOpacity(0.5),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                sub['icon']!,
                                style: TextStyle(fontSize: iconSize),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Text — Flexible prevents overflow when text is long
                          Flexible(
                            child: Text(
                              sub['name']!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 10,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}