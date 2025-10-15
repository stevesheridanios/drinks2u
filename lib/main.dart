import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Danfels',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DrinksHomePage(title: 'Danfels - Browse Products'),
    );
  }
}

class DrinksHomePage extends StatefulWidget {
  const DrinksHomePage({super.key, required this.title});

  final String title;

  @override
  State<DrinksHomePage> createState() => _DrinksHomePageState();
}

class _DrinksHomePageState extends State<DrinksHomePage> {
  // Simple list of drinks (name, price, image optional)
  final List<Map<String, dynamic>> _drinks = [
    {'name': 'Coca-Cola', 'price': 2.50, 'image': null},
    {'name': 'Pepsi', 'price': 2.00, 'image': null},
    {'name': 'Bottled Water', 'price': 1.50, 'image': null},
    {'name': 'Orange Juice', 'price': 3.00, 'image': null},
    {'name': 'Iced Tea', 'price': 2.75, 'image': null},
  ];

  int _cartCount = 0; // Simple cart counter

  void _addToCart(Map<String, dynamic> drink) {
    setState(() {
      _cartCount++;
    });
    // TODO: Add to real cart logic (e.g., update a cart list)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${drink['name']} added to cart! \$${drink['price']}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _cartCount--;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Badge(
                label: Text('$_cartCount'),
                child: const Icon(Icons.shopping_cart),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _drinks.length,
        itemBuilder: (context, index) {
          final drink = _drinks[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(drink['name'][0]), // Initial as placeholder for image
              ),
              title: Text(drink['name']),
              subtitle: Text('\$${drink['price']}'),
              trailing: ElevatedButton(
                onPressed: () => _addToCart(drink),
                child: const Icon(Icons.add_shopping_cart),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to cart screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('View Cart - Coming Soon!')),
          );
        },
        tooltip: 'View Cart',
        child: const Icon(Icons.shopping_cart),
      ),
    );
  }
}