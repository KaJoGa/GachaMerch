import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gachamerch/services/auth_service.dart';
import 'package:gachamerch/services/transaction_service.dart';
import 'package:gachamerch/features/main/profile_page.dart';
import 'package:gachamerch/features/main/transaction_page.dart';
import 'package:gachamerch/theme/app_theme.dart';

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
    'https://static.wikia.nocookie.net/gensin-impact/images/e/e3/Item_%22Pile_%27Em_Up%22.png',
    'https://static.wikia.nocookie.net/gensin-impact/images/b/bb/Item_Pure_Water.png',
    'https://static.wikia.nocookie.net/gensin-impact/images/5/5e/Item_Adeptus%27_Temptation.png',
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.category, 'label': 'Category'},
    {'icon': Icons.flash_on, 'label': 'Flash Sale'},
    {'icon': Icons.local_offer, 'label': 'Voucher'},
    {'icon': Icons.card_giftcard, 'label': 'Gift'},
  ];

  List<Map<String, dynamic>> _products = [];
  String? _error; // pesan error fetch (mis. DB/XAMPP mati) untuk ditampilkan

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
  }

  Future<void> _fetchProducts() async {
    try {
      // Hanya item yang sedang DIJUAL (listings), bukan seluruh katalog.
      final res = await http.get(Uri.parse("${AuthService.baseUrl}/listings"));
      if (res.statusCode == 200) {
        final jsonResponse = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _products = List<Map<String, dynamic>>.from(jsonResponse['data'])
              ..shuffle();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dialog pembelian: pilih jumlah (1..stok), lihat total, lalu konfirmasi.
  Future<void> _showBuyDialog(Map<String, dynamic> product) async {
    final int stock = _asInt(product['stock']);
    final int price = _asInt(product['price']);
    final String name = (product['name'] ?? 'Item').toString();
    int qty = 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price: \$$price'),
                  Text('Stock: $stock'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: qty > 1
                                ? () => setLocal(() => qty--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$qty',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: qty < stock
                                ? () => setLocal(() => qty++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    'Total: \$${price * qty}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Buy'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

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

  /// ================= HOME PAGE =================
  Widget _buildHome() {
    return ListView(
      children: [
        /// BANNER
        SizedBox(
          height: 160,
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
                        ),
                ),
              );
            },
          ),
        ),

        /// MENU
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 30),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _menuItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, i) => Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                  child: Icon(_menuItems[i]['icon'], color: AppColors.secondary),
                ),
                const SizedBox(height: 6),
                Text(_menuItems[i]['label']),
              ],
            ),
          ),
        ),

        /// TITLE
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'On Sale',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          itemBuilder: (context, i) => Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: //_isLoading
                      // ? shimmerBox(height: 110, width: double.infinity)
                      // :
                      (_products[i]['image'] != null && _products[i]['image'].toString().isNotEmpty)
                          ? Container(
                              height: 110,
                              width: double.infinity,
                              color: AppColors.background,
                              // Gambar senjata dari wiki rasionya tinggi/besar, jadi
                              // dikasih ruang lebih (terutama bawah) supaya tampil lebih
                              // kecil & utuh, tidak mepet ke tepi. Makanan tetap kecil.
                              padding: _products[i]['item_type'] == 'weapon'
                                  ? const EdgeInsets.fromLTRB(20, 12, 20, 20)
                                  : const EdgeInsets.all(6),
                              // contain = seluruh gambar muat utuh (tidak di-crop),
                              // ukuran beda-beda menyesuaikan tanpa terpotong.
                              child: Image.network(
                                _products[i]['image'],
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                              ),
                            )
                          : const SizedBox(height: 110, child: Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey))),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: // _isLoading
                      // ? shimmerBox(height: 10, width: 80)
                      // :
                      Text(
                          _products[i]['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '\$${_products[i]['price'] ?? 0}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Stock: ${_products[i]['stock'] ?? 0}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: // _isLoading
                      // ? shimmerBox(height: 30, width: double.infinity)
                      // :
                      ElevatedButton(
                          onPressed: _asInt(_products[i]['stock']) > 0
                              ? () => _showBuyDialog(_products[i])
                              : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(30),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _asInt(_products[i]['stock']) > 0
                                ? 'Buy'
                                : 'Out of stock',
                          ),
                        ),
                ),
              ],
            ),
          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 1,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: const [
              SizedBox(width: 16),
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search in Gachamerch',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        actions: const [
          Icon(Icons.shopping_cart_outlined),
          SizedBox(width: 10),
          Icon(Icons.notifications_none),
          SizedBox(width: 10),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHome(),
          // Key di-bump tiap kali tab Transaksi dibuka supaya riwayat
          // refetch (pembelian baru langsung kelihatan).
          TransactionPage(key: ValueKey('txn_$_txnTick')),
          const ProfilePage(),
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
