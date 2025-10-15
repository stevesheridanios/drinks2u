import 'package:flutter/material.dart';
import 'dart:convert';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Placeholder cart (use shared_preferences for persistence)
  List<Map<String, dynamic>> cartItems = [
    {'name': 'Coconut Water Original', 'price': 2.50, 'quantity': 1},
    {'name': 'Aloe Vera Mango', 'price': 3.50, 'quantity': 2},
  ];

  double get subtotal => cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));

  void _checkout() {
    // Generate JSON order
    final orderJson = jsonEncode({
      'order': {
        'items': cartItems,
        'total': subtotal,
        'timestamp': DateTime.now().toIso8601String(),
      },
    });
    print('Order JSON: $orderJson');  // Replace with email send
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order sent via email with JSON attachment!')),
    );
    setState(() {
      cartItems.clear();  // Empty cart
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cartItems.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(item['name']),
                          subtitle: Text('\$${item['price']} x ${item['quantity']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (item['quantity'] > 1) {
                                  item['quantity']--;
                                } else {
                                  cartItems.removeAt(index);
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Subtotal: \$${subtotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF32CD32),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Checkout & Send Order'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}