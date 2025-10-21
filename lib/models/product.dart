class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final String? image; // Nullable: Handles null for products without images
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.image, // No 'required'—defaults to null if omitted
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
  String? sanitizedImage = json['image'];
  if (sanitizedImage != null && sanitizedImage.isNotEmpty) {
    if (sanitizedImage.startsWith('http')) {
      // Skip sanitization for URLs to preserve ?alt=media
      sanitizedImage = sanitizedImage.trim(); // Just clean whitespace
    } else {
      // Only sanitize local/asset paths
      int lastSlashIndex = sanitizedImage.lastIndexOf('/');
      String pathPrefix = (lastSlashIndex >= 0) ? sanitizedImage.substring(0, lastSlashIndex + 1) : '';
      String filename = (lastSlashIndex >= 0) ? sanitizedImage.substring(lastSlashIndex + 1) : sanitizedImage;
      filename = filename
          .toLowerCase()
          .trim()
          .replaceAll(' ', '_')
          .replaceAll('/', '_')
          .replaceAll('\\', '_')
          .replaceAll(':', '_')
          .replaceAll('?', '_')  // Keep this for assets only
          .replaceAll('*', '_')
          .replaceAll('"', '_')
          .replaceAll('<', '_')
          .replaceAll('>', '_')
          .replaceAll('|', '_');
      sanitizedImage = pathPrefix + filename;
    }
  }
  return Product(
    id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    name: json['name'] ?? '',
    category: json['category'] ?? '',
    price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    image: sanitizedImage,
    description: json['description'] ?? '',
  );
}
}