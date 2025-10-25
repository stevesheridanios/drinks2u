class Product {
  int id;
  final String name;
  final String category;
  double price; // Mutable: Updated dynamically based on mode
  final double metro; // Metro customer price
  final double regional; // Regional customer price
  final double cost; // Supplier cost (for internal use)
  final String? image; // Nullable: Handles null for products without images
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.metro,
    required this.regional,
    required this.cost,
    this.image, // No 'required'—defaults to null if omitted
    required this.description,
  }) : price = regional; // Default to regional

  factory Product.fromJson(Map<String, dynamic> json) {
    String? sanitizedImage = json['image'];
    if (sanitizedImage != null && sanitizedImage.isNotEmpty) {
      if (sanitizedImage.startsWith('http')) {
        // For URLs (Storage), skip sanitization to preserve query params like ?alt=media
        sanitizedImage = sanitizedImage;
      } else {
        // For local/asset paths, sanitize filename only (preserve / separator)
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
    }
    return Product(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      metro: double.tryParse(json['metro']?.toString() ?? '0') ?? 0.0,
      regional: double.tryParse(json['regional']?.toString() ?? '0') ?? 0.0,
      cost: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0, // Map old 'price' to cost
      image: sanitizedImage,
      description: json['description'] ?? '',
    );
  }
}