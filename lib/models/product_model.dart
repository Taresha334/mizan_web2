class Product {
  final String id;
  final String name;
  final String mainCategory; // 'Poultry' or 'Ruminant'
  final String subCategory; // 'Broiler', 'Layer', 'Dairy', etc.
  final double price;
  final String imageUrl;
  final String description;
  final String feedForm; // 'Pellet' or 'Mesh'

  Product({
    required this.id,
    required this.name,
    required this.mainCategory,
    required this.subCategory,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.feedForm,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      mainCategory: json['main_category'] ?? '',
      subCategory: json['sub_category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      description: json['description'] ?? '',
      feedForm: json['feed_form'] ?? '',
    );
  }
}
