import 'package:flutter/material.dart';

import '../../services/transaction_service.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_theme.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await WishlistService.list();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _showSnack(String message, {bool isError = true}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _buy(Map<String, dynamic> item) async {
    final listingId = item["id"] is int
        ? item["id"] as int
        : int.tryParse("${item["id"] ?? ""}");

    if (listingId == null) {
      _showSnack("Cannot buy this item.");
      return;
    }

    final result = await TransactionService.buy(listingId, 1);
    if (!mounted) return;

    if (result.ok) {
      _showSnack("Purchase successful!", isError: false);
    } else {
      _showSnack(result.error ?? "Purchase failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Wishlist")),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No wishlist items yet",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final item = _items[i];
        final image = (item["image"] ?? "").toString();

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
            title: Text(
              (item["name"] ?? "Item").toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Stock: ${item["stock"] ?? 0}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "\$${item["price"] ?? 0}",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () => _buy(item),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Buy"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
