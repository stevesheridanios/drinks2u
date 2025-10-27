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
  int _quantity = 1; // Now: Number of cartons
  @override
  void initState() {
    super.initState();
    print('Detail init for ${widget.product.name} (ID: ${widget.product.id}): description = "${widget.product.description}" (length: ${widget.product.description.length})'); // Debug on entry
  }
  Future<void> _addToCart() async {
    const int unitsPerCarton = 6; // Hardcoded; use widget.product.cartonQty if in model
    final effectiveQuantity = _quantity * unitsPerCarton; // e.g., 2 cartons = 12 units
    try {
      await CartManager.addToCartWithQuantity(widget.product, effectiveQuantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.product.name} x${_quantity} carton(s) (${effectiveQuantity} units) added to cart!')),
        );
      }
      print('Added ${widget.product.name}: ${_quantity} cartons -> ${effectiveQuantity} units'); // Debug
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
    const int unitsPerCarton = 6;
    final unitPrice = product.price; // Base unit price
    final cartonPrice = unitPrice * unitsPerCarton; // Per carton
    final total = cartonPrice * _quantity; // Subtotal for selected cartons
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
            // Price (carton-only)
            Text(
              '\$${unitPrice.toStringAsFixed(2)} per unit | \$${cartonPrice.toStringAsFixed(2)} per carton (6 units)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFF32CD32)),
            ),
            const SizedBox(height: 8),
            // Quantity Selector (for cartons only)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text('Number of Cartons: ', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('$_quantity', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                ),
                const Text('(x6 units each)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            // Subtotal
            Text(
              'Subtotal: \$${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.green),
            ),
            const SizedBox(height: 16),
            // Description
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              desc.isEmpty ? 'No description available.' : desc,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: null,
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
            const SizedBox(height: 16),
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