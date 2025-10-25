import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import '../../models/product.dart';
import '../../cart_manager.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isCarton = false; // Toggle unit vs carton

  @override
  void initState() {
    super.initState();
    print('Detail init for ${widget.product.name} (ID: ${widget.product.id}): description = "${widget.product.description}" (length: ${widget.product.description.length})'); // Debug on entry
  }

  Future<void> _addToCart() async {
    try {
      await CartManager.addToCart(widget.product); // Single add; update manager for qty if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.product.name} x${_quantity}${_isCarton ? ' carton' : ''} added to cart!')),
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
    final product = widget.product;
    final desc = product.description ?? ''; // Safe handling
    final displayPrice = _isCarton ? (product.price * 6) : product.price; // Hardcoded carton = 6
    final total = displayPrice * _quantity;
    print('Build for ${product.name}: final desc = "$desc" (length: ${desc.length})'); // Debug on build
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: const Color(0xFF32CD32), // Lime green
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Center(
              child: (product.image?.isNotEmpty ?? false)
                  ? (product.image!.startsWith('http')
                      ? Image.network(
                          product.image!,
                          height: 250,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) =>
                              loadingProgress == null ? child : const CircularProgressIndicator(),
                          errorBuilder: (context, error, stackTrace) {
                            if (kDebugMode) print('Network image error: $error');
                            return const Icon(Icons.error, size: 250);
                          },
                        )
                      : Image.asset(
                          product.image!,
                          height: 250,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            if (kDebugMode) print('Asset image error: $error');
                            return const Icon(Icons.error, size: 250);
                          },
                        ))
                  : const Icon(Icons.image_not_supported, size: 250),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            // Price
            Text(
              '\$${product.price.toStringAsFixed(2)} per unit',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFF32CD32)),
            ),
            const SizedBox(height: 8),
            // Toggle Unit/Carton
            Row(
              children: [
                const Text('Buy by carton (6-pack)? '),
                Switch(
                  value: _isCarton,
                  onChanged: (_) {
                    setState(() {
                      _isCarton = ! _isCarton;
                      _quantity = _isCarton ? 1 : _quantity;
                    });
                  },
                ),
              ],
            ),
            if (_isCarton) Text('Price for carton: \$${ (product.price * 6).toStringAsFixed(2) }'),
            const SizedBox(height: 8),
            // Quantity Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('$_quantity', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Total (moved up for logical flow)
            Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.green),
            ),
            const SizedBox(height: 16),
            // Description (MOVED HERE: After all pricing/quantity; now fully scrollable)
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              desc.isEmpty ? 'No description available.' : desc,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: null,  // Updated: Unlimited lines for full text
              overflow: TextOverflow.visible,  // Updated: No truncation
              softWrap: true,  // Ensures proper line wrapping
            ),
            const SizedBox(height: 16),  // Extra space before button
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