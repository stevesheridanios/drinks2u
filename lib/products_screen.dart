import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // Your 9 categories
  final List<String> categories = [
    'Aloe Vera', 'Coconut Water', 'Energy Drink', 'Flavoured Milk',
    'Fruit Juice', 'Iced Tea', 'Mineral Water', 'Soft Drink', 'Water',
  ];

  String selectedCategory = 'Aloe Vera';  // Default

  // Products per category with your uploaded images
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

  Future<void> _addToCart(Map<String, dynamic> product) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> cartList = prefs.getStringList('cart') ?? [];
      print('Current cart length before add: ${cartList.length}');  // Debug

      Map<String, dynamic> cartItem = {
        'name': product['name'],
        'price': product['price'].toDouble(),  // Ensure double
        'quantity': 1,
      };

      // Check if item exists, update quantity
      bool found = false;
      for (int i = 0; i < cartList.length; i++) {
        Map<String, dynamic> existing = jsonDecode(cartList[i]);
        if (existing['name'] == product['name']) {
          existing['quantity'] = (existing['quantity'] as int) + 1;
          cartList[i] = jsonEncode(existing);
          found = true;
          print('Updated existing item: ${product['name']} to quantity ${existing['quantity']}');  // Debug
          break;
        }
      }
      if (!found) {
        cartList.add(jsonEncode(cartItem));
        print('Added new item: ${product['name']}');  // Debug
      }
      await prefs.setStringList('cart', cartList);
      print('Cart saved, total items: ${cartList.length}');  // Debug

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product['name']} added to cart!')),
      );
    } catch (e) {
      print('Add to cart error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProducts = productsByCategory[selectedCategory] ?? [];

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
                  setState(() {
                    selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
          // Products list for selected category
          Expanded(
            child: ListView.builder(
              itemCount: categoryProducts.length,
              itemBuilder: (context, index) {
                final product = categoryProducts[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: product['image'] != null
                        ? Image.asset(
                            product['image'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          )
                        : CircleAvatar(child: Text(product['name'][0])),
                    title: Text(product['name']),
                    subtitle: Text('\$${product['price']}'),
                    trailing: ElevatedButton(
                      onPressed: () => _addToCart(product),
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