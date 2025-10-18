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
    String? sanitizedImage = json['image'];
    if (sanitizedImage != null && sanitizedImage.isNotEmpty) {
      // Split path and sanitize filename only (preserve / separator)
      int lastSlashIndex = sanitizedImage.lastIndexOf('/');
      String pathPrefix = (lastSlashIndex >= 0) ? sanitizedImage.substring(0, lastSlashIndex + 1) : '';
      String filename = (lastSlashIndex >= 0) ? sanitizedImage.substring(lastSlashIndex + 1) : sanitizedImage;

      // Sanitize filename: lowercase, trim, replace spaces/special chars
      filename = filename
          .toLowerCase()
          .trim()
          .replaceAll(' ', '_')
          .replaceAll('/', '_')
          .replaceAll('\\', '_')
          .replaceAll(':', '_')
          .replaceAll('?', '_')
          .replaceAll('*', '_')
          .replaceAll('"', '_')
          .replaceAll('<', '_')
          .replaceAll('>', '_')
          .replaceAll('|', '_');

      sanitizedImage = pathPrefix + filename;
    }

    return Product(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      price: json['price'],
      image: sanitizedImage,
      description: json['description'],
    );
  }
}