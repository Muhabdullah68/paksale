import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? nameAr;
  final String icon;
  final String? parentId;
  final int order;
  final bool isActive;
  final List<CategoryModel> subCategories;

  const CategoryModel({
    required this.id,
    required this.name,
    this.nameAr,
    required this.icon,
    this.parentId,
    this.order = 0,
    this.isActive = true,
    this.subCategories = const [],
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      nameAr: d['nameAr'] as String?,
      icon: d['icon'] as String? ?? '',
      parentId: d['parentId'] as String?,
      order: d['order'] as int? ?? 0,
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'nameAr': nameAr,
    'icon': icon,
    'parentId': parentId,
    'order': order,
    'isActive': isActive,
  };
}
