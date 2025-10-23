import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../cart_manager.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool isCarton = false; // Toggle for carton (12-pack)

  @override
  void initState() {
    super.initState();
    // Default to carton if desired, or single
    if (isCarton) {
      quantity = 12;
    }
  }

  void _toggleCarton() {
    setState(() {
      isCarton = !isCarton;
      quantity = isCarton ? 12 : 1;
    });
  }

  void _incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  Future<void> _addToCart() async {
    try {
      // Update CartManager to support initial quantity (modify addToCart to accept qty param)
      await CartManager.addToCartWithQuantity(widget.product, quantity);
      if (mounted) {
        Navigator.pop(context); // Back to Products
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.product.name} x$quantity added to cart!')),
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

  @override
  Widget build(BuildContext context) {
    final double displayPrice = isCarton ? widget.product.price * 12 : widget.product.price;
    final double total = displayPrice * quantity;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: const Color(0xFF32CD32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (updated: Network/Asset detection + error handling)
            Center(
              child: (widget.product.image?.isNotEmpty ?? false)
                  ? (widget.product.image!.startsWith('http')
                      ? Image.network(
                          widget.product.image!,
                          height: 200,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) =>
                              loadingProgress == null ? child : const CircularProgressIndicator(),
                          errorBuilder: (context, error, stackTrace) {
                            print('Network image error in details for ${widget.product.name}: $error');
                            return const Icon(Icons.image_not_supported, size: 200, color: Colors.grey);
                          },
                        )
                      : Image.asset(
                          widget.product.image!,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('Asset image error in details for ${widget.product.name}: $error');
                            return const Icon(Icons.image_not_supported, size: 200, color: Colors.grey);
                          },
                        ))
                  : CircleAvatar(
                      radius: 100,
                      child: Text(widget.product.name.isNotEmpty ? widget.product.name[0].toUpperCase() : '?'),
                    ),
            ),
            const SizedBox(height: 16),
            // Name and Price
            Text(
              widget.product.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '\$${widget.product.price.toStringAsFixed(2)} per unit',
              style: const TextStyle(fontSize: 16, color: Colors.green),
            ),
            const SizedBox(height: 8),
            // Description (from products table, with label for clarity)
            if (widget.product.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Carton Toggle
            Row(
              children: [
                const Text('Buy by carton (12-pack)? '),
                Switch(
                  value: isCarton,
                  onChanged: (_) => _toggleCarton(),
                ),
              ],
            ),
            if (isCarton) Text('Price for carton: \$${ (widget.product.price * 12).toStringAsFixed(2) }'),
            const SizedBox(height: 16),
            // Quantity Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _decrementQuantity,
                  icon: const Icon(Icons.remove),
                ),
                Text('$quantity', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _incrementQuantity,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Total
            Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.green),
            ),
            const SizedBox(height: 24),
            // Add to Cart Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32CD32),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add to Cart', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}