import 'category.dart';
import 'section.dart';

/// Entidade de domínio: produto (espelho do backend).
class Product {
  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.sku,
    this.active = true,
    this.images,
    this.categories,
    this.sections,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? sku;
  final bool active;
  final List<String>? images;
  final List<Category>? categories;
  final List<Section>? sections;
  final DateTime? createdAt;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? sku,
    bool? active,
    List<String>? images,
    List<Category>? categories,
    List<Section>? sections,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      active: active ?? this.active,
      images: images ?? this.images,
      categories: categories ?? this.categories,
      sections: sections ?? this.sections,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
