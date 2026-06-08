import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/cart_service.dart';
import '../../services/transaction_service.dart';
import '../../utils/currency_formatter.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
  int _qty = 1;

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addToCart() async {
    _qty = 1;
    final int stock = _asInt(widget.product['stock']);
    if (stock <= 0) return;

    final confirmed = await _showQtyDialog(stock, false);
    if (confirmed != null && confirmed) {
      CartService.addToCart(widget.product, _qty);
      if (!mounted) return;
      _showSnack('Added to cart!', isError: false);
    }
  }

  void _buyNow() async {
    _qty = 1;
    final int stock = _asInt(widget.product['stock']);
    if (stock <= 0) return;

    final confirmed = await _showQtyDialog(stock, true);
    if (confirmed != null && confirmed) {
      final result = await TransactionService.buy(_asInt(widget.product['id']), _qty);
      if (!mounted) return;
      if (result.ok) {
        _showSnack('Purchase successful!', isError: false);
        // Kembali ke halaman sebelumnya dan kirim sinyal 'true' agar halaman utama di-refresh
        Navigator.pop(context, true); 
      } else {
        _showSnack(result.error ?? 'Purchase failed.');
      }
    }
  }

  Future<bool?> _showQtyDialog(int stock, bool isBuy) async {
    final int price = _asInt(widget.product['price']);
    _qty = 1;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Image + Name + Price
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: widget.product['image'] != null
                              ? Image.network(widget.product['image'], fit: BoxFit.contain)
                              : const Icon(Icons.image, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product['name'] ?? 'Item',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${CurrencyFormatter.format(price)}',
                                style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    
                    // Quantity Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('Stock: $stock', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _qty > 1 ? () => setLocal(() => _qty--) : null,
                                icon: const Icon(Icons.remove, size: 20),
                                color: _qty > 1 ? Colors.black87 : Colors.grey,
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                padding: EdgeInsets.zero,
                              ),
                              Container(
                                width: 32,
                                alignment: Alignment.center,
                                child: Text('$_qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                onPressed: _qty < stock ? () => setLocal(() => _qty++) : null,
                                icon: const Icon(Icons.add, size: 20),
                                color: _qty < stock ? Colors.black87 : Colors.grey,
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 20),
                    
                    // Footer: Total & Actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Price', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          '${CurrencyFormatter.format(price * _qty)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Text(isBuy ? 'Buy Now' : 'Add to Cart', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final int stock = _asInt(product['stock']);
    final bool isWeapon = product['item_type'] == 'weapon';
    final int quality = _asInt(product['quality']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Detail'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[200],
              padding: isWeapon ? const EdgeInsets.all(32) : const EdgeInsets.all(16),
              child: (product['image'] != null && product['image'].toString().isNotEmpty)
                  ? Image.network(
                      product['image'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    )
                  : const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['name'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (quality > 0)
                        Row(
                          children: List.generate(
                            quality,
                            (index) => const Icon(Icons.star, color: Colors.amber, size: 20),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                      '${CurrencyFormatter.format(product['price'] ?? 0)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          product['category'] ?? 'Uncategorized',
                          style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Stock available: $stock', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    product['description']?.toString().isNotEmpty == true 
                        ? product['description'] 
                        : 'No description available for this item.',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: stock > 0 ? _buyNow : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(stock > 0 ? 'Buy Now' : 'Out of stock', style: const TextStyle(fontSize: 16)),
              ),
            ),
            if (stock > 0) ...[
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_shopping_cart, color: AppColors.secondary),
                  onPressed: _addToCart,
                  tooltip: 'Add to Cart',
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
