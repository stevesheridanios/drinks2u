class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final String? image;  // Nullable: Handles null for products without images
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.image,  // No 'required'—defaults to null if omitted
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      price: json['price'],
      image: json['image'],  // Can be null—factory handles it
      description: json['description'],
    );
  }
}