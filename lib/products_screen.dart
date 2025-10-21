import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/product.dart';
import '../cart_manager.dart';
import 'screens/product_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  String selectedCategory = 'Aloe Vera'; // Default to Aloe Vera
  bool isLoading = true; // Track loading state explicitly
  bool _isLoaded = false; // Prevent double-loading

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
    if (!_isLoaded) {
      loadProducts();
      _isLoaded = true;
    }
  }

  Future<void> loadProducts() async {
    setState(() => isLoading = true); // Always show spinner for refresh
    _isLoaded = false; // Reset for refresh (allows re-load)
    print('Starting to load products from Firestore...'); // Debug: Start of load
    try {
      final snapshot = await FirebaseFirestore.instance.collection('products').get();
      print('Firestore snapshot docs: ${snapshot.docs.length}'); // Debug: Fetched count
      final List<dynamic> data = snapshot.docs.map((doc) {
        final mapData = doc.data();
        return {
          'id': doc.id,
          'sku': mapData['sku'] ?? '',
          'name': mapData['name'] ?? '',
          'description': mapData['description'] ?? '',
          'storageLocation': mapData['storageLocation'] ?? '',
          'category': mapData['category'] ?? '',
          'metro': double.tryParse(mapData['metro']?.toString() ?? '0') ?? 0.0,
          'wholesale': double.tryParse(mapData['wholesale']?.toString() ?? '0') ?? 0.0,
          'price': double.tryParse(mapData['price']?.toString() ?? '0') ?? 0.0,
          'cartonQty': int.tryParse(mapData['cartonQty']?.toString() ?? '0') ?? 0,
          'weight': double.tryParse(mapData['weight']?.toString() ?? '0') ?? 0.0,
          'initialSupplier': mapData['initialSupplier'] ?? '',
          'sellByUnit': mapData['sellByUnit'] ?? false,
          'sellByCarton': mapData['sellByCarton'] ?? false,
          'regional': int.tryParse(mapData['regional']?.toString() ?? '0') ?? 0,
          'archive': mapData['archive'] ?? false,
          'image': mapData['image'] ?? '',
        };
      }).toList();

      // Debug: Log first 3 items (remove after testing)
      for (int i = 0; i < data.length && i < 3; i++) {
        final item = data[i];
        print('Item $i debug:');
        print('  id: ${item['id']} (type: ${item['id'].runtimeType})');
        print('  cartonQty: ${item['cartonQty']} (type: ${item['cartonQty'].runtimeType})');
        print('  regional: ${item['regional']} (type: ${item['regional'].runtimeType})');
        print('  price: ${item['price']} (type: ${item['price'].runtimeType})');
      }

      print('Mapped ${data.length} items from Firestore'); // Debug: Parsed count
      if (mounted) {
        setState(() {
          allProducts = []; // Clear to prevent duplication
          allProducts = data.map((json) => Product.fromJson(json)).toList(); // Sanitization happens in fromJson
          filteredProducts = allProducts.where((p) => p.category == selectedCategory).toList(); // Default filter to Aloe Vera
          isLoading = false;
          _isLoaded = true; // Re-set after successful load
          print('SetState: Loaded ${allProducts.length} products from Firestore, filtered to ${filteredProducts.length}'); // Debug: Post-set-state
        });
      }
        } catch (e) {
      print('Firestore load failed: $e'); // Debug: Exact error
      print('Falling back to JSON...'); // Debug: Transition to fallback
      try {
        final String response = await rootBundle.loadString('assets/data/products.json');
        print('JSON response length: ${response.length}'); // Debug: Raw JSON size
        final List<dynamic> jsonData = json.decode(response);
        print('Parsed ${jsonData.length} items from JSON'); // Debug: Parsed count
        if (mounted) {
          setState(() {
            allProducts = []; // Clear to prevent duplication
            allProducts = jsonData.map((json) => Product.fromJson(json)).toList(); // Sanitization happens in fromJson
            filteredProducts = allProducts.where((p) => p.category == selectedCategory).toList(); // Default filter to Aloe Vera
            isLoading = false;
            _isLoaded = true; // Re-set after fallback
            print('SetState: Loaded ${allProducts.length} products from JSON fallback, filtered to ${filteredProducts.length}'); // Debug: Post-set-state
          });
        }
      } catch (jsonError) {
        print('JSON fallback failed: $jsonError'); // Debug: JSON error
        _loadHardcodedProducts(); // Final fallback only on failure
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading products from Firestore and JSON: $e. Using hardcoded fallback.')), // Updated message
          );
        }
      }
    }
  }

  void _loadHardcodedProducts() {
    if (_isLoaded) return; // Prevent double fallback
    print('Loading fallback hardcoded products...'); // Debug: Fallback start
    List<Product> fallback = [];
    productsByCategory.forEach((category, items) {
      for (var item in items) {
        fallback.add(Product(
          id: fallback.length + 1, // Simple incremental ID
          name: item['name'],
          category: category,
          price: item['price'],
          image: item['image'] as String?, // Explicit nullable cast
          description: '${item['name']} - A refreshing drink.', // Placeholder
        ));
      }
    });
    if (mounted) {
      setState(() {
        allProducts = []; // Clear to prevent duplication
        allProducts = fallback;
        filteredProducts = allProducts.where((p) => p.category == selectedCategory).toList(); // Default filter to Aloe Vera
        isLoading = false;
        _isLoaded = true;
        print('Fallback: Loaded ${allProducts.length} products from hardcoded, filtered to ${filteredProducts.length}'); // Debug: Post-set-state
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
      print('Filtered to ${filteredProducts.length} products for $category'); // Debug: Filter result
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
        backgroundColor: const Color(0xFF32CD32), // Lime green
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white), // White icon for contrast
            onPressed: loadProducts, // Calls your Firestore reload method
            tooltip: 'Refresh Products', // Accessibility hint
          ),
        ],
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator( // Pull-to-refresh wrapper
                    onRefresh: loadProducts, // Reload from Firestore on pull
                    child: filteredProducts.isEmpty
                        ? const Center(child: Text('No products found in this category.'))
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(), // Enables pull even if short list
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return Card(
                                margin: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  onTap: () { // Tap ListTile to open detail screen
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
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Image load error for ${product.name}: $error at path ${product.image}'); // Debug log
                                            return CircleAvatar(
                                              child: Text(product.name.isNotEmpty ? product.name[0].toUpperCase() : '?'),
                                            );
                                          },
                                        )
                                      : CircleAvatar(child: Text(product.name.isNotEmpty ? product.name[0].toUpperCase() : '?')),
                                  title: Text(product.name),
                                  subtitle: Text(
                                    '${product.description}\n\$${product.price.toStringAsFixed(2)}',
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _addToCart(product), // Quick add single
                                    child: const Icon(Icons.add_shopping_cart),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
          ),
        ],
      ),
    );
  }
}