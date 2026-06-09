import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gachamerch/services/auth_service.dart';
import 'package:gachamerch/services/transaction_service.dart';
import 'package:gachamerch/services/wishlist_service.dart';
import 'package:gachamerch/services/cart_service.dart';
import 'package:gachamerch/features/cart/cart_page.dart';
import 'package:gachamerch/features/product/product_detail_page.dart';
import 'package:gachamerch/features/main/profile_page.dart';
import 'package:gachamerch/features/main/transaction_page.dart';
import 'package:gachamerch/features/main/notification_page.dart';
import 'package:gachamerch/services/notification_service.dart';
import 'package:gachamerch/theme/app_theme.dart';
import 'package:gachamerch/utils/currency_formatter.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  int _selectedIndex = 0;
  int _txnTick = 0; // bump untuk paksa refetch riwayat saat tab dibuka

  final PageController _bannerController = PageController(
    viewportFraction: 0.9,
    initialPage: 1000,
  );

  bool _isLoading = true;
  Timer? _bannerTimer;

  final List<String> _bannerImages = [
    'https://static.wikia.nocookie.net/gensin-impact/images/9/99/Uncover_Lunar_Realms%2C_Hone_the_Eventide_Radiance_2025-10-22.png',
    'https://static.wikia.nocookie.net/gensin-impact/images/3/3a/The_Stilled_Interstice_of_a_Thousand_Winds.png',
    'https://static.wikia.nocookie.net/gensin-impact/images/6/6e/To_Temper_Thyself_and_Journey_Far.png',
  ];



  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _products = [];
  String? _selectedCategory;
  String _searchQuery = '';
  String _txSearchQuery = '';
  String? _error; // pesan error fetch (mis. DB/XAMPP mati) untuk ditampilkan
  final Set<String> _wishlistIds = {};
  String? _pulsingWishlistId;
  DateTime? _lastWishlistActionAt;

  static const int _pageSize = 10;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();

    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      _bannerController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });

    _fetchProducts();
    _loadWishlist();
    CartService.loadCart();
    NotificationService.loadNotifications();
  }

  Future<void> _loadWishlist() async {
    final items = await WishlistService.list();
    if (!mounted) return;
    setState(() {
      _wishlistIds
        ..clear()
        ..addAll(items.map((item) => item["id"]?.toString()).whereType<String>());
    });
  }

  Future<void> _fetchProducts() async {
    try {
      // Hanya item yang sedang DIJUAL (listings), bukan seluruh katalog.
      final res = await http.get(Uri.parse("${AuthService.baseUrl}/listings"));
      if (res.statusCode == 200) {
        final jsonResponse = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _allProducts = List<Map<String, dynamic>>.from(jsonResponse['data']);
            _applyFilter();
            _error = null;
            _isLoading = false;
          });
        }
      } else {
        // Ambil pesan error backend (mis. 503 saat XAMPP/MySQL mati).
        String message = "Failed to load items (${res.statusCode}).";
        try {
          final body = jsonDecode(res.body);
          if (body is Map && body["error"] != null) {
            message = body["error"].toString();
          }
        } catch (_) {
          // body bukan JSON — pakai pesan default
        }
        if (mounted) {
          setState(() {
            _error = message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error Fetching Products: $e");
      if (mounted) {
        setState(() {
          _error = "Cannot connect to the server. Is the backend running?";
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  int _asInt(dynamic v) =>
      v is int ? v : int.tryParse('${v ?? 0}') ?? 0;

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


  Future<void> _toggleWishlist(Map<String, dynamic> product) async {
    final now = DateTime.now();
    final lastAction = _lastWishlistActionAt;
    if (lastAction != null &&
        now.difference(lastAction) < const Duration(seconds: 3)) {
      _showSnack("Please don't spam the wishlist button.");
      return;
    }

    final id = product["id"]?.toString();
    if (id == null) return;
    _lastWishlistActionAt = now;

    final wasWishlisted = _wishlistIds.contains(id);
    final changed = wasWishlisted
        ? await WishlistService.remove(id)
        : await WishlistService.add(product);
    if (!mounted) return;

    if (changed) {
      setState(() {
        if (wasWishlisted) {
          _wishlistIds.remove(id);
        } else {
          _wishlistIds.add(id);
        }
        _pulsingWishlistId = id;
      });

      Future.delayed(const Duration(milliseconds: 160), () {
        if (!mounted) return;
        setState(() => _pulsingWishlistId = null);
      });
    }

    final name = (product['name'] ?? 'Item').toString();
    _showSnack(
      wasWishlisted
          ? '$name removed from wishlist.'
          : '$name added to wishlist.',
      isError: false,
    );
  }


  Future<int?> _showQtyDialog(Map<String, dynamic> product, bool isBuy) async {
    final int stock = _asInt(product['stock']);
    final int price = _asInt(product['price']);
    final String name = (product['name'] ?? 'Item').toString();
    int qty = 1;

    final confirmed = await showDialog<bool>(
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
                          child: product['image'] != null
                              ? Image.network(product['image'], fit: BoxFit.contain)
                              : const Icon(Icons.image, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                maxLines: 1,
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
                                onPressed: qty > 1 ? () => setLocal(() => qty--) : null,
                                icon: const Icon(Icons.remove, size: 20),
                                color: qty > 1 ? Colors.black87 : Colors.grey,
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                padding: EdgeInsets.zero,
                              ),
                              Container(
                                width: 32,
                                alignment: Alignment.center,
                                child: Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                onPressed: qty < stock ? () => setLocal(() => qty++) : null,
                                icon: const Icon(Icons.add, size: 20),
                                color: qty < stock ? Colors.black87 : Colors.grey,
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
                          '${CurrencyFormatter.format(price * qty)}',
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

    return confirmed == true ? qty : null;
  }

  /// Dialog pembelian: pilih jumlah (1..stok), lalu tambahkan ke keranjang.
  Future<void> _showAddToCartDialog(Map<String, dynamic> product) async {
    final qty = await _showQtyDialog(product, false);
    if (qty == null) return;

    CartService.addToCart(product, qty);
    if (!mounted) return;
    _showSnack('Added to cart!', isError: false);
  }

  /// Dialog pembelian langsung: pilih jumlah (1..stok), lihat total, lalu beli.
  Future<void> _showBuyDialog(Map<String, dynamic> product) async {
    final qty = await _showQtyDialog(product, true);
    if (qty == null) return;

    final result = await TransactionService.buy(_asInt(product['id']), qty);
    if (!mounted) return;
    if (result.ok) {
      _showSnack('Purchase successful!', isError: false);
      _fetchProducts(); // refresh agar stok terbaru kebaca
    } else {
      _showSnack(result.error ?? 'Purchase failed.');
    }
  }

  Widget shimmerBox({double height = 10, double width = 100}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(height: height, width: width, color: Colors.white),
    );
  }

  void _applyFilter() {
    _products = _allProducts.where((p) {
      final matchesCategory = _selectedCategory == null || p['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          (p['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }



  void _showCategoryFilter() {
    final categories = _allProducts.map((p) => p['category']?.toString() ?? 'Unknown').toSet().toList();
    categories.sort();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Filter by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('All Categories'),
                      trailing: _selectedCategory == null ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = null;
                          _applyFilter();
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1),
                    ...categories.map((c) => ListTile(
                      title: Text(c),
                      trailing: _selectedCategory == c ? const Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = c;
                          _applyFilter();
                        });
                        Navigator.pop(context);
                      },
                    )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ================= HOME PAGE =================
  Widget _buildHome() {
    return RefreshIndicator(
      onRefresh: _fetchProducts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), // pastikan bisa di-scroll walau item kosong agar bisa refresh
        children: [
        /// BANNER
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _bannerController,
            itemBuilder: (context, i) {
              final index = i % _bannerImages.length;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[300],
                  image: _isLoading
                      ? null
                      : DecorationImage(
                          image: NetworkImage(_bannerImages[index]),
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        /// TITLE & FILTER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended For You',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showCategoryFilter,
                tooltip: 'Filter Category',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        /// ERROR STATE — fetch gagal (mis. backend/XAMPP MySQL mati).
        if (!_isLoading && _error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _fetchProducts();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Try again"),
                  ),
                ],
              ),
            ),
          ),

        /// EMPTY STATE — belum ada item yang dijual admin.
        if (!_isLoading && _error == null && _products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Center(
              child: Text(
                'No items on sale right now.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

        /// PRODUCT
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _products.length < _visibleCount
              ? _products.length
              : _visibleCount,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.68,
          ),
          itemBuilder: (context, i) {
            final product = _products[i];
            final productId = product["id"]?.toString();
            final isWishlisted = productId != null && _wishlistIds.contains(productId);
            final isPulsing = productId != null && _pulsingWishlistId == productId;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(product: product),
                  ),
                ).then((shouldRefresh) {
                  if (shouldRefresh == true) {
                    _fetchProducts(); // Refresh stock if bought
                  }
                });
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: (product['image'] != null && product['image'].toString().isNotEmpty)
                              ? Container(
                                  height: 110,
                                  width: double.infinity,
                                  color: AppColors.background,
                                  padding: product['item_type'] != 'food'
                                      ? const EdgeInsets.fromLTRB(20, 12, 20, 20)
                                      : const EdgeInsets.all(6),
                                  child: Image.network(
                                    product['image'],
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                                  ),
                                )
                              : const SizedBox(
                                  height: 110,
                                  child: Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => _toggleWishlist(product),
                              child: AnimatedScale(
                                scale: isPulsing ? 1.22 : 1,
                                duration: const Duration(milliseconds: 140),
                                curve: Curves.easeOutBack,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isWishlisted ? AppColors.primary.withValues(alpha: 0.18) : AppColors.surface.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.55)),
                                  ),
                                  child: Icon(
                                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                                    size: 19,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        product['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${CurrencyFormatter.format(product['price'] ?? 0)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Stock: ${product['stock'] ?? 0}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _asInt(product['stock']) > 0
                                  ? () => _showBuyDialog(product)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(30),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 0),
                              ),
                              child: Text(
                                _asInt(product['stock']) > 0 ? 'Buy' : 'Out of stock',
                              ),
                            ),
                          ),
                          if (_asInt(product['stock']) > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.add_shopping_cart, color: AppColors.secondary, size: 18),
                                onPressed: () => _showAddToCartDialog(product),
                                tooltip: 'Add to Cart',
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        if (_visibleCount < _products.length)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _visibleCount += _pageSize;
                });
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show More'),
            ),
          ),

        const SizedBox(height: 16),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 2
          ? null
          : AppBar(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.text,
              elevation: 1,
              title: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      if (_selectedIndex == 0) {
                        _searchQuery = value;
                        _applyFilter();
                      } else if (_selectedIndex == 1) {
                        _txSearchQuery = value;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: _selectedIndex == 0 ? 'Search in Gachamerch' : 'Search transactions...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 6), 
                  ),
                ),
              ),
              actions: [
                ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: CartService.cartItems,
                  builder: (context, cartItems, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CartPage()),
                            ).then((_) {
                              _fetchProducts();
                            });
                          },
                        ),
                        if (cartItems.isNotEmpty)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${cartItems.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: NotificationService.notifications,
                  builder: (context, notifs, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationPage()),
                            );
                          },
                        ),
                        if (notifs.isNotEmpty)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Text('${notifs.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHome(),
          // Key di-bump tiap kali tab Transaksi dibuka supaya riwayat
          // refetch (pembelian baru langsung kelihatan).
          TransactionPage(key: ValueKey('txn_$_txnTick'), searchQuery: _txSearchQuery),
          ProfilePage(
            onNavigateToTransactions: () {
              setState(() {
                _selectedIndex = 1;
                _txnTick++; // buka tab Transaksi → refetch riwayat
              });
            },
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 0) _fetchProducts(); // refresh saat tab Home dibuka
            if (index == 1) _txnTick++; // buka tab Transaksi → refetch riwayat
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
