import 'package:flutter/material.dart';

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
      {'name': 'Coconut Water Mango', 'price': 3.00, 'image': null},  // Add image later
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
              isExpanded: true,  // Full width
              hint: const Text('Select Category'),  // Shown if no value
              style: const TextStyle(color: Colors.black),  // Black text
              dropdownColor: Colors.white,  // White background for dropdown
              underline: Container(
                height: 2,
                color: const Color(0xFF32CD32),  // Lime underline
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
                            fit: BoxFit.contain,  // Full image without cropping
                          )
                        : CircleAvatar(child: Text(product['name'][0])),
                    title: Text(product['name']),
                    subtitle: Text('\$${product['price']}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // TODO: Add to cart (navigate to CartScreen)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product['name']} added to cart!')),
                        );
                      },
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