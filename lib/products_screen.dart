import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/product.dart';
import '../cart_manager.dart';
import 'product_detail_screen.dart';  // New import for detail navigation

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  String selectedCategory = 'Aloe Vera';  // Default to Aloe Vera
  bool isLoading = true;  // Track loading state explicitly

  // Your 9 categories + 'All' for filtering (matched to hardcoded keys)
  List<String> categories = [
    'All',
    'Aloe Vera',
    'Coconut Water',
    'Energy Drink',
    'Flavoured Milk',
    'Fruit Juice',
    'Iced Tea',
    'Mineral Water',
    'Soft Drink',
    'Water',
  ];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    print('Starting to load products from JSON...');  // Debug: Start of load
    try {
      final String response = await rootBundle.loadString('assets/data/products.json');
      print('JSON response length: ${response.length}');  // Debug: Raw JSON size
      final List<dynamic> data = json.decode(response);
      print('Parsed ${data.length} items from JSON');  // Debug: Parsed count
      if (mounted) {
        setState(() {
          allProducts = data.map((json) => Product.fromJson(json)).toList();
          filteredProducts = allProducts.where((p) => p.category == selectedCategory).toList();  // Default filter to Aloe Vera
          isLoading = false;
          print('SetState: Loaded ${allProducts.length} products from JSON, filtered to ${filteredProducts.length}');  // Debug: Post-setState
        });
      }
    } catch (e) {
      print('JSON load failed: $e');  // Debug: Exact error
      _loadHardcodedProducts();  // Fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products from JSON: $e. Using fallback.')),
        );
      }
    }
  }

  void _loadHardcodedProducts() {
    print('Loading fallback hardcoded products...');  // Debug: Fallback start
    // Temporary fallback: Convert your hardcoded map to Product list
    List<Product> fallback = [];
    productsByCategory.forEach((category, items) {
      for (var item in items) {
        fallback.add(Product(
          id: fallback.length + 1,  // Simple incremental ID
          name: item['name'],
          category: category,
          price: item['price'],
          image: item['image'] as String?,  // Explicit nullable cast
          description: '${item['name']} - A refreshing drink.',  // Placeholder
        ));
      }
    });
    if (mounted) {
      setState(() {
        allProducts = fallback;
        filteredProducts = allProducts.where((p) => p.category == selectedCategory).toList();  // Default filter to Aloe Vera
        isLoading = false;
        print('Fallback: Loaded ${allProducts.length} products from hardcoded, filtered to ${filteredProducts.length}');  // Debug: Post-setState
      });
    }
  }

  void filterProducts(String category) {
    setState(() {
      selectedCategory = category;
      if (category == 'All') {
        filteredProducts = allProducts;
      } else {
        filteredProducts = allProducts.where((p) => p.category == category).toList();
      }
      print('Filtered to ${filteredProducts.length} products for $category');  // Debug: Filter result
    });
  }

  Future<void> _addToCart(Product product) async {
    try {
      await CartManager.addToCart(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} added to cart!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add failed: $e')),
        );
      }
    }
  }

  // Keep your hardcoded map here temporarily for fallback
  Map<String, List<Map<String, dynamic>>> productsByCategory = {
    'Aloe Vera': [
      {'name': 'Aloe Vera Lychee', 'price': 3.25, 'image': 'assets/images/aloe_lychee.png'},
      {'name': 'Aloe Vera Mango', 'price': 3.50, 'image': 'assets/images/aloe_mango.png'},
      {'name': 'Aloe Vera Original', 'price': 2.75, 'image': 'assets/images/aloe_original.png'},
      {'name': 'Aloe Vera Peach', 'price': 3.00, 'image': 'assets/images/aloe_peach.png'},
      {'name': 'Aloe Vera Watermelon', 'price': 3.25, 'image': 'assets/images/aloe_watermelon.png'},
    ],
    'Coconut Water': [
      {'name': 'Coconut Water Original', 'price': 2.50, 'image': 'assets/images/coconut_original.png'},
      {'name': 'Coconut Water Mango', 'price': 3.00, 'image': null},
    ],
    'Energy Drink': [
      {'name': 'Energy Boost', 'price': 4.00, 'image': null},
    ],
    'Flavoured Milk': [
      {'name': 'Chocolate Milk', 'price': 2.00, 'image': null},
    ],
    'Fruit Juice': [
      {'name': 'Orange Juice', 'price': 2.75, 'image': null},
    ],
    'Iced Tea': [
      {'name': 'Lemon Iced Tea', 'price': 2.25, 'image': null},
    ],
    'Mineral Water': [
      {'name': 'Sparkling Water', 'price': 1.50, 'image': null},
    ],
    'Soft Drink': [
      {'name': 'Cola', 'price': 2.00, 'image': null},
    ],
    'Water': [
      {'name': 'Pure Water', 'price': 1.00, 'image': null},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: const Color(0xFF32CD32),  // Lime green
      ),
      body: Column(
        children: [
          // Dropdown for categories
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              hint: const Text('Select Category'),
              style: const TextStyle(color: Colors.black),
              dropdownColor: Colors.white,
              underline: Container(
                height: 2,
                color: const Color(0xFF32CD32),
              ),
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  filterProducts(newValue);
                }
              },
            ),
          ),
          // Products list for selected category
          Expanded(
            child: isLoading || filteredProducts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? const Center(child: Text('No products found in this category.'))
                    : ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              onTap: () {  // Tap ListTile to open detail screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                              leading: (product.image?.isNotEmpty ?? false)
                                  ? Image.asset(
                                      product.image!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const CircleAvatar(child: Icon(Icons.image_not_supported)),
                                    )
                                  : CircleAvatar(child: Text(product.name.isNotEmpty ? product.name[0].toUpperCase() : '?')),
                              title: Text(product.name),
                              subtitle: Text(
                                '${product.description}\n\$${product.price.toStringAsFixed(2)}',
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _addToCart(product),  // Quick add single
                                child: const Icon(Icons.add_shopping_cart),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}