import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'dart:convert';
import 'dart:math'; // For min()
import 'package:shared_preferences/shared_preferences.dart'; // For pricing mode (kept for compatibility)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      final List<dynamic> data = [];
      for (var doc in snapshot.docs) { // For loop for per-doc trace
        final mapData = doc.data();
        final rawDesc = mapData['description']; // Raw before default
        final mappedDesc = rawDesc ?? ''; // After default
        final mappedItem = {
          'id': doc.id,
          'sku': mapData['sku'] ?? '',
          'name': mapData['name'] ?? '',
          'description': mappedDesc, // Use mapped
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
          'regional': double.tryParse(mapData['regional']?.toString() ?? '0') ?? 0.0,
          'archive': mapData['archive'] ?? false,
          'image': mapData['image'] ?? '',
        };
        data.add(mappedItem);
        // Per-doc debug: Raw vs mapped, especially for Nippys
        if (kDebugMode) {
          final name = mapData['name'] ?? 'Unnamed';
          print('Firestore doc ${doc.id} (name: $name): raw description = "$rawDesc" (type: ${rawDesc.runtimeType}), mapped = "$mappedDesc"');
          if (name.toLowerCase().contains('nippys')) {
            print('*** NIPPYS TRACE: Doc $doc.id full raw data keys: ${mapData.keys.toList()}'); // Keys list for mismatch
          }
        }
      }
      // Temp diagnostic: Find Nippys and log full item
      final nippysItem = data.firstWhere((item) => (item['name'] as String).contains('Nippys'), orElse: () => null);
      if (nippysItem != null) {
        print('*** NIPPYS FULL MAPPED ITEM: $nippysItem');
        print('*** NIPPYS DESCRIPTION FROM MAPPED: "${nippysItem['description']}"');
      }
      // Debug: Log first 3 items (remove after testing)
      for (int i = 0; i < data.length && i < 3; i++) {
        final item = data[i];
        print('Item $i debug:');
        print(' id: ${item['id']} (type: ${item['id'].runtimeType})');
        print(' cartonQty: ${item['cartonQty']} (type: ${item['cartonQty'].runtimeType})');
        print(' regional: ${item['regional']} (type: ${item['regional'].runtimeType})');
        print(' price: ${item['price']} (type: ${item['price'].runtimeType})');
        print(' description: "${item['description']}" (type: ${item['description'].runtimeType})'); // Added debug for description
      }
      print('Mapped ${data.length} items from Firestore'); // Debug: Parsed count
      if (mounted) {
        allProducts = []; // Clear to prevent duplication
        allProducts = data.map((json) => Product.fromJson(json)).toList(); // Sanitization happens in fromJson
        await _applyPricing(allProducts); // Apply dynamic pricing
        filteredProducts = allProducts.where((p) => p.category == selectedCategory || selectedCategory == 'All').toList(); // Fixed filter for 'All'
        setState(() {
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
          allProducts = []; // Clear to prevent duplication
          allProducts = jsonData.map((json) => Product.fromJson(json)).toList(); // Sanitization happens in fromJson
          await _applyPricing(allProducts); // Apply dynamic pricing
          filteredProducts = allProducts.where((p) => p.category == selectedCategory || selectedCategory == 'All').toList(); // Fixed filter for 'All'
          setState(() {
            isLoading = false;
            _isLoaded = true; // Re-set after fallback
            print('SetState: Loaded ${allProducts.length} products from JSON fallback, filtered to ${filteredProducts.length}'); // Debug: Post-set-state
          });
        }
      } catch (jsonError) {
        print('JSON fallback failed: $jsonError'); // Debug: JSON error
        await _loadHardcodedProducts(); // Final fallback only on failure
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading products from Firestore and JSON: $e. Using hardcoded fallback.')), // Updated message
          );
        }
      }
    }
  }
  Future<void> _loadHardcodedProducts() async {
    if (_isLoaded) return; // Prevent double fallback
    print('Loading fallback hardcoded products...'); // Debug: Fallback start
    List<Product> fallback = [];
    productsByCategory.forEach((category, items) {
      for (var item in items) {
        fallback.add(Product(
          id: fallback.length + 1, // Simple incremental ID
          name: item['name'] ?? 'Unnamed',
          category: category,
          metro: item['price'] ?? 0.0, // Assume same for fallback (customize if needed)
          regional: item['price'] ?? 0.0,
          cost: item['price'] ?? 0.0, // Map to cost
          image: item['image'] as String?,
          description: item['description'] ?? '${item['name']} - A refreshing drink.', // Ensure description (add to map if missing)
        ));
      }
    });
    if (mounted) {
      allProducts = []; // Clear to prevent duplication
      allProducts = fallback;
      await _applyPricing(allProducts); // Apply pricing to fallback too
      filteredProducts = allProducts.where((p) => p.category == selectedCategory || selectedCategory == 'All').toList(); // Fixed filter for 'All'
      setState(() {
        isLoading = false;
        _isLoaded = true;
        print('Fallback: Loaded ${allProducts.length} products from hardcoded, filtered to ${filteredProducts.length}'); // Debug: Post-set-state
      });
    }
  }
  Future<void> _applyPricing(List<Product> products) async {
    // NEW: Fetch user type for dynamic pricing
    String mode = 'regional'; // Default for non-logged-in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final accountType = userData['account_type'] ?? 'personal';
          mode = accountType.toLowerCase() == 'business' ? 'metro' : 'regional';
          print('Pricing mode set to $mode based on account_type: $accountType for user ${user.uid}'); // Debug
        }
      } catch (e) {
        print('Error fetching user type for pricing: $e - Defaulting to regional'); // Fallback
      }
    } else {
      print('No user logged in - Using regional pricing'); // Debug
    }
    // Apply mode to products
    for (final product in products) {
      product.price = mode == 'metro' ? product.metro : product.regional;
      print('Applied pricing for ${product.name}: $mode - New price: \$${product.price} (description preserved: "${product.description}")'); // Debug: Confirm description survives pricing
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
  // UPDATED: Quick add now for 1 carton (TASK 2)
  Future<void> _addToCart(Product product) async {
    const int unitsPerCarton = 6;
    try {
      await CartManager.addToCartWithQuantity(product, unitsPerCarton);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} (1 carton / ${unitsPerCarton} units) added to cart!')),
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
  // Keep your hardcoded map here temporarily for fallback – Added descriptions
  Map<String, List<Map<String, dynamic>>> productsByCategory = {
    'Aloe Vera': [
      {'name': 'Aloe Vera Lychee', 'price': 3.25, 'image': 'assets/images/aloe_lychee.png', 'description': 'Refreshing aloe vera with lychee flavor.'},
      {'name': 'Aloe Vera Mango', 'price': 3.50, 'image': 'assets/images/aloe_mango.png', 'description': 'Tropical mango-infused aloe vera drink.'},
      {'name': 'Aloe Vera Original', 'price': 2.75, 'image': 'assets/images/aloe_original.png', 'description': 'Pure aloe vera for hydration.'},
      {'name': 'Aloe Vera Peach', 'price': 3.00, 'image': 'assets/images/aloe_peach.png', 'description': 'Sweet peach aloe vera blend.'},
      {'name': 'Aloe Vera Watermelon', 'price': 3.25, 'image': 'assets/images/aloe_watermelon.png', 'description': 'Juicy watermelon aloe vera.'},
    ],
    'Coconut Water': [
      {'name': 'Coconut Water Original', 'price': 2.50, 'image': 'assets/images/coconut_original.png', 'description': 'Natural coconut water for electrolytes.'},
      {'name': 'Coconut Water Mango', 'price': 3.00, 'image': null, 'description': 'Mango-flavored coconut water.'},
    ],
    'Energy Drink': [
      {'name': 'Energy Boost', 'price': 4.00, 'image': null, 'description': 'High-energy boost with vitamins.'},
    ],
    'Flavoured Milk': [
      {'name': 'Chocolate Milk', 'price': 2.00, 'image': null, 'description': 'Creamy chocolate milk.'},
    ],
    'Fruit Juice': [
      {'name': 'Orange Juice', 'price': 2.75, 'image': null, 'description': 'Fresh squeezed orange juice.'},
    ],
    'Iced Tea': [
      {'name': 'Lemon Iced Tea', 'price': 2.25, 'image': null, 'description': 'Refreshing lemon iced tea.'},
    ],
    'Mineral Water': [
      {'name': 'Sparkling Water', 'price': 1.50, 'image': null, 'description': 'Bubbly mineral water.'},
    ],
    'Soft Drink': [
      {'name': 'Cola', 'price': 2.00, 'image': null, 'description': 'Classic cola taste.'},
    ],
    'Water': [
      {'name': 'Pure Water', 'price': 1.00, 'image': null, 'description': 'Pure filtered water.'},
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
                              // Debug print for image type detection
                              if (kDebugMode) {
                                print('Debug: ${product.name} image="${product.image}" startsWith http: ${product.image?.startsWith("http") ?? false}');
                                final previewLength = min(50, product.description.length);
                                print('Debug: ${product.name} description preview: "${product.description.substring(0, previewLength)}..." (full length: ${product.description.length})'); // Safe substring with min + length
                              }
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
                                      ? (product.image!.startsWith('http') // URL from Storage
                                          ? Image.network(
                                              product.image!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.contain,
                                              loadingBuilder: (context, child, loadingProgress) =>
                                                  loadingProgress == null ? child : const CircularProgressIndicator(),
                                              errorBuilder: (context, error, stackTrace) {
                                                if (kDebugMode) {
                                                  print('Network image load error for ${product.name}: $error at URL ${product.image}'); // Debug log
                                                }
                                                return CircleAvatar(
                                                  child: Text(product.name.isNotEmpty ? product.name[0].toUpperCase() : '?'),
                                                );
                                              },
                                            )
                                          : Image.asset( // Fallback asset path
                                              product.image!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                if (kDebugMode) {
                                                  print('Asset image load error for ${product.name}: $error at path ${product.image}'); // Debug log
                                                }
                                                return CircleAvatar(
                                                  child: Text(product.name.isNotEmpty ? product.name[0].toUpperCase() : '?'),
                                                );
                                              },
                                            ))
                                      : CircleAvatar(child: Text(product.name.isNotEmpty ? product.name[0].toUpperCase() : '?')),
                                  title: Text(product.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}', // Price
                                      ),
                                      if (product.description.isNotEmpty)
                                        Text(
                                          product.description.length > 50
                                              ? '${product.description.substring(0, min(50, product.description.length))}...'
                                              : product.description,
                                          style: Theme.of(context).textTheme.bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ), // Description preview – Safe substring
                                    ],
                                  ),
                                  // UPDATED: Quick add button for 1 carton (TASK 2)
                                  trailing: ElevatedButton(
                                    onPressed: () => _addToCart(product),
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