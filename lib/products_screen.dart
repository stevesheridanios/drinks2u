import 'package:flutter/material.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // Categories from your outline
  final List<String> categories = [
    'Aloe Vera', 'Coconut Water', 'Energy Drink', 'Flavoured Milk',
    'Fruit Juice', 'Iced Tea', 'Mineral Water', 'Soft Drink', 'Water',
  ];

  String selectedCategory = 'Aloe Vera';  // Default

  // Placeholder products per category (sync with backend JSON)
  Map<String, List<Map<String, dynamic>>> productsByCategory = {
    'Aloe Vera': [
      {'name': 'Aloe Vera Mango', 'price': 3.50, 'image': null},
      {'name': 'Aloe Vera Peach', 'price': 3.00, 'image': null},
    ],
    'Coconut Water': [
      {'name': 'Coconut Water Original', 'price': 2.50, 'image': null},
      {'name': 'Coconut Water Mango', 'price': 3.00, 'image': null},
    ],
    // Add placeholders for other categories...
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
      appBar: AppBar(title: const Text('Products')),
      body: Column(
        children: [
          // Categories grid
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: () => setState(() {
                      selectedCategory = category;
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCategory == category ? const Color(0xFF32CD32) : Colors.grey,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(category),
                  ),
                );
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
                    leading: CircleAvatar(child: Text(product['name'][0])),
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