class Product {
  int id;
  final String name;
  final String category;
  double price; // Mutable: Updated dynamically based on mode
  final double metro; // Metro customer price
  final double regional; // Regional customer price
  final double cost; // Supplier cost (for internal use)
  final String? image; // Nullable: Handles null for products without images
  final String description; // Final: Preserved in clones

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

    final desc = json['description'] ?? ''; // Safe default
    print('Product.fromJson for ${json['name'] ?? 'Unnamed'}: description="$desc"'); // Debug: Log on creation

    return Product(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      metro: double.tryParse(json['metro']?.toString() ?? '0') ?? 0.0,
      regional: double.tryParse(json['regional']?.toString() ?? '0') ?? 0.0,
      cost: double.tryParse(json['cost']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0, // Prefer 'cost', fallback to 'price'
      image: sanitizedImage,
      description: desc,
    );
  }

  // toJson if needed for cart/save (e.g., order export)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'metro': metro,
      'regional': regional,
      'cost': cost,
      'price': price, // Current price (post-mode)
      'image': image,
      'description': description,
    };
  }
}